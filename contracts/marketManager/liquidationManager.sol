// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/marketManagerInterface.sol";
import "../interfaces/managerDataStorageInterface.sol";
import "../interfaces/marketHandlerInterface.sol";
import "../interfaces/liquidationManagerInterface.sol";
import "../Errors.sol";

/**
 * @title BiFi Liquidation Manager Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract etherLiquidationManager is liquidationManagerInterface, LiquidationManagerErrors {
	event CircuitBreaked(bool breaked, uint256 blockNumber);
  event Liquidate(address liquidator, address delinquentBorrower, uint256 liquidateHandler, uint256 liquidateAmount, uint256 rewardHandler, uint256 rewardAmount);
  
	address payable owner;

	bool emergency = false;

	uint256 constant unifiedPoint = 10 ** 18;

	marketManagerInterface public marketManager;

	struct LiquidationModel {
		uint256 delinquentDepositAsset;
		uint256 delinquentBorrowAsset;
		uint256 liquidatePrice;
		uint256 receivePrice;
		uint256 liquidateAmount;
		uint256 liquidateAsset;
		uint256 rewardAsset;
		uint256 rewardAmount;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier circuitBreaker {
		address msgSender = msg.sender;
		require((!emergency) || (msgSender == owner), CIRCUIT_BREAKER);
		_;
	}

	/**
	* @dev Construct a new liquidationManager
	* @param marketManagerAddr The address of marketManager contract
	*/
	constructor (address marketManagerAddr) public
	{
		owner = msg.sender;
		marketManager = marketManagerInterface(marketManagerAddr);
	}

	/**
	* @dev Set new market manager address
	* @param marketManagerAddr The address of marketManager contract
	* @return true (TODO: validate results)
	*/
	function setMarketManagerAddr(address marketManagerAddr) external onlyOwner returns (bool) {
		marketManager = marketManagerInterface(marketManagerAddr);
		return true;
	}

	/**
	* @dev Transfer ownership
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	/**
	* @dev Get the address of owner
	* @return the address of owner
	*/
	function getOwner() public view returns (address)
	{
		return owner;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by marketManager
	* @param _emergency The status of circuitBreak
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyManager external override returns (bool)
	{
		emergency = _emergency;
		emit CircuitBreaked(_emergency, block.number);
		return true;
	}

	/**
	* @dev Liquidate asset of the user in default (or margin call) status
	* @param delinquentBorrower the liquidation target
	* @param targetHandler The hander ID of the liquidating asset (the
	  liquidator repay the tokens of the targetHandler instead)
	* @param liquidateAmount The amount to liquidate
	* @param receiveHandler The handler ID of the reward token for the liquidator
	* @return The amount of reward token
	*/
	function partialLiquidation(address payable delinquentBorrower, uint256 targetHandler, uint256 liquidateAmount, uint256 receiveHandler) circuitBreaker external override returns (uint256)
	{
		/* msg.sender is liquidator */
		address payable liquidator = msg.sender;
		LiquidationModel memory vars;
		/* Check whether the user is in liquidation.*/
		if (_checkLiquidation(delinquentBorrower) == false)
		{
			revert(NO_DELINQUENT);
		}

		/* Liquidate */
		(vars.liquidateAmount, vars.delinquentDepositAsset, vars.delinquentBorrowAsset) = marketManager.partialLiquidationUser(delinquentBorrower, liquidateAmount, liquidator, targetHandler, receiveHandler);

		/* Compute the price of the liquidated tokens */
		vars.liquidatePrice = marketManager.getTokenHandlerPrice(targetHandler);
		vars.liquidateAsset = unifiedMul(vars.liquidateAmount, vars.liquidatePrice);

		/* Calculates the number of tokens to receive as rewards. */
		vars.rewardAsset = unifiedDiv(unifiedMul(vars.liquidateAsset, vars.delinquentDepositAsset), vars.delinquentBorrowAsset);
		vars.receivePrice = marketManager.getTokenHandlerPrice(receiveHandler);
		vars.rewardAmount = unifiedDiv(vars.rewardAsset, vars.receivePrice);

		/* Receive reward */

		marketManager.partialLiquidationUserReward(delinquentBorrower, vars.rewardAmount, liquidator, receiveHandler);
    emit Liquidate(liquidator, delinquentBorrower, targetHandler, vars.liquidateAmount, receiveHandler, vars.rewardAmount);

    return vars.rewardAmount;
	}

	/**
	* @dev Checks the given user is eligible for delinquentBorrower (external)
	* @param userAddr The address of user
	* @return Eligibility as delinquentBorrower
	*/
	function checkLiquidation(address payable userAddr) external view override returns (bool)
	{
		return _checkLiquidation(userAddr);
	}

	/**
	* @dev Checks the given user is eligible for delinquentBorrower (internal)
	* @param userAddr The address of user
	* @return Eligibility as delinquentBorrower
	*/
	function _checkLiquidation(address payable userAddr) internal view returns (bool)
	{
		uint256 userBorrowAssetSum;
		uint256 liquidationLimitAssetSum;
		uint256 tokenListLength = marketManager.getTokenHandlersLength();
		for (uint256 handlerID = 0; handlerID < tokenListLength; handlerID++)
		{
			if (marketManager.getTokenHandlerSupport(handlerID))
			{
				/* Get the deposit and borrow amount including interest */
				uint256 depositAsset;
				uint256 borrowAsset;
				(depositAsset, borrowAsset) = marketManager.getUserIntraHandlerAssetWithInterest(userAddr, handlerID);


				/* Compute the liquidation limit and the sum of borrow of the
				user */
				uint256 marginCallLimit = marketManager.getTokenHandlerMarginCallLimit(handlerID);
				liquidationLimitAssetSum = add(liquidationLimitAssetSum, unifiedMul(depositAsset, marginCallLimit));
				userBorrowAssetSum = add(userBorrowAssetSum, borrowAsset);
			}

		}

		/* If the borrowed amount exceeds the liquidation limit, the user is a delinquent borrower. */
		if (liquidationLimitAssetSum <= userBorrowAssetSum)
		{
			return true;
			/* Margin call */
		}

		return false;
	}

	/* ******************* Safe Math ******************* */
  // from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
  // Subject to the MIT license.
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "add overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "sub overflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "div by zero");
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mod(a, b, "mod by zero");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b != 0, errorMessage);
		return a % b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "unified div by zero");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
	}
}
