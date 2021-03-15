// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "./interfaces/marketManagerInterface.sol";
import "./interfaces/interestModelInterface.sol";
import "./interfaces/marketHandlerDataStorageInterface.sol";
import "./interfaces/marketSIHandlerDataStorageInterface.sol";
import "./Errors.sol";
/**
 * @title Bifi user request proxy (navtive coin)
 * @notice access logic contracts via delegate calls.
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract coinProxy is RequestProxyErrors {
	/* handler storage */
	address payable owner;

	uint256 handlerID;

	string tokenName = "ether";

	uint256 constant unifiedPoint = 10 ** 18;

	marketManagerInterface marketManager;

	interestModelInterface interestModelInstance;

	marketHandlerDataStorageInterface handlerDataStorage;

	marketSIHandlerDataStorageInterface SIHandlerDataStorage;

	/* proxy storage */
	address public handler;

	address public SI;

	string DEPOSIT = "deposit(uint256,bool)";

	string REDEEM = "withdraw(uint256,bool)";

	string BORROW = "borrow(uint256,bool)";

	string REPAY = "repay(uint256,bool)";

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	/**
	* @dev Construct a new coinProxy which uses coinHandlerLogic
	*/
	constructor () public
	{
		owner = msg.sender;
	}

	/**
	* @dev Replace the owner of the handler
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Initialize the contract
	* @param _handlerID ID of handler
	* @param marketManagerAddr The address of market manager
	* @param interestModelAddr The address of handler interest model contract address
	* @param marketDataStorageAddr The address of handler data storage
	* @param siHandlerAddr The address of service incentive contract
	* @param SIHandlerDataStorageAddr The address of service incentive data storage
	*/
	function initialize(uint256 _handlerID, address handlerAddr, address marketManagerAddr, address interestModelAddr, address marketDataStorageAddr, address siHandlerAddr, address SIHandlerDataStorageAddr) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		handler = handlerAddr;
		SI = siHandlerAddr;
		marketManager = marketManagerInterface(marketManagerAddr);
		interestModelInstance = interestModelInterface(interestModelAddr);
		handlerDataStorage = marketHandlerDataStorageInterface(marketDataStorageAddr);
		SIHandlerDataStorage = marketSIHandlerDataStorageInterface(SIHandlerDataStorageAddr);
	}

	/**
	 * @dev Set ID of handler
	 * @param _handlerID The ID of handler
	 * @return true (TODO: validate results)
	 */
	function setHandlerID(uint256 _handlerID) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		return true;
	}

	/**
	 * @dev Set the address of handler
	 * @param handlerAddr The address of handler
	 * @return true (TODO: validate results)
	 */
	function setHandlerAddr(address handlerAddr) onlyOwner public returns (bool)
	{
		handler = handlerAddr;
		return true;
	}

	/**
	 * @dev Set the address of service incentive contract
	 * @param siHandlerAddr The address of service incentive contract
 	 * @return true (TODO: validate results)
	 */
	function setSiHandlerAddr(address siHandlerAddr) onlyOwner public returns (bool)
	{
		SI = siHandlerAddr;
		return true;
	}

	/**
	* @dev Get ID of handler
	* @return The connected handler ID
	*/
	function getHandlerID() public view returns (uint256)
	{
		return handlerID;
	}

	/**
	* @dev Get the address of handler
	* @return The handler address
	*/
	function getHandlerAddr() public view returns (address)
	{
		return handler;
	}

	/**
	* @dev Get the address of service incentive contract
	* @return The service incentive contract address
	*/
	function getSiHandlerAddr() public view returns (address)
	{
		return SI;
	}

	/**
	* @dev Move assets to sender for the migration event.
	*/
	function migration(address payable target) onlyOwner public returns (bool)
	{
		target.transfer(address(this).balance);
		/*ToDo: update selfDestruct function */
	}

	/**
	* @dev fallback function where handler can receive native coin
	*/
	fallback () external payable
	{

	}

	/**
	* @dev Forward the request for deposit to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to deposit
	* @param flag Flag for the full calculation mode
	* @return whether the deposit has been made successfully or not.
	*/
	function deposit(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(DEPOSIT, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the request for withdraw to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to withdraw
	* @param flag Flag for the full calculation mode
	* @return whether the withdraw has been made successfully or not.
	*/
	function withdraw(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REDEEM, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the request for borrow to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to borrow
	* @param flag Flag for the full calculation mode
	* @return whether the borrow has been made successfully or not.
	*/
	function borrow(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(BORROW, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the request for repay to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to repay
	* @param flag Flag for the full calculation mode
	* @return whether the repay has been made successfully or not.
	*/
	function repay(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REPAY, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Call other functions in handler logic contract.
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function handlerProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other view functions in handler logic contract.
	* (delegatecall does not work for view functions)
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function handlerViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other functions in service incentive logic contract.
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function siProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other view functions in service incentive logic contract.
	* (delegatecall does not work for view functions)
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function siViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}
}
