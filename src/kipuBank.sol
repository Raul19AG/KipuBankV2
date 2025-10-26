//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {Ioracle} from "Ioracle.sol";
//import {oracle} from "oracle.sol";
//import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";





interface Ioracle {
        function latestAnswer() external view returns(int256);
    }
     
	 contract kipuBank is  AccessControl {

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
    uint256 constant DECIMAL_FACTOR = 10e6;
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
    //AggregatorV3Interface public  s_feeds; //0x694AA1769357215DE4FAC081bf1f309aDC325306 Ethereum ETH/USD
	//variable que almacena el precio de la moneda 0x694AA1769357215DE4FAC081bf1f309aDC325306
	//uint256 public price = chainlinkFeed();
	uint256 public price = uint256(latestAnswer()); //devuelve el precio;
	//variable que almacena el precio de la moneda 0x694AA1769357215DE4FAC081bf1f309aDC325306
	//IOracle public oracle;
     
	///@notice variable constante para almacenar el latido (heartbeat) del Data Feed
    //uint16 constant ORACLE_HEARTBEAT = 3800;
    
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
		if(msg.value > i_bankCap){
			revert KipubanK_MontoInvalido("Monto Invalido");
		}
		_;
	}
					
	
	/*///////////////////////
					Functions
	///////////////////////*/
	constructor(uint256 _limite, IERC20 _usdc )	{
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		i_bankCap = _limite;
		i_extMax = 10*10e18;
		USDC = _usdc; 
		//s_feeds = AggregatorV3Interface(_feed);
		//Ioracle oracle = _oracle;Ioracle _oracle
		

	}
	
	/*
		*@notice funcion para realizar depositos en eth
		*@dev esta funcion debe sumar el valor depositado a s_depositos
		*@dev esta funcion precisas emitir el evento KipubanK_Deposito.
	*/
	function depositEth() external payable MontoInvalido{
		emit kipubank_Deposito(msg.sender, msg.value);
          if(getMyBalance()>=i_bankCap) revert KipubanK_MontoInvalido("Capacidad Maxima del Banco");
		  s_depositos[msg.sender] = s_depositos[msg.sender] + msg.value;
		  s_cuentas[msg.sender].eth = s_cuentas[msg.sender].eth + msg.value;
		  s_cuentas[msg.sender].totalUsd = convertEthWToUsdc(s_cuentas[msg.sender].eth);
		  	unchecked{
		++s_oper_depo_total;
		}
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
		  	unchecked{
		++s_oper_depo_total;
		}
	}
	
	/*
		*@notice funcion para realizar Extracciones
		*@notice El _monto de la extraccion debe ser <= a mi balance
		*@dev solo el titualr de la cuenta puede realizar la extraccion debe tener el Role USERS
		*@param _monto valor a ser extraido
	*/
	function extraccionEth(uint256 _monto) external payable onlyRole(USERS){
		if(_monto > i_extMax) revert  KipubanK_MontoMaxExcedido();
		if(_monto > s_depositos[msg.sender]) revert KipubanK_MontoInvalido("saldo Insuficiente");
         emit kipubank_ExtraccionHecha(msg.sender, _monto);
		 _transferirEth(_monto);
		  s_depositos[msg.sender] = s_depositos[msg.sender] - _monto;
		  s_cuentas[msg.sender].eth = s_cuentas[msg.sender].eth - _monto;
		  s_cuentas[msg.sender].totalUsd = convertEthWToUsdc(s_cuentas[msg.sender].totalUsd - (_monto));
		  unchecked{
		++s_oper_ext_total;
		}
	}
	/*
		*@notice funcion para realizar Extracciones en USDC
		*@notice El _monto de la extraccion debe ser <= a mi balance
		*@dev solo el titualr de la cuenta puede realizar la extraccion debe tener el Role USERS
		*@param _monto valor a ser extraido
	*/
	function extraccionUsdc(uint256 _monto) external payable onlyRole(USERS){
		if (_monto > s_cuentas[msg.sender].usdc) revert KipubanK_MontoInvalido("saldo Insuficiente");
		emit kipubank_ExtraccionHecha(msg.sender, _monto);
		s_cuentas[msg.sender].usdc = s_cuentas[msg.sender].usdc - _monto;
		s_cuentas[msg.sender].totalUsd = s_cuentas[msg.sender].totalUsd - (_monto);
		USDC.transfer(msg.sender, _monto);
		unchecked{
		++s_oper_ext_total;
		}
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
    /*
     * @notice función para consultar el precio en USD del ETH 
     * @return ethUSDPrice_ el precio provisto por el oráculo.
     * @dev esta es una implementación simplificada.
     *
   function chainlinkFeed() internal   view returns (uint256 ethUSDPrice_) {
        (, int256 ethUSDPrice,, uint256 updatedAt,) = s_feeds.latestRoundData();

        if (ethUSDPrice == 0) revert KipuBank_OracleCompromised();
        if (block.timestamp - updatedAt > ORACLE_HEARTBEAT) revert KipuBank_StalePrice();

        ethUSDPrice_ = uint256(ethUSDPrice);
    }
    */

     function latestAnswer() internal  pure returns(int256){
            return 3900;
	 }
	/*@notice funcion que toma el precio de eth en usd de un oraculo
	 *return _latestAnswer
	 */
    
    
	  /*@notice funcion para cambiar el oraculo
	 *@param addres _feed
	 */
	// function setOracle(address _feed) public onlyRole(MY_ROLE){
	//	oracle = IOracle(_feed);
	// }

	/*
     * @notice función interna para realizar la conversión de decimales de ETH a USDC
     * @param _mont la cantidad de ETH a ser convertida
     * @return usdc_ el resultado del cálculo.
     */
	function convertEthWToUsdc(uint256  _monto) public view onlyRole(USERS)	returns(uint256) {
		uint256 usdc_ = ((_monto * DECIMAL_FACTOR) * price);
		usdc_ = usdc_ / 10e18;
		return usdc_;
}
      

   /*@notice funcion para convercion de decimales
   *@param uint256 amount
   *@param uint256 fromDecimals
   *@param uint256 toDecimals
   *@return uint256
   */
   //function convertDecimals(uint256 amount, uint256 fromDecimals, uint256 toDecimals) internal pure returns (uint256) {
   //uint256 result = (amount * 10 ** toDecimals) / (10 ** fromDecimals);
   //return result;
   // }


  /**@notice funcion para regular el bankCap convirtiendo eth a usdc
   * @dev funcion para regular el bankCap convirtiendo eth a usdc
   * @return  uint256
   /*
   function converBankCap() private   returns (uint256) {
	uint256 ConverCap = ((i_bankCap /100)*80);
	  	   if(getMyBalance()>= ConverCap){
		uint256	ConverCap2 = ((ConverCap / 100) * 10);
			s_bankCapUsdc = convertEthToUsdc(ConverCap2);
            USDC.Transfer(from, to, value);
 
		   }
		
		}*/
	}