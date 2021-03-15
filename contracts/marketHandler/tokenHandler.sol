// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/marketHandlerInterface.sol";
import "../interfaces/marketHandlerDataStorageInterface.sol";
import "../interfaces/marketManagerInterface.sol";
import "../interfaces/interestModelInterface.sol";
import "../interfaces/marketSIHandlerDataStorageInterface.sol";
import "../interfaces/tokenInterface.sol";
import "../interfaces/proxyContractInterface.sol";
import "../interfaces/SIInterface.sol";
import "../Errors.sol";


/**
 * @title Bifi's tokenHandler logic contract for ERC20 tokens
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract tokenHandler is marketHandlerInterface, HandlerErrors {
	event MarketIn(address userAddr);

	event Deposit(address depositor, uint256 depositAmount, uint256 handlerID);
	event Withdraw(address redeemer, uint256 redeemAmount, uint256 handlerID);
	event Borrow(address borrower, uint256 borrowAmount, uint256 handlerID);
	event Repay(address repayer, uint256 repayAmount, uint256 handlerID);

	event ReserveDeposit(uint256 reserveDepositAmount, uint256 handlerID);
	event ReserveWithdraw(uint256 reserveWithdrawAmount, uint256 handlerID);

	event OwnershipTransferred(address owner, address newOwner);

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

	struct ProxyInfo {
		bool result;
		bytes returnData;
		bytes data;
		bytes proxyData;
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
	* @dev Set circuitBreak to freeze all of handlers by owner
	* @param _emergency Boolean state of the circuit break.
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setCircuitBreaker(_emergency);

		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers by marketManager
	* @param _emergency Boolean state of the circuit break.
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyMarketManager external override returns (bool)
	{
		handlerDataStorage.setCircuitBreaker(_emergency);

		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Change the owner of the handler
	* @param newOwner the address of the owner to be replaced
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable newOwner) onlyOwner external override returns (bool)
	{
		owner = newOwner;

		emit OwnershipTransferred(owner, newOwner);
		return true;
	}

	/**
	* @dev Get the token name
   * @return the token name
	*/
	function getTokenName() external view override returns (string memory)
	{
		return tokenName;
	}

	/**
	* @dev Deposit assets to the reserve of the handler.
	* @param unifiedTokenAmount The amount of token to deposit
	* @return true (TODO: validate results)
	*/
	function reserveDeposit(uint256 unifiedTokenAmount) external payable override returns (bool)
	{
		require(msg.value == 0, USE_ARG);

		handlerDataStorage.addReservedAmount(unifiedTokenAmount);
		handlerDataStorage.addDepositTotalAmount(unifiedTokenAmount);

		_transferFrom(msg.sender, unifiedTokenAmount);

		emit ReserveDeposit(unifiedTokenAmount, handlerID);
		return true;
	}

	/**
	* @dev Withdraw assets from the reserve of the handler.
	* @param unifiedTokenAmount The amount of token to withdraw
	* @return true (TODO: validate results)
	*/
	function reserveWithdraw(uint256 unifiedTokenAmount) onlyOwner external override returns (bool)
	{
		address payable reserveAddr = handlerDataStorage.getReservedAddr();

		handlerDataStorage.subReservedAmount(unifiedTokenAmount);
		handlerDataStorage.subDepositTotalAmount(unifiedTokenAmount);

		_transfer(reserveAddr, unifiedTokenAmount);

		emit ReserveWithdraw(unifiedTokenAmount, handlerID);
		return true;
	}

	/**
	* @dev Deposit action
	* @param unifiedTokenAmount The deposit amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function deposit(uint256 unifiedTokenAmount, bool flag) external payable override returns (bool)
	{
		require(msg.value == 0, USE_ARG);

		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		if(flag) {
			// flag is true, update interest, reward all handlers
			marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		} else {
			marketManager.rewardUpdateOfInAction(userAddr, _handlerID);
			_applyInterest(userAddr);
		}

		handlerDataStorage.addDepositAmount(userAddr, unifiedTokenAmount);

		_transferFrom(userAddr, unifiedTokenAmount);

		emit Deposit(userAddr, unifiedTokenAmount, _handlerID);
		return true;
	}

	/**
	* @dev Withdraw action
	* @param unifiedTokenAmount The withdraw amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function withdraw(uint256 unifiedTokenAmount, bool flag) external override returns (bool)
	{
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		uint256 userLiquidityAmount;
		uint256 userCollateralizableAmount;
		uint256 price;
		(userLiquidityAmount, userCollateralizableAmount, , , , price) = marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		require(unifiedMul(unifiedTokenAmount, price) <= handlerDataStorage.getLimitOfAction(), EXCEED_LIMIT);

		uint256 adjustedAmount = _getUserActionMaxWithdrawAmount(userAddr, unifiedTokenAmount, userCollateralizableAmount);

		handlerDataStorage.subDepositAmount(userAddr, adjustedAmount);

		_transfer(userAddr, adjustedAmount);

		emit Withdraw(userAddr, adjustedAmount, _handlerID);
		return true;
	}

	/**
	* @dev Borrow action
	* @param unifiedTokenAmount The borrow amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function borrow(uint256 unifiedTokenAmount, bool flag) external override returns (bool)
	{
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		uint256 userLiquidityAmount;
		uint256 userCollateralizableAmount;
		uint256 price;
		(userLiquidityAmount, userCollateralizableAmount, , , , price) = marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		require(unifiedMul(unifiedTokenAmount, price) <= handlerDataStorage.getLimitOfAction(), EXCEED_LIMIT);

		uint256 adjustedAmount = _getUserActionMaxBorrowAmount(unifiedTokenAmount, userLiquidityAmount);

		handlerDataStorage.addBorrowAmount(userAddr, adjustedAmount);

		_transfer(userAddr, adjustedAmount);

		emit Borrow(userAddr, adjustedAmount, _handlerID);
		return true;
	}

	/**
	* @dev Repay action
	* @param unifiedTokenAmount The repay amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function repay(uint256 unifiedTokenAmount, bool flag) external payable override returns (bool)
	{
		require(msg.value == 0, USE_ARG);
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		if(flag) {
			// flag is true, update interest, reward all handlers
			marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		} else {
			marketManager.rewardUpdateOfInAction(userAddr, _handlerID);
			_applyInterest(userAddr);
		}

		uint256 userBorrowAmount = handlerDataStorage.getUserIntraBorrowAmount(userAddr);

		if (userBorrowAmount < unifiedTokenAmount)
		{
			unifiedTokenAmount = userBorrowAmount;
		}

		handlerDataStorage.subBorrowAmount(userAddr, unifiedTokenAmount);

		_transferFrom(userAddr, unifiedTokenAmount);

		emit Repay(userAddr, unifiedTokenAmount, _handlerID);
		return true;
	}

	/**
	* @dev liquidate delinquentBorrower's partial(or can total) asset
	* @param delinquentBorrower The user addresss of liquidation target
	* @param liquidateAmount The amount of liquidator request
	* @param liquidator The address of a user executing liquidate
	* @param rewardHandlerID The handler id of delinquentBorrower's collateral for receive
	* @return (liquidateAmount, delinquentDepositAsset, delinquentBorrowAsset), result of liquidate
	*/
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 rewardHandlerID) onlyMarketManager external override returns (uint256, uint256, uint256)
	{
		/* over paied amount compaction */
		uint256 tmp;
		uint256 delinquentMarginCallDeposit;
		uint256 delinquentDepositAsset;
		uint256 delinquentBorrowAsset;
		uint256 liquidatorLiquidityAmount;

      /* apply interest for sync "latest" asset for delinquentBorrower and liquidator */
		(, , delinquentMarginCallDeposit, delinquentDepositAsset, delinquentBorrowAsset, ) = marketManager.applyInterestHandlers(delinquentBorrower, handlerID, false);
		(, liquidatorLiquidityAmount, , , , ) = marketManager.applyInterestHandlers(liquidator, handlerID, false);

      /* check delinquentBorrower liquidatable */
		require(delinquentMarginCallDeposit <= delinquentBorrowAsset, NO_LIQUIDATION);

		tmp = handlerDataStorage.getUserIntraDepositAmount(liquidator);
		if (tmp <= liquidateAmount)
		{
			liquidateAmount = tmp;
		}

		tmp = handlerDataStorage.getUserIntraBorrowAmount(delinquentBorrower);
		if (tmp <= liquidateAmount)
		{
			liquidateAmount = tmp;
		}

      /* get maximum "receive handler" amount by liquidate amount */
		liquidateAmount = marketManager.getMaxLiquidationReward(delinquentBorrower, handlerID, liquidateAmount, rewardHandlerID, unifiedDiv(delinquentBorrowAsset, delinquentDepositAsset));

      /* check liquidator has enough amount for liquidation */
		require(liquidatorLiquidityAmount > liquidateAmount, NO_EFFECTIVE_BALANCE);

      /* update storage for liquidate*/
		handlerDataStorage.subDepositAmount(liquidator, liquidateAmount);

		handlerDataStorage.subBorrowAmount(delinquentBorrower, liquidateAmount);

		return (liquidateAmount, delinquentDepositAsset, delinquentBorrowAsset);
	}

	/**
	* @dev liquidator receive delinquentBorrower's collateral after liquidate delinquentBorrower's asset
	* @param delinquentBorrower The user addresss of liquidation target
	* @param liquidationAmountWithReward The amount of liquidator receiving delinquentBorrower's collateral
	* @param liquidator The address of a user executing liquidate
	* @return The amount of token transfered(in storage)
	*/
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 liquidationAmountWithReward, address payable liquidator) onlyMarketManager external override returns (uint256)
	{
		marketManager.rewardUpdateOfInAction(delinquentBorrower, handlerID);
		_applyInterest(delinquentBorrower);
		/* check delinquentBorrower's collateral enough */
		uint256 collateralAmount = handlerDataStorage.getUserIntraDepositAmount(delinquentBorrower);
		require(collateralAmount >= liquidationAmountWithReward, NO_LIQUIDATION_REWARD);

		/* collateral transfer */
		handlerDataStorage.subDepositAmount(delinquentBorrower, liquidationAmountWithReward);

		_transfer(liquidator, liquidationAmountWithReward);

		return liquidationAmountWithReward;
	}

	/**
	* @dev Get borrowLimit and marginCallLimit
	* @return borrowLimit and marginCallLimit
	*/
	function getTokenHandlerLimit() external view override returns (uint256, uint256)
	{
		return handlerDataStorage.getLimit();
	}

	/**
	* @dev Set the borrow limit of the handler through a specific handlerID
	* @param borrowLimit The borrow limit
	* @return true (TODO: validate results)
	*/
	function setTokenHandlerBorrowLimit(uint256 borrowLimit) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setBorrowLimit(borrowLimit);
		return true;
	}

	/**
	* @dev Set the liquidation limit of the handler through a specific handlerID
	* @param marginCallLimit The liquidation limit
	* @return true (TODO: validate results)
	*/
	function setTokenHandlerMarginCallLimit(uint256 marginCallLimit) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setMarginCallLimit(marginCallLimit);
		return true;
	}

	/**
	* @dev Get the liquidation limit of handler through a specific handlerID
	* @return The liquidation limit
	*/
	function getTokenHandlerMarginCallLimit() external view override returns (uint256)
	{
		return handlerDataStorage.getMarginCallLimit();
	}

	/**
	* @dev Get the borrow limit of the handler through a specific handlerID
	* @return The borrow limit
	*/
	function getTokenHandlerBorrowLimit() external view override returns (uint256)
	{
		return handlerDataStorage.getBorrowLimit();
	}

	/**
	* @dev Get the maximum amount that user can borrow
	* @param userAddr The address of user
	* @return the maximum amount that user can borrow
	*/
	function getUserMaxBorrowAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getUserMaxBorrowAmount(userAddr);
	}

	/**
	* @dev Get the maximum amount that user can borrow
	* @param userAddr The address of user
	* @return the maximum amount that user can borrow
	*/
	function _getUserMaxBorrowAmount(address payable userAddr) internal view returns (uint256)
	{
		/* Prevent Action: over "Token Liquidity" amount*/
		uint256 handlerLiquidityAmount = _getTokenLiquidityLimitAmountWithInterest(userAddr);
		/* Prevent Action: over "CREDIT" amount */
		uint256 userLiquidityAmount = marketManager.getUserExtraLiquidityAmount(userAddr, handlerID);
		uint256 minAmount = userLiquidityAmount;
		if (handlerLiquidityAmount < minAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum amount that user can borrow
	* @param requestedAmount The amount of token to borrow
	* @param userLiquidityAmount The amount of liquidity that users can borrow
	* @return the maximum amount that user can borrow
	*/
	function _getUserActionMaxBorrowAmount(uint256 requestedAmount, uint256 userLiquidityAmount) internal view returns (uint256)
	{
		/* Prevent Action: over "Token Liquidity" amount*/
		uint256 handlerLiquidityAmount = _getTokenLiquidityLimitAmount();

		/* select minimum of handlerLiqudity and user liquidity */
		uint256 minAmount = requestedAmount;

		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		if (minAmount > userLiquidityAmount)
		{
			minAmount = userLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum amount that users can withdraw
	* @param userAddr The address of user
	* @return the maximum amount that users can withdraw
	*/
	function getUserMaxWithdrawAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getUserMaxWithdrawAmount(userAddr);
	}

	/**
	* @dev Get the rate of SIR and BIR
	* @return The rate of SIR and BIR
	*/
	function getSIRandBIR() external view override returns (uint256, uint256)
	{
		uint256 totalDepositAmount = handlerDataStorage.getDepositTotalAmount();
		uint256 totalBorrowAmount = handlerDataStorage.getBorrowTotalAmount();

		return interestModelInstance.getSIRandBIR(totalDepositAmount, totalBorrowAmount);
	}

	/**
	* @dev Get the maximum amount that users can withdraw
	* @param userAddr The address of user
	* @return the maximum amount that users can withdraw
	*/
	function _getUserMaxWithdrawAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositAmountWithInterest;
		uint256 borrowAmountWithInterest;
		(depositAmountWithInterest, borrowAmountWithInterest) = _getUserAmountWithInterest(userAddr);

		uint256 handlerLiquidityAmount = _getTokenLiquidityAmountWithInterest(userAddr);

		uint256 userLiquidityAmount = marketManager.getUserCollateralizableAmount(userAddr, handlerID);

		/* Prevent Action: over "DEPOSIT" amount */
		uint256 minAmount = depositAmountWithInterest;
		/* Prevent Action: over "CREDIT" amount */
		if (minAmount > userLiquidityAmount)
		{
			minAmount = userLiquidityAmount;
		}

		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum amount that users can withdraw
	* @param userAddr The address of user
	* @param requestedAmount The amount of token to withdraw
	* @param collateralableAmount The amount of liquidity that users can borrow
	* @return the maximum amount that users can withdraw
	*/
	function _getUserActionMaxWithdrawAmount(address payable userAddr, uint256 requestedAmount, uint256 collateralableAmount) internal view returns (uint256)
	{
		uint256 depositAmount = handlerDataStorage.getUserIntraDepositAmount(userAddr);

		uint256 handlerLiquidityAmount = _getTokenLiquidityAmount();

		/* select minimum among deposited, requested and collateralable*/
		uint256 minAmount = depositAmount;

		if (minAmount > requestedAmount)
		{
			minAmount = requestedAmount;
		}

		if (minAmount > collateralableAmount)
		{
			minAmount = collateralableAmount;
		}

		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum amount that users can repay
	* @param userAddr The address of user
	* @return the maximum amount that users can repay
	*/
	function getUserMaxRepayAmount(address payable userAddr) external view override returns (uint256)
	{
		uint256 depositAmountWithInterest;
		uint256 borrowAmountWithInterest;
		(depositAmountWithInterest, borrowAmountWithInterest) = _getUserAmountWithInterest(userAddr);

		return borrowAmountWithInterest;
	}

	/**
	* @dev Update (apply) interest entry point (external)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function applyInterest(address payable userAddr) external override returns (uint256, uint256)
	{
		return _applyInterest(userAddr);
	}

	/**
	* @dev Update (apply) interest entry point (external)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _applyInterest(address payable userAddr) internal returns (uint256, uint256)
	{
		_checkNewCustomer(userAddr);
		_checkFirstAction();
		return _updateInterestAmount(userAddr);
	}

	/**
	* @dev Check whether a given userAddr is a new user or not
	* @param userAddr The user address
	* @return true if the user is a new user; false otherwise.
	*/
	function _checkNewCustomer(address payable userAddr) internal returns (bool)
	{
		marketHandlerDataStorageInterface _handlerDataStorage = handlerDataStorage;
		if (_handlerDataStorage.getUserAccessed(userAddr))
		{
			return false;
		}
		/* hotfix */
		_handlerDataStorage.setUserAccessed(userAddr, true);

		(uint256 gDEXR, uint256 gBEXR) = _handlerDataStorage.getGlobalEXR();
		_handlerDataStorage.setUserEXR(userAddr, gDEXR, gBEXR);
		return true;
	}

	/**
	* @dev Get the address of the token that the handler is dealing with
	* (coinHandler don't deal with tokens in coin handlers)
	* @return The address of the token
	*/
	function getERC20Addr() external view returns (address)
	{
		return address(erc20Instance);
	}

	/**
	* @dev Get the amount of deposit and borrow of the user
	* @param userAddr The address of user
	* (depositAmount, borrowAmount)
	*/
	function getUserAmount(address payable userAddr) external view override returns (uint256, uint256)
	{
		uint256 depositAmount = handlerDataStorage.getUserIntraDepositAmount(userAddr);
		uint256 borrowAmount = handlerDataStorage.getUserIntraBorrowAmount(userAddr);

		return (depositAmount, borrowAmount);
	}

	/**
	* @dev Get the amount of user's deposit
	* @param userAddr The address of user
	* @return the amount of user's deposit
	*/
	function getUserIntraDepositAmount(address payable userAddr) external view returns (uint256)
	{
		return handlerDataStorage.getUserIntraDepositAmount(userAddr);
	}

	/**
	* @dev Get the amount of user's borrow
	* @param userAddr The address of user
	* @return the amount of user's borrow
	*/
	function getUserIntraBorrowAmount(address payable userAddr) external view returns (uint256)
	{
		return handlerDataStorage.getUserIntraBorrowAmount(userAddr);
	}

	/**
	* @dev Get the amount of handler's total deposit
	* @return the amount of handler's total deposit
	*/
	function getDepositTotalAmount() external view override returns (uint256)
	{
		return handlerDataStorage.getDepositTotalAmount();
	}

	/**
	* @dev Get the amount of handler's total borrow
	* @return the amount of handler's total borrow
	*/
	function getBorrowTotalAmount() external view override returns (uint256)
	{
		return handlerDataStorage.getBorrowTotalAmount();
	}

	/**
	* @dev Get the amount of deposit and borrow of user including interest
	* @param userAddr The user address
	* @return (userDepositAmount, userBorrowAmount)
	*/
	function getUserAmountWithInterest(address payable userAddr) external view override returns (uint256, uint256)
	{
		return _getUserAmountWithInterest(userAddr);
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
	* @dev Check first action of user in the This Block (external)
	* @return true for first action
	*/
	function checkFirstAction() onlyMarketManager external override returns (bool)
	{
		return _checkFirstAction();
	}

	/**
	* @dev Check first action of user in the This Block (external)
	* @return true for first action
	*/
	function _checkFirstAction() internal returns (bool)
	{
		marketHandlerDataStorageInterface _handlerDataStorage = handlerDataStorage;

		uint256 lastUpdatedBlock = _handlerDataStorage.getLastUpdatedBlock();
		uint256 currentBlockNumber = block.number;
		uint256 blockDelta = sub(currentBlockNumber, lastUpdatedBlock);

		if (blockDelta > 0)
		{
			_handlerDataStorage.setBlocks(currentBlockNumber, blockDelta);
			_handlerDataStorage.syncActionEXR();
			return true;
		}

		return false;
	}

	/**
	* @dev calculate (apply) interest (internal) and call storage update function
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _updateInterestAmount(address payable userAddr) internal returns (uint256, uint256)
	{
		bool depositNegativeFlag;
		uint256 deltaDepositAmount;
		uint256 globalDepositEXR;

		bool borrowNegativeFlag;
		uint256 deltaBorrowAmount;
		uint256 globalBorrowEXR;
      /* calculate interest amount and params by call Interest Model */
		(depositNegativeFlag, deltaDepositAmount, globalDepositEXR, borrowNegativeFlag, deltaBorrowAmount, globalBorrowEXR) = interestModelInstance.getInterestAmount(address(handlerDataStorage), userAddr, false);

		/* update new global EXR to user EXR*/
		handlerDataStorage.setEXR(userAddr, globalDepositEXR, globalBorrowEXR);

		/* call storage update function for update "latest" interest information  */
		return _setAmountReflectInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);
	}

	/**
	* @dev Apply the user's interest
	* @param userAddr The user address
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _setAmountReflectInterest(address payable userAddr, bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
      /* call _getAmountWithInterest for adding user storage amount and interest delta amount (deposit and borrow)*/
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _getAmountWithInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);

		/* update user amount in storage*/
		handlerDataStorage.setAmount(userAddr, depositTotalAmount, borrowTotalAmount, userDepositAmount, userBorrowAmount);

      /* update "spread between deposits and borrows" */
		_updateReservedAmount(depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);

		return (userDepositAmount, userBorrowAmount);
	}

	/**
	* @dev Get the "latest" user amount of deposit and borrow including interest (internal, view)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _getUserAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _calcAmountWithInterest(userAddr);

		return (userDepositAmount, userBorrowAmount);
	}

	/**
	* @dev Get the "latest" handler amount of deposit and borrow including interest (internal, view)
	* @param userAddr The user address
	* @return "latest" (depositTotalAmount, borrowTotalAmount)
	*/
	function _getTotalAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _calcAmountWithInterest(userAddr);

		return (depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev The deposit and borrow amount with interest for the user
	* @param userAddr The user address
	* @return "latest" (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount)
	*/
	function _calcAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256, uint256, uint256)
	{
		bool depositNegativeFlag;
		uint256 deltaDepositAmount;
		uint256 globalDepositEXR;

		bool borrowNegativeFlag;
		uint256 deltaBorrowAmount;
		uint256 globalBorrowEXR;
		(depositNegativeFlag, deltaDepositAmount, globalDepositEXR, borrowNegativeFlag, deltaBorrowAmount, globalBorrowEXR) = interestModelInstance.getInterestAmount(address(handlerDataStorage), userAddr, true);

		return _getAmountWithInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);
	}

	/**
	* @dev Calculate "latest" amount with interest for the block delta
	* @param userAddr The user address
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return "latest" (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount)
	*/
	function _getAmountWithInterest(address payable userAddr, bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal view returns (uint256, uint256, uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, borrowTotalAmount, userDepositAmount, userBorrowAmount) = handlerDataStorage.getAmount(userAddr);

		if (depositNegativeFlag)
		{
			depositTotalAmount = sub(depositTotalAmount, deltaDepositAmount);
			userDepositAmount = sub(userDepositAmount, deltaDepositAmount);
		}
		else
		{
			depositTotalAmount = add(depositTotalAmount, deltaDepositAmount);
			userDepositAmount = add(userDepositAmount, deltaDepositAmount);
		}

		if (borrowNegativeFlag)
		{
			borrowTotalAmount = sub(borrowTotalAmount, deltaBorrowAmount);
			userBorrowAmount = sub(userBorrowAmount, deltaBorrowAmount);
		}
		else
		{
			borrowTotalAmount = add(borrowTotalAmount, deltaBorrowAmount);
			userBorrowAmount = add(userBorrowAmount, deltaBorrowAmount);
		}

		return (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount);
	}

	/**
	* @dev Update the amount of the reserve
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return true (TODO: validate results)
	*/
	function _updateReservedAmount(bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal returns (bool)
	{
		int256 signedDeltaDepositAmount = int(deltaDepositAmount);
		int256 signedDeltaBorrowAmount = int(deltaBorrowAmount);
		if (depositNegativeFlag)
		{
			signedDeltaDepositAmount = signedDeltaDepositAmount * (-1);
		}

		if (borrowNegativeFlag)
		{
			signedDeltaBorrowAmount = signedDeltaBorrowAmount * (-1);
		}

      /* signedDeltaReservedAmount is singed amount */
		int256 signedDeltaReservedAmount = signedSub(signedDeltaBorrowAmount, signedDeltaDepositAmount);
		handlerDataStorage.updateSignedReservedAmount(signedDeltaReservedAmount);
		return true;
	}

	/**
	* @dev Sends the handler's assets to the given user
	* @param userAddr The address of user
	* @param unifiedTokenAmount The amount of token to send in unified token amount
	* @return true (TODO: validate results)
	*/
	function _transfer(address payable userAddr, uint256 unifiedTokenAmount) internal returns (bool)
	{
		uint256 beforeBalance = erc20Instance.balanceOf(userAddr);
		uint256 underlyingAmount = _convertUnifiedToUnderlying(unifiedTokenAmount);

		erc20Instance.transfer(userAddr, underlyingAmount);

		uint256 afterBalance = erc20Instance.balanceOf(userAddr);
		require(underlyingAmount == sub(afterBalance, beforeBalance), TRANSFER);

		return true;
	}

	/**
	* @dev Sends the assets from the user to the contract
	* @param userAddr The address of user
	* @param unifiedTokenAmount The amount of token to send in unified token amount
	* @return true (TODO: validate results)
	*/
	function _transferFrom(address payable userAddr, uint256 unifiedTokenAmount) internal returns (bool)
	{
		uint256 beforeBalance = erc20Instance.balanceOf(userAddr);
		uint256 underlyingAmount = _convertUnifiedToUnderlying(unifiedTokenAmount);

		erc20Instance.transferFrom(userAddr, address(this), underlyingAmount);

		uint256 afterBalance = erc20Instance.balanceOf(userAddr);
		require(underlyingAmount == sub(beforeBalance, afterBalance), TRANSFER);

		return true;
	}

	/**
	* @dev Convert amount of handler's unified decimals to amount of token's underlying decimals
	* @param unifiedTokenAmount The amount of unified decimals
	* @return (underlyingTokenAmount)
	*/
	function _convertUnifiedToUnderlying(uint256 unifiedTokenAmount) internal view returns (uint256)
	{
		return div(mul(unifiedTokenAmount, underlyingTokenDecimal), unifiedTokenDecimal);
	}

	/**
	* @dev Convert amount of token's underlying decimals to amount of handler's unified decimals
	* @param underlyingTokenAmount The amount of underlying decimals
	* @return (unifiedTokenAmount)
	*/
	function _convertUnderlyingToUnified(uint256 underlyingTokenAmount) internal view returns (uint256)
	{
		return div(mul(underlyingTokenAmount, unifiedTokenDecimal), underlyingTokenDecimal);
	}

	/**
	* @dev Get (total deposit - total borrow) of the handler
	* @return (total deposit - total borrow) of the handler
	*/
	function _getTokenLiquidityAmount() internal view returns (uint256)
	{
		marketHandlerDataStorageInterface _handlerDataStorage = handlerDataStorage;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _handlerDataStorage.getHandlerAmount();

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		if (depositTotalAmount < borrowTotalAmount)
		{
			return 0;
		}

		return sub(depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev Get (total deposit * liquidity limit - total borrow) of the handler
	* @return (total deposit * liquidity limit - total borrow) of the handler
	*/
	function _getTokenLiquidityLimitAmount() internal view returns (uint256)
	{
		marketHandlerDataStorageInterface _handlerDataStorage = handlerDataStorage;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _handlerDataStorage.getHandlerAmount();

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		uint256 liquidityDeposit = unifiedMul(depositTotalAmount, _handlerDataStorage.getLiquidityLimit());
		if (liquidityDeposit < borrowTotalAmount)
		{
			return 0;
		}

		return sub(liquidityDeposit, borrowTotalAmount);
	}

	/**
	* @dev Get (total deposit - total borrow) of the handler including interest
	* @param userAddr The user address(for wrapping function, unused)
	* @return (total deposit - total borrow) of the handler including interest
	*/
	function _getTokenLiquidityAmountWithInterest(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _getTotalAmountWithInterest(userAddr);

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		if (depositTotalAmount < borrowTotalAmount)
		{
			return 0;
		}

		return sub(depositTotalAmount, borrowTotalAmount);
	}
	/**
	* @dev Get (total deposit * liquidity limit - total borrow) of the handler including interest
	* @param userAddr The user address(for wrapping function, unused)
	* @return (total deposit * liquidity limit - total borrow) of the handler including interest
	*/
	function _getTokenLiquidityLimitAmountWithInterest(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _getTotalAmountWithInterest(userAddr);

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		uint256 liquidityDeposit = unifiedMul(depositTotalAmount, handlerDataStorage.getLiquidityLimit());

		if (liquidityDeposit < borrowTotalAmount)
		{
			return 0;
		}

		return sub(liquidityDeposit, borrowTotalAmount);
	}

	/**
	 * @dev Set the unifiedPoint of token's decimal
	 * @param _unifiedTokenDecimal the unifiedPoint of token's decimal
	 * @return true (TODO: validate results)
	 */
	function setUnifiedTokenDecimal(uint256 _unifiedTokenDecimal) onlyOwner external returns (bool)
	{
		unifiedTokenDecimal = _unifiedTokenDecimal;
		return true;
	}

	/**
	 * @dev Get the decimal of token
	 * @return (uint256, uint256) the decimal of token and the unifiedPoint of token's decimal
	 */
	function getTokenDecimals() external view returns (uint256, uint256)
	{
		return (underlyingTokenDecimal, unifiedTokenDecimal);
	}

	/**
	 * @dev Get the unifiedPoint of token's decimal (for fixed decimal number)
	 * @return the unifiedPoint of token's decimal
	 */
	/* default: UnifiedTokenDecimal Function */
	function getUnifiedTokenDecimal() external view returns (uint256)
	{
		return unifiedTokenDecimal;
	}

	/**
	 * @dev Get the decimal of the underlying token
	 * @return the decimal of the underlying token
	 */
	/* default: UnderlyingTokenDecimal Function */
	function getUnderlyingTokenDecimal() external view returns (uint256)
	{
		return underlyingTokenDecimal;
	}

	/**
	 * @dev Set the decimal of token
	 * @param _underlyingTokenDecimal the decimal of token
	 * @return true (TODO: validate results)
	 */
	function setUnderlyingTokenDecimal(uint256 _underlyingTokenDecimal) onlyOwner external returns (bool)
	{
		underlyingTokenDecimal = _underlyingTokenDecimal;
		return true;
	}

	/**
	* @dev Set the address of the marketManager contract
	* @param marketManagerAddr The address of the marketManager contract
	* @return true (TODO: validate results)
	*/
	function setMarketManager(address marketManagerAddr) onlyOwner public returns (bool)
	{
		marketManager = marketManagerInterface(marketManagerAddr);
		return true;
	}

	/**
	* @dev Set the address of the interestModel contract
	* @param interestModelAddr The address of the interestModel contract
	* @return true (TODO: validate results)
	*/
	function setInterestModel(address interestModelAddr) onlyOwner public returns (bool)
	{
		interestModelInstance = interestModelInterface(interestModelAddr);
		return true;
	}

	/**
	* @dev Set the address of the marketDataStorage contract
	* @param marketDataStorageAddr The address of the marketDataStorage contract
	* @return true (TODO: validate results)
	*/
	function setHandlerDataStorage(address marketDataStorageAddr) onlyOwner public returns (bool)
	{
		handlerDataStorage = marketHandlerDataStorageInterface(marketDataStorageAddr);
		return true;
	}

	/**
	 * @dev Set the address and name of the underlying ERC-20 token
	 * @param erc20Addr The address of ERC-20 token
	 * @param name The name of ERC-20 token
	 * @return true (TODO: validate results)
	 */
	function setErc20(address erc20Addr, string memory name) onlyOwner public returns (bool)
	{
		erc20Instance = IERC20(erc20Addr);
		tokenName = name;
		return true;
	}

	/**
	* @dev Set the address of the siHandlerDataStorage contract
	* @param SIHandlerDataStorageAddr The address of the siHandlerDataStorage contract
	* @return true (TODO: validate results)
	*/
	function setSiHandlerDataStorage(address SIHandlerDataStorageAddr) onlyOwner public returns (bool)
	{
		SIHandlerDataStorage = marketSIHandlerDataStorageInterface(SIHandlerDataStorageAddr);
		return true;
	}

	/**
	* @dev Get the address of the siHandlerDataStorage contract
	* @return The address of the siHandlerDataStorage contract
	*/
	function getSiHandlerDataStorage() public view returns (address)
	{
		return address(SIHandlerDataStorage);
	}

	/**
	* @dev Get the address of the marketManager contract
	* @return The address of the marketManager contract
	*/
	function getMarketManagerAddr() public view returns (address)
	{
		return address(marketManager);
	}

	/**
	* @dev Get the address of the interestModel contract
	* @return The address of the interestModel contract
	*/
	function getInterestModelAddr() public view returns (address)
	{
		return address(interestModelInstance);
	}

	/**
	* @dev Get the address of handler's dataStroage
	* @return the address of handler's dataStroage
	*/
	function getHandlerDataStorageAddr() public view returns (address)
	{
		return address(handlerDataStorage);
	}

	/**
	 * @dev Get the address of the underlying ERC-20 token
	 * @return The address of the underlying ERC-20 token
	 */
	function getErc20Addr() public view returns (address)
	{
		return address(erc20Instance);
	}

	/**
	* @dev Get the outgoing limit of tokens
	* @return The outgoing limit of tokens
	*/
	function getLimitOfAction() external view returns (uint256)
	{
		return handlerDataStorage.getLimitOfAction();
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
