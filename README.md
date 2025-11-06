## Título de la documentación: Documentación del contrato kipubank

## Introducción
Finalidad del documento: Este documento proporciona información completa sobre el contrato Kipu-bank, sus características, instalación y guía de usuario.

# Alcance del Contrato:
kipubank permite a los usuarios crear una cuenta, almacenar, depositar y extraeer token nativos ETH y USDC COMPANY de una boveda. 

# Destinatarios:
Esta documentación está dirigida a usuarios finales, administradores y desarrolladores.


## Instalación y configuración

# Requisitos previos:
SO windows, MacOS o Linux, Browsers Explorer, Chrome v.xxx, Firefox V.xxx o posteriores

# Pasos de la descarga:
Instalción a traves de dispositivos extraibles..,
Clona el repositorio: git clone <https://github.com/Raul19AG/KipuBankV2>
# Deployed in https://sepolia.etherscan.io/address/
## Guía del usuario

# Cómo empezar:

# Abri tu Navegador favorito, Ingrasa a remix.ethereum.org, desde el Explorador de archivos de remix ingresa a open file from your system y Navega hasta la carpeta del proyecto: contracts, esta carpeta contiene los ficheros:
Kipu-bank.sol
README.md
abrir: Kipu-bank.sol
1.-Compilar con solidity compiler
2.-Click en Deploy and run transactions, en el panel de navegacion que se desplega seleccionar la VM requeriada, scrolear hacia abajo, en deployed contracts
clickear en Kipu-bank AT 0x..., se desplegara los botones deposit, extraccion con un campo de entrada en el cual se ingresa el monto deseado, con el boton getOpe_depo se Visualiza la cantidad de operaciones de deposito realizadas hasta ese momento;
con el boton getOpe_ext se visualiza la cantidad de operaciones de extraccion realizadas hasta ese momento;
el boton s_depositos tiene un campo para ingresar el adress del usuario, con el cual se visualiza EL BALANCE del mismo.

# Como interactuar con el contrato:
Funcion GrantRole: Otorga privilejios a la cuenta  ingresada, solicita addres de la cuenta y byte32 de Role.
Funcion RenunceRole: Renuncia privilijios a la cuenta ingresada, solicita addres de la cuenta y byte32 de Role.
Funcion RevokeRole: Revoca privilijios a la cuenta ingresada, solicita addres de la cuenta y byte32 de Role.
Funcion convertEthWTo: convierte un monto de ETH  ingresado en weis a USDC.
Funcion DEFAULT_ADMIN : retorna byte32 del Default admin
Funcion getMyBalance : retorna balance actual de la cuenta.
Funcion getRoleAdmin : retorna byte32 del Default admin.
Funcion hasRole : retorna bool, param acount address y byte32 Role.
 i_owner : retorna byte32 address del owner.
 MY_ROLE: retorna byte32 de MyRole.
 USERS: retorna byte32 de USERS.
s_cuentas: retorna el estado de la cuenta uint256: eth, usdc, usdcTotal.
s_depositos: retorna uint256  balance total de la cuenta.
s_feeds: retorna el adress del s_feeds actual.
s_oper_depo: retorna uint256 total de operaciones de deposito realizadas ETH + USDC Compay.
s_oper_ext_total: retorna uint256 total de operaciones de extraccion realizadas ETH + USDC Compay.

Funcion deposit: es la utilizada para Ingresar ETH en weis al la cuenta, emite un evento a la blockchain, incrementa la variable s_oper_depo_total
Funcion depositUsdc: es la utilizada para Ingresar usdc COMPANY en  la cuenta, emite un evento a la blockchain, incrementa la variable s_oper_depo_total
Funcion extraccionEth: es para realizar extracciones de ETH en weis, recibe un parametro uint256, llama una funcion privada, emite un evento a la blockchain, incrementa la variable s_oper_ext_total.
Funcion extraccionUsdc: es para realizar extracciones de Usdc  con seis 6 decimales recibe un parametro uint256, llama una funcion privada, emite un evento a la blockchain, incrementa la variable s_oper_ext_total.
Funcion getOpe_depo_total: visualiza el registro total de operaciones de DEPOSITO realizadas hasta el momento.
Funcion getOpe_ext_total: visualiza el registro total de operaciones de EXTRACION realizadas hasta el momento.


## Enlace del contrato en el Block chain:
#

## Agradecimientos a:
TalentoTech,ETH*KIPU Sus docentes y compañeros de cusro.
ServiTecPc Incursionando en el Desarrollo de Contratos Inteligentes
Gobierno de la Ciudad.
Ministerio de Educacion de la Ciudad. 
