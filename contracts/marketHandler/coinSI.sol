// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/SIInterface.sol";
import "../interfaces/marketHandlerDataStorageInterface.sol";
import "../interfaces/marketManagerInterface.sol";
import "../interfaces/interestModelInterface.sol";
import "../interfaces/marketSIHandlerDataStorageInterface.sol";
import "../Errors.sol";

/**
 * @title Bifi's coinSI Contract
 * @notice Contract of coinSI, where users can action with reward logic
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract coinSI is SIInterface, SIErrors {
	event CircuitBreaked(bool breaked, uint256 blockNumber, uint256 handlerID);

	address payable owner;

	uint256 handlerID;

	string tokenName;

	uint256 constant unifiedPoint = 10 ** 18;

	marketManagerInterface marketManager;

	interestModelInterface interestModelInstance;

	marketHandlerDataStorageInterface handlerDataStorage;

	marketSIHandlerDataStorageInterface SIHandlerDataStorage;

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
	* @dev Replace the owner of the handler
	* @param _owner the address of the owner to be replaced
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers with owner
	* @param _emergency The status on whether to use circuitBreak
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers with marketManager
	* @param _emergency The status on whether to use circuitBreak
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
	* @param _rewardPerBlock The amount of rewards per block
	* @return true (TODO: validate results)
	*/
	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) onlyMarketManager external override returns (bool)
	{
		return SIHandlerDataStorage.updateRewardPerBlockStorage(_rewardPerBlock);
	}

	/**
	* @dev Calculates the number of rewards given according to the gap of block number
	* @param userAddr The address of user
	* @return Whether or not updateRewardLane succeed
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

		/* To calculate the amount of rewards that change as the block flows, bring in the user's deposit, borrow, and total deposit, total borrow of the market */
		uint256 currentBlockNum = block.number;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositTotalAmount, borrowTotalAmount, depositUserAmount, borrowUserAmount) = handlerDataStorage.getAmount(userAddr);

		/* Update the market's reward parameter value according to the rate of beta(the rate of weight) if the time of call is later than when the reward was updated */
		if (market.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 _delta = sub(currentBlockNum, market.rewardLaneUpdateAt);
			uint256 betaRateBaseTotalAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
			if (betaRateBaseTotalAmount != 0)
			{
				market.rewardLane = add(market.rewardLane, _calcRewardLaneDistance(_delta, market.rewardPerBlock, betaRateBaseTotalAmount));
			}

			_SIHandlerDataStorage.setMarketRewardInfo(market.rewardLane, currentBlockNum, market.rewardPerBlock);
		}

		/* Update the user's reward parameter value according to the rate of beta(the rate of weight) if the time of call is later than when the reward was updated */
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
	* @dev Calculates the number of rewards given according to the gap of block number
	* @param _delta The amount of blockNumber's gap
	* @param _rewardPerBlock The amount of reward per block
	* @param _total The total amount of betaRate
	* @return The result of reward given according to the block number gap
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
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The amount of user's betaRate
	*/
	function getBetaRateBaseUserAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getBetaRateBaseUserAmount(userAddr);
	}

	/**
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The amount of user's betaRate
	*/
	function _getBetaRateBaseUserAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositUserAmount, borrowUserAmount) = handlerDataStorage.getUserAmount(userAddr);
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
	}

	/**
	* @dev Get the amount of user's accumulated rewards as tokens
	* and initialize user reward amount
	* @param userAddr The address of user who claimed
	* @return The amount of user's reward
	*/
	function claimRewardAmountUser(address payable userAddr) onlyMarketManager external override returns (uint256)
	{
		return _claimRewardAmountUser(userAddr);
	}

	/**
	* @dev Get the amount of user's accumulated rewards as tokens
	* and initialize user reward amount
	* @param userAddr The address of user who claimed
	* @return The amount of user's reward
	*/
	function _claimRewardAmountUser(address payable userAddr) internal returns (uint256)
	{
		UserRewardInfo memory user;
		uint256 currentBlockNum = block.number;
		(user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = SIHandlerDataStorage.getUserRewardInfo(userAddr);
		SIHandlerDataStorage.setUserRewardInfo(userAddr, user.rewardLane, currentBlockNum, 0);
		return user.rewardAmount;
	}

	/**
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param _beta The rate of beta
	* @param _depositAmount The amount of user's deposit
	* @param _borrowAmount The amount of user's borrow
	* @return The amount of user's betaRate
	*/
	function _calcBetaBaseAmount(uint256 _beta, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return add(unifiedMul(_depositAmount, _beta), unifiedMul(_borrowAmount, sub(unifiedPoint, _beta)));
	}

	/**
	* @dev Get reward parameters related the market
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardPerBlock)
	*/
	function getMarketRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getMarketRewardInfo();
	}

	/**
	* @dev Get reward parameters related the user
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardAmount)
	*/
	function getUserRewardInfo(address payable userAddr) external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getUserRewardInfo(userAddr);
	}

	/**
	* @dev Get the rate of beta
	* @return The rate of beta
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
