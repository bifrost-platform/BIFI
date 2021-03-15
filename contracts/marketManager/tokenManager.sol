// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/marketManagerInterface.sol";

import "../interfacesForManager/managerDataStorageInterfaceForManager.sol";
import "../interfacesForManager/oracleProxyInterfaceForManager.sol";

import "../interfaces/liquidationManagerInterface.sol";
import "../interfaces/proxyContractInterface.sol";
import "../interfaces/tokenInterface.sol";
import "../Errors.sol";
import "../SafeMath.sol";

import "../interfaces/observerInterface.sol";

import "../interfaces/marketHandlerInterface.sol";
import "../interfaces/SIInterface.sol";

/**
 * @title Bifi's marketManager contract
 * @notice Implement business logic and manage handlers
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract etherManager is marketManagerInterface, ManagerErrors {
	using SafeMath for uint256;

	address public owner;
	mapping(address => bool) operators;
	mapping(address => Breaker) internal breakerTable;

	bool public emergency = false;

	managerDataStorageInterfaceForManager internal dataStorageInstance;
	oracleProxyInterfaceForManager internal oracleProxy;

	/* feat: manager reward token instance*/
	IERC20 internal rewardErc20Instance;

	observerInterface public observer;

	uint256 public tokenHandlerLength;

	event HandlerRewardUpdate(uint256 handlerID, uint256 alphaBaseAsset, uint256 rewardPerBlocks);
	event ChainRewardUpdate(uint256 chainID, uint256 alphaBaseAsset, uint256 rewardPerBlocks);

	struct UserAssetsInfo {
		uint256 depositAssetSum;
		uint256 borrowAssetSum;
		uint256 marginCallLimitSum;
		uint256 depositAssetBorrowLimitSum;
		uint256 depositAsset;
		uint256 borrowAsset;
		uint256 price;
		uint256 callerPrice;
		uint256 depositAmount;
		uint256 borrowAmount;
		uint256 borrowLimit;
		uint256 marginCallLimit;
		uint256 callerBorrowLimit;
		uint256 userBorrowableAsset;
		uint256 withdrawableAsset;
	}

	struct Breaker {
		bool auth;
		bool tried;
	}

	struct ContractInfo {
		bool support;
		address addr;

		proxyContractInterface tokenHandler;
		bytes data;

		marketHandlerInterface handlerFunction;
		SIInterface siFunction;

		oracleProxyInterfaceForManager oracleProxy;
		managerDataStorageInterfaceForManager managerDataStorage;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyHandler(uint256 handlerID) {
		_isHandler(handlerID);
		_;
	}

	modifier onlyOperators {
		address payable sender = msg.sender;
		require(operators[sender] || sender == owner);
		_;
	}

	function _isHandler(uint256 handlerID) internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getTokenHandlerAddr(handlerID)) || (msgSender == owner), ONLY_HANDLER);
	}

	modifier onlyLiquidationManager {
		_isLiquidationManager();
		_;
	}

	function _isLiquidationManager() internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getLiquidationManagerAddr()) || (msgSender == owner), ONLY_LIQUIDATION_MANAGER);
	}

	modifier circuitBreaker {
		_isCircuitBreak();
		_;
	}

	function _isCircuitBreak() internal view {
		require((!emergency) || (msg.sender == owner), CIRCUIT_BREAKER);
	}

	modifier onlyBreaker {
		_isBreaker();
		_;
	}

	function _isBreaker() internal view {
		require(breakerTable[msg.sender].auth, ONLY_BREAKER);
	}

	/**
	* @dev Constructor for marketManager
	* @param managerDataStorageAddr The address of the manager storage contract
	* @param oracleProxyAddr The address of oracle proxy contract (e.g., price feeds)
	* @param breaker The address of default circuit breaker
	* @param erc20Addr The address of reward token (ERC-20)
	*/
	constructor (address managerDataStorageAddr, address oracleProxyAddr, address breaker, address erc20Addr) public
	{
		owner = msg.sender;
		dataStorageInstance = managerDataStorageInterfaceForManager(managerDataStorageAddr);
		oracleProxy = oracleProxyInterfaceForManager(oracleProxyAddr);
		rewardErc20Instance = IERC20(erc20Addr);
		breakerTable[owner].auth = true;
		breakerTable[breaker].auth = true;
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

	function setOperator(address payable adminAddr, bool flag) onlyOwner external returns (bool) {
		operators[adminAddr] = flag;
		return flag;
	}

	/**
	* @dev Set the address of oracleProxy contract
	* @param oracleProxyAddr The address of oracleProxy contract
	* @return true (TODO: validate results)
	*/
	function setOracleProxy(address oracleProxyAddr) onlyOwner external override returns (bool)
	{
		oracleProxy = oracleProxyInterfaceForManager(oracleProxyAddr);
		return true;
	}

	/**
	* @dev Set the address of BiFi reward token contract
	* @param erc20Addr The address of BiFi reward token contract
	* @return true (TODO: validate results)
	*/
	function setRewardErc20(address erc20Addr) onlyOwner public returns (bool)
	{
		rewardErc20Instance = IERC20(erc20Addr);
		return true;
	}

	/**
	* @dev Authorize admin user for circuitBreaker
	* @param _target The address of the circuitBreaker admin user.
	* @param _status The boolean status of circuitBreaker (on/off)
	* @return true (TODO: validate results)
	*/
	function setBreakerTable(address _target, bool _status) onlyOwner external override returns (bool)
	{
		breakerTable[_target].auth = _status;
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers
	* @param _emergency The boolean status of circuitBreaker (on/off)
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyBreaker external override returns (bool)
	{
		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));

			// use delegate call via handler proxy
			// for token handlers
			bytes memory callData = abi.encodeWithSelector(
				marketHandlerInterface
				.setCircuitBreaker.selector,
				_emergency
			);

			tokenHandler.handlerProxy(callData);
			tokenHandler.siProxy(callData);
		}

		liquidationManagerInterface liquidationManager = liquidationManagerInterface(dataStorageInstance.getLiquidationManagerAddr());
		liquidationManager.setCircuitBreaker(_emergency);
		emergency = _emergency;
		return true;
	}

	/**
	* @dev Get the circuitBreak status
	* @return The circuitBreak status
	*/
	function getCircuitBreaker() external view override returns (bool)
	{
		return emergency;
	}

	/**
	* @dev Get information for a handler
	* @param handlerID Handler ID
	* @return (success or failure, handler address, handler name)
	*/
	function getTokenHandlerInfo(uint256 handlerID) external view override returns (bool, address, string memory)
	{
		bool support;
		address tokenHandlerAddr;
		string memory tokenName;
		if (dataStorageInstance.getTokenHandlerSupport(handlerID))
		{
			tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
			proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
			bytes memory data;
			(, data) = tokenHandler.handlerViewProxy(
				abi.encodeWithSelector(
					marketHandlerInterface
					.getTokenName.selector
				)
			);
			tokenName = abi.decode(data, (string));
			support = true;
		}

		return (support, tokenHandlerAddr, tokenName);
	}

	/**
	* @dev Register a handler
	* @param handlerID Handler ID and address
	* @param tokenHandlerAddr The handler address
	* @return true (TODO: validate results)
	*/
	function handlerRegister(uint256 handlerID, address tokenHandlerAddr) onlyOwner external override returns (bool)
	{
    	dataStorageInstance.setTokenHandler(handlerID, tokenHandlerAddr);
		tokenHandlerLength = tokenHandlerLength + 1;
		return true;
	}

	/**
	* @dev Set a liquidation manager contract
	* @param liquidationManagetAddr The address of liquidiation manager
	* @return true (TODO: validate results)
	*/
	function setLiquidationManager(address liquidationManagetAddr) onlyOwner external override returns (bool)
	{
		dataStorageInstance.setLiquidationManagerAddr(liquidationManagetAddr);
		return true;
	}

	/**
	* @dev Update the (SI) rewards for a user
	* @param userAddr The address of the user
	* @param callerID The handler ID
	* @return true (TODO: validate results)
	*/
	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external override returns (bool)
	{
		ContractInfo memory handlerInfo;
		(handlerInfo.support, handlerInfo.addr) = dataStorageInstance.getTokenHandlerInfo(callerID);
		if (handlerInfo.support)
		{
			proxyContractInterface tokenHandler;
			tokenHandler = proxyContractInterface(handlerInfo.addr);
			tokenHandler.siProxy(
				abi.encodeWithSelector(
					SIInterface
					.updateRewardLane.selector,
					userAddr
				)
			);
		}

		return true;
	}

	/**
	* @dev Update interest of a user for a handler (internal)
	* @param userAddr The user address
	* @param callerID The handler ID
	* @param allFlag Flag for the full calculation mode (calculting for all handlers)
	* @return (uint256, uint256, uint256, uint256, uint256, uint256)
	*/
	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external override returns (uint256, uint256, uint256, uint256, uint256, uint256)
	{
		UserAssetsInfo memory userAssetsInfo;
		ContractInfo memory handlerInfo;
		handlerInfo.oracleProxy = oracleProxy;
		handlerInfo.managerDataStorage = dataStorageInstance;

		/* From all handlers, get the token price, margin call limit, borrow limit */
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			(handlerInfo.support, handlerInfo.addr) = handlerInfo.managerDataStorage.getTokenHandlerInfo(handlerID);
			if (handlerInfo.support)
			{
				handlerInfo.tokenHandler = proxyContractInterface(handlerInfo.addr);

				/* If the full-calculation mode is not set, work on the given handler only */
				if ((handlerID == callerID) || allFlag)
				{
					handlerInfo.tokenHandler.siProxy(
						abi.encodeWithSelector(
							handlerInfo.siFunction
							.updateRewardLane.selector,
							userAddr
						)
					);
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerProxy(
						abi.encodeWithSelector(
							handlerInfo.handlerFunction
							.applyInterest.selector,
							userAddr
						)
					);

					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}
				else
				{
					/* Get the deposit and borrow amount for the user */
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
						abi.encodeWithSelector(
							handlerInfo.handlerFunction
							.getUserAmount.selector,
							userAddr
						)
					);
					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}

				(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
					abi.encodeWithSelector(
						handlerInfo.handlerFunction
						.getTokenHandlerLimit.selector
					)
				);
				(userAssetsInfo.borrowLimit, userAssetsInfo.marginCallLimit) = abi.decode(handlerInfo.data, (uint256, uint256));

				/* Get the token price */
				if (handlerID == callerID)
				{
					userAssetsInfo.price = handlerInfo.oracleProxy.getTokenPrice(handlerID);
					userAssetsInfo.callerPrice = userAssetsInfo.price;
					userAssetsInfo.callerBorrowLimit = userAssetsInfo.borrowLimit;
				}

				/* If the user has no balance, the token handler can be ignored.*/
				if ((userAssetsInfo.depositAmount > 0) || (userAssetsInfo.borrowAmount > 0))
				{
					if (handlerID != callerID)
					{
						userAssetsInfo.price = handlerInfo.oracleProxy.getTokenPrice(handlerID);
					}

					/* Compute the deposit parameters */
					if (userAssetsInfo.depositAmount > 0)
					{
						userAssetsInfo.depositAsset = userAssetsInfo.depositAmount.unifiedMul(userAssetsInfo.price);
						userAssetsInfo.depositAssetBorrowLimitSum = userAssetsInfo.depositAssetBorrowLimitSum.add(userAssetsInfo.depositAsset.unifiedMul(userAssetsInfo.borrowLimit));
						userAssetsInfo.marginCallLimitSum = userAssetsInfo.marginCallLimitSum.add(userAssetsInfo.depositAsset.unifiedMul(userAssetsInfo.marginCallLimit));
						userAssetsInfo.depositAssetSum = userAssetsInfo.depositAssetSum.add(userAssetsInfo.depositAsset);
					}

					/* Compute the borrow parameters */
					if (userAssetsInfo.borrowAmount > 0)
					{
						userAssetsInfo.borrowAsset = userAssetsInfo.borrowAmount.unifiedMul(userAssetsInfo.price);
						userAssetsInfo.borrowAssetSum = userAssetsInfo.borrowAssetSum.add(userAssetsInfo.borrowAsset);
					}

				}

			}

		}

		if (userAssetsInfo.depositAssetBorrowLimitSum > userAssetsInfo.borrowAssetSum)
		{
			/* Set the amount that the user can borrow from the borrow limit and previous borrows. */
			userAssetsInfo.userBorrowableAsset = userAssetsInfo.depositAssetBorrowLimitSum.sub(userAssetsInfo.borrowAssetSum);

			/* Set the allowed amount that the user can withdraw based on the user borrow */
			userAssetsInfo.withdrawableAsset = userAssetsInfo.depositAssetBorrowLimitSum.sub(userAssetsInfo.borrowAssetSum).unifiedDiv(userAssetsInfo.callerBorrowLimit);
		}

		/* Return the calculated parameters */
		return (userAssetsInfo.userBorrowableAsset.unifiedDiv(userAssetsInfo.callerPrice), userAssetsInfo.withdrawableAsset.unifiedDiv(userAssetsInfo.callerPrice), userAssetsInfo.marginCallLimitSum, userAssetsInfo.depositAssetSum, userAssetsInfo.borrowAssetSum, userAssetsInfo.callerPrice);
	}

	/**
	* @dev Reward the user (msg.sender) with the reward token after calculating interest.
	* @return true (TODO: validate results)
	*/
	function interestUpdateReward() external override returns (bool)
	{
		uint256 thisBlock = block.number;
		uint256 interestRewardUpdated = dataStorageInstance.getInterestRewardUpdated();
		uint256 delta = thisBlock - interestRewardUpdated;
		if (delta == 0)
		{
			return false;
		}

		dataStorageInstance.setInterestRewardUpdated(thisBlock);
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
			bytes memory data;
			(, data) = tokenHandler.handlerProxy(
				abi.encodeWithSelector(
					marketHandlerInterface
					.checkFirstAction.selector
				)
			);
		}

		/* transfer reward tokens */
		return _rewardTransfer(msg.sender, delta.mul(dataStorageInstance.getInterestUpdateRewardPerblock()));
	}

	/**
	* @dev (Update operation) update the rewards parameters.
	* @param userAddr The address of operator
	* @return Whether or not the operation succeed
	*/
	function updateRewardParams(address payable userAddr) onlyOperators external override returns (bool)
	{
		if (_determineRewardParams(userAddr))
		{
			return _calcRewardParams(userAddr);
		}

		return false;
	}

	/**
	* @dev Claim all rewards for the user
	* @param userAddr The user address
	* @return true (TODO: validate results)
	*/
	function rewardClaimAll(address payable userAddr) external override returns (uint256)
	{
		uint256 handlerID;
		uint256 claimAmountSum;
		for (handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			claimAmountSum = claimAmountSum.add(_claimHandlerRewardAmount(handlerID, userAddr));
		}
		require(_rewardTransfer(userAddr, claimAmountSum));
		return claimAmountSum;
	}

	/* TODO: comment */
	function claimHandlerReward(uint256 handlerID, address payable userAddr) external returns (uint256) {
		uint256 amount = _claimHandlerRewardAmount(handlerID, userAddr);

		require(_rewardTransfer(userAddr, amount));

		return amount;
	}

	/* TODO: comment */
	function _claimHandlerRewardAmount(uint256 handlerID, address payable userAddr) internal returns (uint256) {
		bytes memory data;

		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		tokenHandler.siProxy(
			abi.encodeWithSelector(
				SIInterface
				.updateRewardLane.selector,
				userAddr
			)
		);

		/* Claim reward for a token handler */
		(, data) = tokenHandler.siProxy(
			abi.encodeWithSelector(
				SIInterface.claimRewardAmountUser.selector,
				userAddr
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Transfer reward tokens to owner (for administration)
	* @param _amount The amount of the reward token
	* @return true (TODO: validate results)
	*/
	function ownerRewardTransfer(uint256 _amount) onlyOwner external override returns (bool)
	{
		return _rewardTransfer(address(uint160(owner)), _amount);
	}

	/**
	* @dev Transfer reward tokens to a user
	* @param userAddr The address of recipient
	* @param _amount The amount of the reward token
	* @return true (TODO: validate results)
	*/
	function _rewardTransfer(address payable userAddr, uint256 _amount) internal returns (bool)
	{
		IERC20 _rewardERC20 = rewardErc20Instance;

		if(address(_rewardERC20) != address(0x0)) {
			uint256 beforeBalance = _rewardERC20.balanceOf(userAddr);
			_rewardERC20.transfer(userAddr, _amount);
			require(_amount == _rewardERC20.balanceOf(userAddr).sub(beforeBalance), REWARD_TRANSFER);
			return true;
		}
	}

	/**
	* @dev (Update operation) update the rewards parameters (by using alpha- and
	  beta-score).
	* @param userAddr The address of the operator
	* @return Whether or not this process succeed
	*/
	function _determineRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 thisBlockNum = block.number;
		managerDataStorageInterfaceForManager _dataStorage = dataStorageInstance;
		/* The inactive period (delta) since the last action happens */
		uint256 delta = thisBlockNum - _dataStorage.getRewardParamUpdated();
		_dataStorage.setRewardParamUpdated(thisBlockNum);
		if (delta == 0)
		{
			return false;
		}

		/* Rewards assigned for a block */
		uint256 globalRewardPerBlock = _dataStorage.getGlobalRewardPerBlock();
		/* Rewards decrement for a block. (Rewards per block monotonically decreases) */
		uint256 globalRewardDecrement = _dataStorage.getGlobalRewardDecrement();
		/* Total amount of rewards */
		uint256 globalRewardTotalAmount = _dataStorage.getGlobalRewardTotalAmount();

		/* Remaining periods for reward distribution */
		uint256 remainingPeriod = globalRewardPerBlock.unifiedDiv(globalRewardDecrement);

		if (remainingPeriod >= delta.mul(SafeMath.unifiedPoint))
		{
			remainingPeriod = remainingPeriod.sub(delta.mul(SafeMath.unifiedPoint));
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		if (globalRewardTotalAmount >= globalRewardPerBlock.mul(delta))
		{
			globalRewardTotalAmount = globalRewardTotalAmount - globalRewardPerBlock.mul(delta);
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		globalRewardPerBlock = globalRewardTotalAmount.mul(2).unifiedDiv(remainingPeriod.add(SafeMath.unifiedPoint));
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, globalRewardPerBlock, globalRewardDecrement, globalRewardTotalAmount);
	}

	/**
	* @dev Epilogue of _determineRewardParams for code-size savings
	* @param _dataStorage interface of Manager Data Storage
	* @param userAddr User Address for Reward token transfer
	* @param _delta The inactive period (delta) since the last action happens
	* @param _globalRewardPerBlock Reward per block
	* @param _globalRewardDecrement Rewards decrement for a block
	* @param _globalRewardTotalAmount Total amount of rewards
	* @return true (TODO: validate results)
	*/
	function _epilogueOfDetermineRewardParams(
		managerDataStorageInterfaceForManager _dataStorage,
		address payable userAddr,
		uint256 _delta,
		uint256 _globalRewardPerBlock,
		uint256 _globalRewardDecrement,
		uint256 _globalRewardTotalAmount
	) internal returns (bool) {
    // Set the reward model parameters
    	_dataStorage.setGlobalRewardPerBlock(_globalRewardPerBlock);
		_dataStorage.setGlobalRewardDecrement(_globalRewardDecrement);
		_dataStorage.setGlobalRewardTotalAmount(_globalRewardTotalAmount);

		uint256 rewardAmount = _delta.mul(_dataStorage.getRewardParamUpdateRewardPerBlock());
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		_rewardTransfer(userAddr, rewardAmount);
		return true;
	}

	/**
	* @dev Update rewards paramters of token handlers.
	* @param userAddr The address of operator
	* @return true (TODO: validate results)
	*/
	function _calcRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 handlerLength = tokenHandlerLength;
		bytes memory data;
		uint256[] memory handlerAlphaRateBaseAsset = new uint256[](handlerLength);
		uint256[] memory chainAlphaRateBaseAsset;
		uint256 handlerID;
		uint256 alphaRateBaseGlobalAssetSum;
		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			handlerAlphaRateBaseAsset[handlerID] = _getAlphaBaseAsset(handlerID);
			alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(handlerAlphaRateBaseAsset[handlerID]);
		}

		chainAlphaRateBaseAsset = observer.getAlphaBaseAsset();
		handlerID = 0;
		for (;handlerID < chainAlphaRateBaseAsset.length; handlerID++) {
			alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(chainAlphaRateBaseAsset[handlerID]);
		}

		handlerID = 0;
		uint256 globalRewardPerBlocks = dataStorageInstance.getGlobalRewardPerBlock();

		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
			(, data) = tokenHandler.siProxy(
				abi.encodeWithSelector(
					SIInterface
					.updateRewardLane.selector,
					userAddr
				)
			);

			/* Update reward parameter for the token handler */
			uint256 rewardPerBlocks = globalRewardPerBlocks
								.unifiedMul(
								handlerAlphaRateBaseAsset[handlerID]
								.unifiedDiv(alphaRateBaseGlobalAssetSum)
								);
			data = abi.encodeWithSelector(
				SIInterface.updateRewardPerBlockLogic.selector,
				rewardPerBlocks
			);
			(, data) = tokenHandler.siProxy(data);

			emit HandlerRewardUpdate(handlerID, handlerAlphaRateBaseAsset[handlerID], rewardPerBlocks);
		}

		handlerID = 0;
		for (;handlerID < chainAlphaRateBaseAsset.length; handlerID++) {
			uint256 rewardPerBlocks = chainAlphaRateBaseAsset[handlerID]
										.unifiedDiv(alphaRateBaseGlobalAssetSum)
										.unifiedMul(globalRewardPerBlocks);

			observer.setChainGlobalRewardPerblock(
				handlerID,
				rewardPerBlocks
			);
			emit ChainRewardUpdate(handlerID, chainAlphaRateBaseAsset[handlerID], rewardPerBlocks);
		}

		return true;
	}

	/**
	* @dev Calculate the alpha-score for the handler (in USD price)
	* @param _handlerID The handler ID
	* @return The alpha-score of the handler
	*/
	function _getAlphaBaseAsset(uint256 _handlerID) internal view returns (uint256)
	{
		bytes memory data;
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(_handlerID));

    // TODO merge call
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface
				.getDepositTotalAmount.selector
			)
		);
		uint256 _depositAmount = abi.decode(data, (uint256));

		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface
				.getBorrowTotalAmount.selector
			)
		);
		uint256 _borrowAmount = abi.decode(data, (uint256));

		return _calcAlphaBaseAmount(
              dataStorageInstance.getAlphaRate(),
              _depositAmount,
              _borrowAmount
            )
            .unifiedMul(_getTokenHandlerPrice(_handlerID));
	}

	/**
	* @dev Calculate the alpha-score for the handler (in token amount)
	* @param _alpha The alpha parameter
	* @param _depositAmount The total amount of deposit
	* @param _borrowAmount The total amount of borrow
	* @return The alpha-score of the handler (in token amount)
	*/
	function _calcAlphaBaseAmount(uint256 _alpha, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return _depositAmount.unifiedMul(_alpha).add(_borrowAmount.unifiedMul(SafeMath.unifiedPoint.sub(_alpha)));
	}

	/**
	* @dev Get the token price of the handler
	* @param handlerID The handler ID
	* @return The token price of the handler
	*/
	function getTokenHandlerPrice(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerPrice(handlerID);
	}

	/**
	* @dev Get the margin call limit of the handler (external)
	* @param handlerID The handler ID
	* @return The margin call limit
	*/
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerMarginCallLimit(handlerID);
	}

	/**
	* @dev Get the margin call limit of the handler (internal)
	* @param handlerID The handler ID
	* @return The margin call limit
	*/
	function _getTokenHandlerMarginCallLimit(uint256 handlerID) internal view returns (uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface
				.getTokenHandlerMarginCallLimit.selector
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the borrow limit of the handler (external)
	* @param handlerID The handler ID
	* @return The borrow limit
	*/
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerBorrowLimit(handlerID);
	}

	/**
	* @dev Get the borrow limit of the handler (internal)
	* @param handlerID The handler ID
	* @return The borrow limit
	*/
	function _getTokenHandlerBorrowLimit(uint256 handlerID) internal view returns (uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));

		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface
				.getTokenHandlerBorrowLimit.selector
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the handler status of whether the handler is supported or not.
	* @param handlerID The handler ID
	* @return Whether the handler is supported or not
	*/
	function getTokenHandlerSupport(uint256 handlerID) external view override returns (bool)
	{
		return dataStorageInstance.getTokenHandlerSupport(handlerID);
	}

	/**
	* @dev Set the length of the handler list
	* @param _tokenHandlerLength The length of the handler list
	* @return true (TODO: validate results)
	*/
	function setTokenHandlersLength(uint256 _tokenHandlerLength) onlyOwner external override returns (bool)
	{
		tokenHandlerLength = _tokenHandlerLength;
		return true;
	}

	/**
	* @dev Get the length of the handler list
	* @return the length of the handler list
	*/
	function getTokenHandlersLength() external view override returns (uint256)
	{
		return tokenHandlerLength;
	}

	/**
	* @dev Get the handler ID at the index in the handler list
	* @param index The index of the handler list (array)
	* @return The handler ID
	*/
	function getTokenHandlerID(uint256 index) external view override returns (uint256)
	{
		return dataStorageInstance.getTokenHandlerID(index);
	}

	/**
	* @dev Get the amount of token that the user can borrow more
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The amount of token that user can borrow more
	*/
	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view override returns (uint256)
	{
		uint256 depositCredit;
		uint256 borrowCredit;
		(depositCredit, borrowCredit) = _getUserTotalIntraCreditAsset(userAddr);
		if (depositCredit == 0)
		{
			return 0;
		}

		if (depositCredit > borrowCredit)
		{
			return depositCredit.sub(borrowCredit).unifiedDiv(_getTokenHandlerPrice(handlerID));
		}
		else
		{
			return 0;
		}

	}

	/**
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	/* about user market Information function*/
	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view override returns (uint256, uint256)
	{
		return _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
	}

	/**
	* @dev Get the depositTotalCredit and borrowTotalCredit
	* @param userAddr The address of the user
	* @return depositTotalCredit The amount that users can borrow (i.e. deposit * borrowLimit)
	* @return borrowTotalCredit The sum of borrow amount for all handlers
	*/
	function getUserTotalIntraCreditAsset(address payable userAddr) external view override returns (uint256, uint256)
	{
		return _getUserTotalIntraCreditAsset(userAddr);
	}

	/**
	* @dev Get the borrow and margin call limits of the user for all handlers
	* @param userAddr The address of the user
	* @return userTotalBorrowLimitAsset the sum of borrow limit for all handlers
	* @return userTotalMarginCallLimitAsset the sume of margin call limit for handlers
	*/
	function getUserLimitIntraAsset(address payable userAddr) external view override returns (uint256, uint256)
	{
		uint256 userTotalBorrowLimitAsset;
		uint256 userTotalMarginCallLimitAsset;

		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{
				uint256 depositHandlerAsset;
				uint256 borrowHandlerAsset;
				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				uint256 borrowLimit = _getTokenHandlerBorrowLimit(handlerID);
				uint256 marginCallLimit = _getTokenHandlerMarginCallLimit(handlerID);
				uint256 userBorrowLimitAsset = depositHandlerAsset.unifiedMul(borrowLimit);
				uint256 userMarginCallLimitAsset = depositHandlerAsset.unifiedMul(marginCallLimit);
				userTotalBorrowLimitAsset = userTotalBorrowLimitAsset.add(userBorrowLimitAsset);
				userTotalMarginCallLimitAsset = userTotalMarginCallLimitAsset.add(userMarginCallLimitAsset);
			}
			else
			{
				continue;
			}

		}

		return (userTotalBorrowLimitAsset, userTotalMarginCallLimitAsset);
	}


	/**
	* @dev Get the maximum allowed amount to borrow of the user from the given handler
	* @param userAddr The address of the user
	* @param callerID The target handler to borrow
	* @return extraCollateralAmount The maximum allowed amount to borrow from
	  the handler.
	*/
	function getUserCollateralizableAmount(address payable userAddr, uint256 callerID) external view override returns (uint256)
	{
		uint256 userTotalBorrowAsset;
		uint256 depositAssetBorrowLimitSum;
		uint256 depositHandlerAsset;
		uint256 borrowHandlerAsset;
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{

				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				userTotalBorrowAsset = userTotalBorrowAsset.add(borrowHandlerAsset);
				depositAssetBorrowLimitSum = depositAssetBorrowLimitSum
												.add(
													depositHandlerAsset
													.unifiedMul( _getTokenHandlerBorrowLimit(handlerID) )
												);
			}
		}

		if (depositAssetBorrowLimitSum > userTotalBorrowAsset)
		{
			return depositAssetBorrowLimitSum
					.sub(userTotalBorrowAsset)
					.unifiedDiv( _getTokenHandlerBorrowLimit(callerID) )
					.unifiedDiv( _getTokenHandlerPrice(callerID) );
		}
		return 0;
	}

	/**
	* @dev Partial liquidation for a user
	* @param delinquentBorrower The address of the liquidation target
	* @param liquidateAmount The amount to liquidate
	* @param liquidator The address of the liquidator (liquidation operator)
	* @param liquidateHandlerID The hander ID of the liquidating asset
	* @param rewardHandlerID The handler ID of the reward token for the liquidator
	* @return (uint256, uint256, uint256)
	*/
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) onlyLiquidationManager external override returns (uint256, uint256, uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(liquidateHandlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		bytes memory data;

		data = abi.encodeWithSelector(
			marketHandlerInterface
			.partialLiquidationUser.selector,

			delinquentBorrower,
			liquidateAmount,
			liquidator,
			rewardHandlerID
		);
		(, data) = tokenHandler.handlerProxy(data);

		return abi.decode(data, (uint256, uint256, uint256));
	}

	/**
	* @dev Get the maximum liquidation reward by checking sufficient reward
	  amount for the liquidator.
	* @param delinquentBorrower The address of the liquidation target
	* @param liquidateHandlerID The hander ID of the liquidating asset
	* @param liquidateAmount The amount to liquidate
	* @param rewardHandlerID The handler ID of the reward token for the liquidator
	* @param rewardRatio delinquentBorrowAsset / delinquentDepositAsset
	* @return The maximum reward token amount for the liquidator
	*/
	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view override returns (uint256)
	{
		uint256 liquidatePrice = _getTokenHandlerPrice(liquidateHandlerID);
		uint256 rewardPrice = _getTokenHandlerPrice(rewardHandlerID);
		uint256 delinquentBorrowerRewardDeposit;
		(delinquentBorrowerRewardDeposit, ) = _getHandlerAmount(delinquentBorrower, rewardHandlerID);
		uint256 rewardAsset = delinquentBorrowerRewardDeposit.unifiedMul(rewardPrice).unifiedMul(rewardRatio);
		if (liquidateAmount.unifiedMul(liquidatePrice) > rewardAsset)
		{
			return rewardAsset.unifiedDiv(liquidatePrice);
		}
		else
		{
			return liquidateAmount;
		}

	}

	/**
	* @dev Reward the liquidator
	* @param delinquentBorrower The address of the liquidation target
	* @param rewardAmount The amount of reward token
	* @param liquidator The address of the liquidator (liquidation operator)
	* @param handlerID The handler ID of the reward token for the liquidator
	* @return The amount of reward token
	*/
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) onlyLiquidationManager external override returns (uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		bytes memory data;
		data = abi.encodeWithSelector(
			marketHandlerInterface
			.partialLiquidationUserReward.selector,

			delinquentBorrower,
			rewardAmount,
			liquidator
		);
		(, data) = tokenHandler.handlerProxy(data);

		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the deposit and borrow amount of the user for the handler (internal)
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount
	*/
	function _getHandlerAmount(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface
				.getUserAmount.selector,
				userAddr
			)
		);
		return abi.decode(data, (uint256, uint256));
	}

	/**
	* @dev Set the support stauts for the handler
	* @param handlerID the handler ID
	* @param support the support status (boolean)
	* @return true (TODO: validate results)
	*/
	function setHandlerSupport(uint256 handlerID, bool support) onlyOwner public returns (bool)
	{
		require(!dataStorageInstance.getTokenHandlerExist(handlerID), UNSUPPORTED_TOKEN);
		/* activate or inactivate anyway*/
		dataStorageInstance.setTokenHandlerSupport(handlerID, support);
		return true;
	}

	/**
	* @dev Get owner's address of the manager contract
	* @return The address of owner
	*/
	function getOwner() public view returns (address)
	{
		return owner;
	}

	/**
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	function _getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		uint256 price = _getTokenHandlerPrice(handlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		uint256 depositAmount;
		uint256 borrowAmount;

		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				marketHandlerInterface.getUserAmountWithInterest.selector,
				userAddr
			)
		);
		(depositAmount, borrowAmount) = abi.decode(data, (uint256, uint256));

		uint256 depositAsset = depositAmount.unifiedMul(price);
		uint256 borrowAsset = borrowAmount.unifiedMul(price);
		return (depositAsset, borrowAsset);
	}

	/**
	* @dev Get the depositTotalCredit and borrowTotalCredit
	* @param userAddr The address of the user
	* @return depositTotalCredit The amount that users can borrow (i.e. deposit * borrowLimit)
	* @return borrowTotalCredit The sum of borrow amount for all handlers
	*/
	function _getUserTotalIntraCreditAsset(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalCredit;
		uint256 borrowTotalCredit;
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{
				uint256 depositHandlerAsset;
				uint256 borrowHandlerAsset;
				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				uint256 borrowLimit = _getTokenHandlerBorrowLimit(handlerID);
				uint256 depositHandlerCredit = depositHandlerAsset.unifiedMul(borrowLimit);
				depositTotalCredit = depositTotalCredit.add(depositHandlerCredit);
				borrowTotalCredit = borrowTotalCredit.add(borrowHandlerAsset);
			}
			else
			{
				continue;
			}

		}

		return (depositTotalCredit, borrowTotalCredit);
	}

	/**
	* @dev Get the token price for the handler
	* @param handlerID The handler id
	* @return The token price of the handler
	*/
	function _getTokenHandlerPrice(uint256 handlerID) internal view returns (uint256)
	{
		return (oracleProxy.getTokenPrice(handlerID));
	}

	/**
	* @dev Get the address of reward token
	* @return The address of reward token
	*/
	function getRewardErc20() public view returns (address)
	{
		return address(rewardErc20Instance);
	}

	/**
	* @dev Get the reward parameters
	* @return (uint256,uint256,uint256) rewardPerBlock, rewardDecrement, rewardTotalAmount
	*/
	function getGlobalRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		managerDataStorageInterfaceForManager _dataStorage = dataStorageInstance;
		return (_dataStorage.getGlobalRewardPerBlock(), _dataStorage.getGlobalRewardDecrement(), _dataStorage.getGlobalRewardTotalAmount());
	}

	function setObserverAddr(address observerAddr) onlyOwner external returns (bool) {
		observer = observerInterface( observerAddr );
	}
}
