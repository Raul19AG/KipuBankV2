//SPDX-License-Identifier: MIT
pragma solidity >0.5.8;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import { UniversalRouter } from "@uniswap/universal-router/contracts/UniversalRouter.sol";




     
	 contract KipuBank is  AccessControl {

	/*///////////////////////
					Variables
	///////////////////////*/
	///@notice variable inmutable almacena el owner
	address immutable public i_owner;
	///@notice variable Inmutable Monto de extraccion maxima
	uint256 immutable i_extMax ;
	///@notice variable Inmutable para almacenar el limite global de deposito
	uint256 immutable i_bankCap;
	///@notice variable constante para almacenar el factor de decimales
    uint256 constant DECIMAL_FACTOR = 10**6;
	///@notice variable constante que almacena rol
    bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
    ///@notice variable constante que almacena rol
    bytes32 public constant USERS = keccak256("USERS"); 

	///@notice variable Inmutable para almacenar el limite global de deposito
	uint256 s_bankCapUsdc;
    ///@notice variable para almacenar el total de operaciones depositos
	uint256 public  s_oper_depo_total;
    ///@notice variable para almacenar el total de operaciones extracciones
	uint256 public s_oper_ext_total;
    
	///@notice variable para almacenar la dirección del Chainlink Feed
    AggregatorV3Interface public  s_feeds;// = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);// Ethereum ETH/USD
	//variable que almacena el precio de la moneda  0x5C022E645Dbae6Fb9cF079698F787D5d1C098cA7
	//uint256 public price = chainlinkFeed();      0x5C022E645Dbae6Fb9cF079698F787D5d1C098cA7                                            
	
	//variable que almacena el precio de la moneda 
	//IOracle public oracle;
     //s_feeds = AggregatorV3Interface(_feed); //address  _feed 
	///@notice variable constante para almacenar el latido (heartbeat) del Data Feed
    uint16 constant ORACLE_HEARTBEAT = 3600;
    
	IERC20 immutable public USDC;
	IERC20 immutable public USD;

	
	///struct
	struct Deposito {
		uint256 eth;
		uint256 usdc;
	    uint256 totalUsd;
	}
	///@notice mapping para almacenar las distinatas cuentas del usuario
	mapping(address usuario => Deposito) public s_cuentas; 
    	
	///@notice mapping para almacenar el valor dado por el usuário
	mapping(address usuario => uint256 valor) public s_depositos;
	
	/*///////////////////////
						Events
	////////////////////////*/
	///@notice evento emitido cuando un nuevo deposito es hecho
	event kipubank_Deposito(address depositante, uint256 valor);
	///@notice evento emitido cuando una extraccion es hecha
	event kipubank_ExtraccionHecha(address receptor, uint256 valor);
    ///@notice evento emitida al cambiar la direccion de feed chainlink
	event kipubank_ChangeFeed(address newFeed);

	
	/*///////////////////////
						Errors
	///////////////////////*/
	///@notice error emitido cuando la transaccion falla
	error kipubank_TransaccionFallo(bytes error);
	///@notice error emitido cuando la direccion es diferente a la del beneficiario 
	error kipubank_ClienteNoValido(address extraccionista, address usuario);
	///@notice error emitido cuando el saldo es Insuficiente
	error KipubanK_BalanceInsuficiente();
	///@notice error emitido cuando el monto es mayor a i_extMax
	error KipubanK_MontoMaxExcedido();
	///@notice error monto invalido
	error KipubanK_MontoInvalido(string);
	///@notice error emitido cuando el retorno del oráculo es incorrecto
    error KipuBank_OracleCompromised();
    ///@notice error emitido cuando la última actualización del oráculo supera el heartbeat
    error KipuBank_StalePrice();
	/*//////////////////////
					Modifiers
    //////////////////////*/
	///@notice modificador para validar el beneficiario
	modifier MontoInvalido() {
		if(msg.value > i_bankCap || msg.value <= 0){
			revert KipubanK_MontoInvalido("Monto Invalido");
		}
		_;
	}
					
	
	/*///////////////////////
					Functions
	///////////////////////*/
	/**
	* @notice costrucor del contrato
    * @param _limite Límite global de depósitos en el banco (en wei).
	* @param _usdc address de USDC
	* @param _feed address de oraculo chainlink eth
    * @dev i_extMax se fija en 10 ETH (10*10^18 wei) como máximo por extracción.
    */
	constructor(uint256 _limite, IERC20 _usdc,  address payable  _feed )	{
		i_owner = msg.sender;
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		i_bankCap = _limite;
		i_extMax = 10*10e18;
		//USDC = _usdc; 
		s_feeds =  AggregatorV3Interface(_feed); 
		
		

	}
	
	/*
		*@notice funcion para realizar depositos en eth
		*@dev esta funcion debe sumar el valor depositado a s_depositos
		*@dev esta funcion precisas emitir el evento KipubanK_Deposito.
	*/
	function deposit() external payable  MontoInvalido{
		if(getMyBalance() + msg.value >=i_bankCap) revert KipubanK_MontoInvalido("Capacidad Maxima del Banco");
		s_depositos[msg.sender] = s_depositos[msg.sender] + msg.value;
		s_cuentas[msg.sender].eth = s_cuentas[msg.sender].eth + msg.value;
		s_cuentas[msg.sender].totalUsd = s_cuentas[msg.sender].totalUsd + convertEthWToUsdc(s_cuentas[msg.sender].eth);
		emit kipubank_Deposito(msg.sender, msg.value);
		++s_oper_depo_total;
		
	}
    /*
		*@notice funcion para realizar depositos usdc
		*@dev esta funcion debe sumar el valor depositado a s_depositos
		*@dev esta funcion precisas emitir el evento KipubanK_Deposito.
	*/

	function depositUsdc(uint256 _usdcAmount) external {
		USDC.transferFrom(msg.sender, address(this), _usdcAmount);
		emit kipubank_Deposito(msg.sender, _usdcAmount);
          if(getMyBalance()>=i_bankCap) revert KipubanK_MontoInvalido("Capacidad Maxima del Banco");
		  s_cuentas[msg.sender].usdc = s_cuentas[msg.sender].usdc + _usdcAmount;
		  s_cuentas[msg.sender].totalUsd = s_cuentas[msg.sender].totalUsd + _usdcAmount ;//* 10e5);
		  s_depositos[msg.sender] += _usdcAmount;
		  //s_cuentas[msg.sender].totalUsd += convertEthWToUsdc(msg.value);
		  ++s_oper_depo_total;
	
	}
	
	/*
		*@notice funcion para realizar Extracciones
		*@notice El _monto de la extraccion debe ser <= a mi balance
		*@dev solo el titualr de la cuenta puede realizar la extraccion debe tener el Role USERS
		*@param _monto valor a ser extraido
	*/
	function extraccionEth(uint256 _monto) external payable  onlyRole(USERS){
		if(_monto > i_extMax) revert  KipubanK_MontoMaxExcedido();
		if(_monto > s_depositos[msg.sender]) revert KipubanK_MontoInvalido("saldo Insuficiente");
          s_depositos[msg.sender] = s_depositos[msg.sender] - _monto;
		  s_cuentas[msg.sender].eth = s_cuentas[msg.sender].eth - _monto;
		  s_cuentas[msg.sender].totalUsd = s_cuentas[msg.sender].totalUsd -convertEthWToUsdc(_monto);
		  emit kipubank_ExtraccionHecha(msg.sender, _monto);
		  ++s_oper_ext_total;
		  _transferirEth(_monto);
		
	}
	/*
		*@notice funcion para realizar Extracciones en USDC
		*@notice El _monto de la extraccion debe ser <= a mi balance
		*@dev solo el titualr de la cuenta puede realizar la extraccion debe tener el Role USERS
		*@param _monto valor a ser extraido
	*/
	function extraccionUsdc(uint256 _monto) external onlyRole(USERS){
		if (_monto > s_cuentas[msg.sender].usdc) revert KipubanK_MontoInvalido("saldo Insuficiente");
		if(_monto > i_extMax) revert  KipubanK_MontoMaxExcedido();
		emit kipubank_ExtraccionHecha(msg.sender, _monto);
		s_cuentas[msg.sender].usdc = s_cuentas[msg.sender].usdc - _monto;
		s_cuentas[msg.sender].totalUsd = s_cuentas[msg.sender].totalUsd - (_monto);
		s_depositos[msg.sender] = s_depositos[msg.sender] - _monto;
		USDC.transfer(msg.sender, _monto);
		++s_oper_ext_total;
		
	}
	
	/*
		*@notice funcion privada para realizar  transferencia de ether
		*@param _monto valor a ser transferido
		*@dev precisa revert si falla
	*/
	function _transferirEth(uint256 _monto) private {
		(bool sucess,bytes memory error) = msg.sender.call{value: _monto}("");
		if(!sucess) revert kipubank_TransaccionFallo(error);
	}
    /*
		*@notice funcion privada para obtener el balance del contrato actual
		*@retorna el balance del contrato
		*/
   function getMyBalance() public view onlyRole(MY_ROLE)returns (uint256) {
        return address(this).balance;
   }
   /**
 * @notice Función para consultar el precio en USD del ETH usando Chainlink.
 * @return ethUSDPrice_ Precio de ETH en USD (con 8 decimales, como Chainlink).
 * @dev Reverte si el precio es 0 (oráculo comprometido) o está desactualizado.
 */
function chainlinkFeed() public view returns (uint256) {
    (, int256 ethUSDPrice, , uint256 updatedAt, ) = s_feeds.latestRoundData();

    // Validaciones críticas
    if (ethUSDPrice <= 0) revert KipuBank_OracleCompromised();  // Precio <= 0 es inválido
    if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();  // Datos antiguos

    // Convierte de int256 a uint256 (seguro porque ya validamos que ethUSDPrice > 0)
     return uint256(ethUSDPrice);
} 

    /**
 * @notice Convierte un amount de ETH a USDC usando el precio de Chainlink.
 * @param _ethAmount Cantidad de ETH (en wei, 18 decimales).
 * @return Amount en USDC (6 decimales).
 */
function convertEthWToUsdc(uint256 _ethAmount) public view  returns (uint256) {
    uint256 ethUSDPrice = chainlinkFeed(); //; 380000000000 HArcode porque chainlink no funka// Precio en 8 decimales (ej: 2000 * 1e8) 380000000000;
    // Fórmula: (ETH * precio) / 10^(18 + 8 - 6) = (ETH * precio) / 1e20
    //s_cuentas[msg.sender].totalUsd += convertEthWToUsdc(msg.value);
	uint256 usdcAmount = (_ethAmount * ethUSDPrice) / 1e20;
	return usdcAmount;
	
	
}
 
    /*
     * @notice función para consultar el precio en USD del ETH 
     * @return ethUSDPrice_ el precio provisto por el oráculo.
     * @dev esta es una implementación simplificada.
     */
   //function chainlinkFeed() internal   view returns (uint256 ethUSDPrice_) {
    //    (, int256 ethUSDPrice,, uint256 updatedAt,) = s_feeds.latestRoundData();

      //  if (ethUSDPrice == 0) revert KipuBank_OracleCompromised();
        //if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();

   //     ethUSDPrice_ = uint256(ethUSDPrice);
    //}
    

    

	/*
     * @notice función interna para realizar la conversión de decimales de ETH a USDC
     * @param _mont la cantidad de ETH a ser convertida
     * @return usdc_ el resultado del cálculo.
     *
	function convertEthWToUsdc(uint256  _monto) public view onlyRole(USERS)	returns(uint256) {
		uint256 usdc_ = ((_monto * DECIMAL_FACTOR) * 3800);
		usdc_ = usdc_ / 1e20;
		return usdc_;
}*/
      

   /*@notice funcion para convercion de decimales
   *@param uint256 amount
   *@param uint256 fromDecimals
   *@param uint256 toDecimals
   *@return uint256
   */
    function convertDecimals(uint256 amount, uint256 fromDecimals, uint256 toDecimals) internal pure returns (uint256) {
    uint256 result = (amount * 10 ** toDecimals) / (10 ** fromDecimals);
    return result;
     }


  /*@notice funcion para regular el bankCap convirtiendo eth a usdc
   * @dev funcion para regular el bankCap convirtiendo eth a usdc
   * @return  uint256
   */
   function converBankCap() public onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
    uint256 eightyPercentCap = (i_bankCap * 80) / 100;
    uint256 ethToConvert = eightyPercentCap;
    uint256 usdcAmount = convertEthWToUsdc(ethToConvert);

    // Transferir ETH a USDC (requiere aprobación y lógica de swap)
    // Ejemplo: Usar un exchange como Uniswap o Curve
    // USDC.transfer(address(exchange), ethToConvert);
    // ... lógica de swap ...

    s_bankCapUsdc = usdcAmount;
    return usdcAmount;
}
	}
