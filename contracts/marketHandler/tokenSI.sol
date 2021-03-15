// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/SIInterface.sol";
import "../interfaces/marketHandlerDataStorageInterface.sol";
import "../interfaces/marketManagerInterface.sol";
import "../interfaces/interestModelInterface.sol";
import "../interfaces/tokenInterface.sol";
import "../interfaces/marketSIHandlerDataStorageInterface.sol";
import "../Errors.sol";

/**
 * @title Bifi tokenSI Contract
 * @notice Service incentive logic
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract tokenSI is SIInterface, SIErrors {
	event CircuitBreaked(bool breaked, uint256 blockNumber, uint256 handlerID);

	address payable owner;

	uint256 handlerID;

	string tokenName;

	uint256 constant unifiedPoint = 10 ** 18;

	uint256 unifiedTokenDecimal;

	uint256 underlyingTokenDecimal;

	marketManagerInterface marketManager;

	interestModelInterface interestModelInstance;

	marketHandlerDataStorageInterface handlerDataStorage;

	marketSIHandlerDataStorageInterface SIHandlerDataStorage;

	IERC20 erc20Instance;

	struct MarketRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardPerBlock;
	}

	struct UserRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardAmount;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == address(owner), ONLY_OWNER);
		_;
	}

	/**
	* @dev Transfer ownership
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by owne
	* @param _emergency The status of the circuit breaker
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by marketManager
	* @param _emergency The status of the circuit breaker
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyMarketManager external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Update the amount of rewards per block
	* @param _rewardPerBlock The amount of the reward amount per block
	* @return true (TODO: validate results)
	*/
	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) onlyMarketManager external override returns (bool)
	{
		return SIHandlerDataStorage.updateRewardPerBlockStorage(_rewardPerBlock);
	}

	/**
	* @dev Update the reward lane (the acculumated sum of the reward unit per block) of the market and user
	* @param userAddr The address of user
	* @return Whether or not this process has succeeded
	*/
	function updateRewardLane(address payable userAddr) external override returns (bool)
	{
		return _updateRewardLane(userAddr);
	}
	function _updateRewardLane(address payable userAddr) internal returns (bool)
  {
		MarketRewardInfo memory market;
		UserRewardInfo memory user;
		marketSIHandlerDataStorageInterface _SIHandlerDataStorage = SIHandlerDataStorage;
		(market.rewardLane, market.rewardLaneUpdateAt, market.rewardPerBlock, user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = _SIHandlerDataStorage.getRewardInfo(userAddr);

		uint256 currentBlockNum = block.number;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositTotalAmount, borrowTotalAmount, depositUserAmount, borrowUserAmount) = handlerDataStorage.getAmount(userAddr);

		/* Unless the reward lane of the market is updated at the current block */
		if (market.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 _delta = sub(currentBlockNum, market.rewardLaneUpdateAt);
			uint256 betaRateBaseTotalAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
			if (betaRateBaseTotalAmount != 0)
			{
				/* update the reward lane */
				market.rewardLane = add(market.rewardLane, _calcRewardLaneDistance(_delta, market.rewardPerBlock, betaRateBaseTotalAmount));
			}

			_SIHandlerDataStorage.setMarketRewardInfo(market.rewardLane, currentBlockNum, market.rewardPerBlock);
		}

		/* Unless the reward lane of the user  is updated at the current block */
		if (user.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 betaRateBaseUserAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
			if (betaRateBaseUserAmount != 0)
			{
				user.rewardAmount = add(user.rewardAmount, unifiedMul(betaRateBaseUserAmount, sub(market.rewardLane, user.rewardLane)));
			}

			_SIHandlerDataStorage.setUserRewardInfo(userAddr, market.rewardLane, currentBlockNum, user.rewardAmount);
			return true;
		}

		return false;
	}

	/**
	* @dev Calculates the reward lane distance (for delta blocks) based on the given parameters.
	* @param _delta The blockNumber difference
	* @param _rewardPerBlock The amount of reward per block
	* @param _total The total amount of betaRate
	* @return The reward lane distance
	*/
	function _calcRewardLaneDistance(uint256 _delta, uint256 _rewardPerBlock, uint256 _total) internal pure returns (uint256)
	{
		return mul(_delta, unifiedDiv(_rewardPerBlock, _total));
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function getBetaRateBaseTotalAmount() external view override returns (uint256)
	{
		return _getBetaRateBaseTotalAmount();
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function _getBetaRateBaseTotalAmount() internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = handlerDataStorage.getHandlerAmount();
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev Calculate the rewards given to the user by using the beta score (external).
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The beta score of the user
	*/
	function getBetaRateBaseUserAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getBetaRateBaseUserAmount(userAddr);
	}

	/**
	* @dev Calculate the rewards given to the user by using the beta score (internal)
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The beta score of the user
	*/
	function _getBetaRateBaseUserAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositUserAmount, borrowUserAmount) = handlerDataStorage.getUserAmount(userAddr);
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
	}

	function _calcBetaBaseAmount(uint256 _beta, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return add(unifiedMul(_depositAmount, _beta), unifiedMul(_borrowAmount, sub(unifiedPoint, _beta)));
	}

	/**
	* @dev Claim rewards for the user (external)
	* @param userAddr The address of user
	* @return The amount of user reward
	*/
	function claimRewardAmountUser(address payable userAddr) onlyMarketManager external override returns (uint256)
	{
		return _claimRewardAmountUser(userAddr);
	}

	/**
	* @dev Claim rewards for the user (internal)
	* @param userAddr The address of user
	* @return The amount of user reward
	*/
	function _claimRewardAmountUser(address payable userAddr) internal returns (uint256)
	{
		UserRewardInfo memory user;
		uint256 currentBlockNum = block.number;
		(user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = SIHandlerDataStorage.getUserRewardInfo(userAddr);

		/* reset the user reward */
		SIHandlerDataStorage.setUserRewardInfo(userAddr, user.rewardLane, currentBlockNum, 0);
		return user.rewardAmount;
	}

	/**
	* @dev Get the reward parameters of the market
	* @return (rewardLane, rewardLaneUpdateAt, rewardPerBlock)
	*/
	function getMarketRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getMarketRewardInfo();
	}

	/**
	* @dev Get reward parameters for the user
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardAmount)
	*/
	function getUserRewardInfo(address payable userAddr) external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getUserRewardInfo(userAddr);
	}

	/**
	* @dev Get the rate of beta (beta-score)
	* @return The rate of beta (beta-score)
	*/
	function getBetaRate() external view returns (uint256)
	{
		return SIHandlerDataStorage.getBetaRate();
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

	function signedAdd(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a + b;
		require(((b >= 0) && (c >= a)) || ((b < 0) && (c < a)), "SignedSafeMath: addition overflow");
		return c;
	}

	function signedSub(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a - b;
		require(((b >= 0) && (c <= a)) || ((b < 0) && (c > a)), "SignedSafeMath: subtraction overflow");
		return c;
	}
}
