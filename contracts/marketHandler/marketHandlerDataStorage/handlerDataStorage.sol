// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../../interfaces/marketHandlerDataStorageInterface.sol";
import "../../Errors.sol";

/**
 * @title BiFi's market handler data storage contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract marketHandlerDataStorage is marketHandlerDataStorageInterface, HandlerDataStorageModifier {
	address payable owner;

	bool emergency = false;

	address payable reservedAddr;

	int256 reservedAmount;

	address marketHandlerAddr;

	address interestModelAddr;

	uint256 lastUpdatedBlock;

	uint256 inactiveActionDelta;

	uint256 actionDepositEXR;

	uint256 actionBorrowEXR;

	uint256 public depositTotalAmount;

	uint256 public borrowTotalAmount;

	uint256 public globalDepositEXR;

	uint256 public globalBorrowEXR;

	mapping(address => IntraUser) intraUsers;

	MarketInterestModelParameters interestParams;

	uint256 constant unifiedPoint = 10 ** 18;

	uint256 public liquidityLimit = unifiedPoint;

	uint256 public limitOfAction = 100000 * unifiedPoint;

	struct MarketInterestModelParameters {
		uint256 borrowLimit;
		uint256 marginCallLimit;
		uint256 minimumInterestRate;
		uint256 liquiditySensitivity;
	}

	struct IntraUser {
		bool userAccessed;
		uint256 intraDepositAmount;
		uint256 intraBorrowAmount;
		uint256 userDepositEXR;
		uint256 userBorrowEXR;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyBifiContract {
		address msgSender = msg.sender;
		require(((msgSender == marketHandlerAddr) || (msgSender == interestModelAddr)) || (msgSender == owner), ONLY_BIFI_CONTRACT);
		_;
	}

	modifier circuitBreaker {
		address msgSender = msg.sender;
		require((!emergency) || (msgSender == owner), CIRCUIT_BREAKER);
		_;
	}

	constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity) public
	{
		owner = msg.sender;
		/* default reservedAddr */
		reservedAddr = owner;
		_initializeEXR();
		MarketInterestModelParameters memory _interestParams = interestParams;
		_interestParams.borrowLimit = _borrowLimit;
		_interestParams.marginCallLimit = _marginCallLimit;
		_interestParams.minimumInterestRate = _minimumInterestRate;
		_interestParams.liquiditySensitivity = _liquiditySensitivity;
		interestParams = _interestParams;
	}

	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	function getOwner() public view returns (address)
	{
		return owner;
	}

	function setCircuitBreaker(bool _emergency) onlyBifiContract external override returns (bool)
	{
		emergency = _emergency;
		return true;
	}

	function setNewCustomer(address payable userAddr) onlyBifiContract circuitBreaker external override returns (bool)
	{
		intraUsers[userAddr].userAccessed = true;
		intraUsers[userAddr].userDepositEXR = unifiedPoint;
		intraUsers[userAddr].userBorrowEXR = unifiedPoint;
		return true;
	}

	function setUserAccessed(address payable userAddr, bool _accessed) onlyBifiContract circuitBreaker external override returns (bool)
	{
		intraUsers[userAddr].userAccessed = _accessed;
		return true;
	}

	function getReservedAddr() external view override returns (address payable)
	{
		return reservedAddr;
	}

	function setReservedAddr(address payable reservedAddress) onlyOwner external override returns (bool)
	{
		reservedAddr = reservedAddress;
		return true;
	}

	function getReservedAmount() external view override returns (int256)
	{
		return reservedAmount;
	}

	function addReservedAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (int256)
	{
		reservedAmount = signedAdd(reservedAmount, int(amount));
		return reservedAmount;
	}

	function subReservedAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (int256)
	{
		reservedAmount = signedSub(reservedAmount, int(amount));
		return reservedAmount;
	}

	function updateSignedReservedAmount(int256 amount) onlyBifiContract circuitBreaker external override returns (int256)
	{
		reservedAmount = signedAdd(reservedAmount, amount);
		return reservedAmount;
	}

	function addDepositTotalAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		depositTotalAmount = add(depositTotalAmount, amount);
		return depositTotalAmount;
	}

	function subDepositTotalAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		depositTotalAmount = sub(depositTotalAmount, amount);
		return depositTotalAmount;
	}

	function addBorrowTotalAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		borrowTotalAmount = add(borrowTotalAmount, amount);
		return borrowTotalAmount;
	}

	function subBorrowTotalAmount(uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		borrowTotalAmount = sub(borrowTotalAmount, amount);
		return borrowTotalAmount;
	}

	function addUserIntraDepositAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		intraUsers[userAddr].intraDepositAmount = add(intraUsers[userAddr].intraDepositAmount, amount);
		return intraUsers[userAddr].intraDepositAmount;
	}

	function subUserIntraDepositAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		intraUsers[userAddr].intraDepositAmount = sub(intraUsers[userAddr].intraDepositAmount, amount);
		return intraUsers[userAddr].intraDepositAmount;
	}

	function addUserIntraBorrowAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		intraUsers[userAddr].intraBorrowAmount = add(intraUsers[userAddr].intraBorrowAmount, amount);
		return intraUsers[userAddr].intraBorrowAmount;
	}

	function subUserIntraBorrowAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		intraUsers[userAddr].intraBorrowAmount = sub(intraUsers[userAddr].intraBorrowAmount, amount);
		return intraUsers[userAddr].intraBorrowAmount;
	}

	function addDepositAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (bool)
	{
		depositTotalAmount = add(depositTotalAmount, amount);
		intraUsers[userAddr].intraDepositAmount = add(intraUsers[userAddr].intraDepositAmount, amount);
	}

	function addBorrowAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (bool)
	{
		borrowTotalAmount = add(borrowTotalAmount, amount);
		intraUsers[userAddr].intraBorrowAmount = add(intraUsers[userAddr].intraBorrowAmount, amount);
	}

	function subDepositAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (bool)
	{
		depositTotalAmount = sub(depositTotalAmount, amount);
		intraUsers[userAddr].intraDepositAmount = sub(intraUsers[userAddr].intraDepositAmount, amount);
	}

	function subBorrowAmount(address payable userAddr, uint256 amount) onlyBifiContract circuitBreaker external override returns (bool)
	{
		borrowTotalAmount = sub(borrowTotalAmount, amount);
		intraUsers[userAddr].intraBorrowAmount = sub(intraUsers[userAddr].intraBorrowAmount, amount);
	}

	function getUserAmount(address payable userAddr) external view override returns (uint256, uint256)
	{
		return (intraUsers[userAddr].intraDepositAmount, intraUsers[userAddr].intraBorrowAmount);
	}

	function getHandlerAmount() external view override returns (uint256, uint256)
	{
		return (depositTotalAmount, borrowTotalAmount);
	}

	function setAmount(address payable userAddr, uint256 _depositTotalAmount, uint256 _borrowTotalAmount, uint256 depositAmount, uint256 borrowAmount) onlyBifiContract circuitBreaker external override returns (uint256)
	{
		depositTotalAmount = _depositTotalAmount;
		borrowTotalAmount = _borrowTotalAmount;
		intraUsers[userAddr].intraDepositAmount = depositAmount;
		intraUsers[userAddr].intraBorrowAmount = borrowAmount;
	}

	function getAmount(address payable userAddr) external view override returns (uint256, uint256, uint256, uint256)
	{
		return (depositTotalAmount, borrowTotalAmount, intraUsers[userAddr].intraDepositAmount, intraUsers[userAddr].intraBorrowAmount);
	}

	function setBlocks(uint256 _lastUpdatedBlock, uint256 _inactiveActionDelta) onlyBifiContract circuitBreaker external override returns (bool)
	{
		lastUpdatedBlock = _lastUpdatedBlock;
		inactiveActionDelta = _inactiveActionDelta;
		return true;
	}

	function setLastUpdatedBlock(uint256 _lastUpdatedBlock) onlyBifiContract circuitBreaker external override returns (bool)
	{
		lastUpdatedBlock = _lastUpdatedBlock;
		return true;
	}

	function setInactiveActionDelta(uint256 _inactiveActionDelta) onlyBifiContract circuitBreaker external override returns (bool)
	{
		inactiveActionDelta = _inactiveActionDelta;
		return true;
	}

	function syncActionEXR() onlyBifiContract circuitBreaker external override returns (bool)
	{
		actionDepositEXR = globalDepositEXR;
		actionBorrowEXR = globalBorrowEXR;
		return true;
	}

	function getActionEXR() external view override returns (uint256, uint256)
	{
		return (actionDepositEXR, actionBorrowEXR);
	}

	function setActionEXR(uint256 _actionDepositEXR, uint256 _actionBorrowEXR) onlyBifiContract circuitBreaker external override returns (bool)
	{
		actionDepositEXR = _actionDepositEXR;
		actionBorrowEXR = _actionBorrowEXR;
		return true;
	}

	function setEXR(address payable userAddr, uint256 _globalDepositEXR, uint256 _globalBorrowEXR) onlyBifiContract circuitBreaker external override returns (bool)
	{
		globalDepositEXR = _globalDepositEXR;
		globalBorrowEXR = _globalBorrowEXR;
		intraUsers[userAddr].userDepositEXR = _globalDepositEXR;
		intraUsers[userAddr].userBorrowEXR = _globalBorrowEXR;
		return true;
	}

	function getUserEXR(address payable userAddr) external view override returns (uint256, uint256)
	{
		return (intraUsers[userAddr].userDepositEXR, intraUsers[userAddr].userBorrowEXR);
	}

	function setUserEXR(address payable userAddr, uint256 depositEXR, uint256 borrowEXR) onlyBifiContract circuitBreaker external override returns (bool)
	{
		intraUsers[userAddr].userDepositEXR = depositEXR;
		intraUsers[userAddr].userBorrowEXR = borrowEXR;
		return true;
	}

	function getGlobalEXR() external view override returns (uint256, uint256)
	{
		return (globalDepositEXR, globalBorrowEXR);
	}

	function setMarketHandlerAddr(address _marketHandlerAddr) onlyOwner external override returns (bool)
	{
		marketHandlerAddr = _marketHandlerAddr;
		return true;
	}

	function setInterestModelAddr(address _interestModelAddr) onlyOwner external override returns (bool)
	{
		interestModelAddr = _interestModelAddr;
		return true;
	}

	function setTokenHandler(address _marketHandlerAddr, address _interestModelAddr) onlyOwner external override returns (bool)
	{
		marketHandlerAddr = _marketHandlerAddr;
		interestModelAddr = _interestModelAddr;
		return true;
	}

	function setCoinHandler(address _marketHandlerAddr, address _interestModelAddr) onlyOwner external override returns (bool)
	{
		marketHandlerAddr = _marketHandlerAddr;
		interestModelAddr = _interestModelAddr;
		return true;
	}

	/* total Borrow Function */
	function getBorrowTotalAmount() external view override returns (uint256)
	{
		return borrowTotalAmount;
	}

	/* Global: lastUpdated function */
	function getLastUpdatedBlock() external view override returns (uint256)
	{
		return lastUpdatedBlock;
	}

	/* User Accessed Function */
	function getUserAccessed(address payable userAddr) external view override returns (bool)
	{
		return intraUsers[userAddr].userAccessed;
	}

	/* total Deposit Function */
	function getDepositTotalAmount() external view override returns (uint256)
	{
		return depositTotalAmount;
	}

	/* intra Borrow Function */
	function getUserIntraBorrowAmount(address payable userAddr) external view override returns (uint256)
	{
		return intraUsers[userAddr].intraBorrowAmount;
	}

	/* intra Deposit Function */
	function getUserIntraDepositAmount(address payable userAddr) external view override returns (uint256)
	{
		return intraUsers[userAddr].intraDepositAmount;
	}

	/* Global: inactiveActionDelta function */
	function getInactiveActionDelta() external view override returns (uint256)
	{
		return inactiveActionDelta;
	}

	/* Action: ExchangeRate Function */
	function getGlobalBorrowEXR() external view override returns (uint256)
	{
		return globalBorrowEXR;
	}

	/* Global: ExchangeRate Function */
	function getGlobalDepositEXR() external view override returns (uint256)
	{
		return globalDepositEXR;
	}

	function getMarketHandlerAddr() external view override returns (address)
	{
		return marketHandlerAddr;
	}

	function getInterestModelAddr() external view override returns (address)
	{
		return interestModelAddr;
	}

	function _initializeEXR() internal
	{
		uint256 currectBlockNumber = block.number;
		actionDepositEXR = unifiedPoint;
		actionBorrowEXR = unifiedPoint;
		globalDepositEXR = unifiedPoint;
		globalBorrowEXR = unifiedPoint;
		lastUpdatedBlock = currectBlockNumber - 1;
		inactiveActionDelta = lastUpdatedBlock;
	}

	function getLimit() external view override returns (uint256, uint256)
	{
		return (interestParams.borrowLimit, interestParams.marginCallLimit);
	}

	function getBorrowLimit() external view override returns (uint256)
	{
		return interestParams.borrowLimit;
	}

	function getMarginCallLimit() external view override returns (uint256)
	{
		return interestParams.marginCallLimit;
	}

	function getMinimumInterestRate() external view override returns (uint256)
	{
		return interestParams.minimumInterestRate;
	}

	function getLiquiditySensitivity() external view override returns (uint256)
	{
		return interestParams.liquiditySensitivity;
	}

	function setBorrowLimit(uint256 _borrowLimit) onlyOwner external override returns (bool)
	{
		interestParams.borrowLimit = _borrowLimit;
		return true;
	}

	function setMarginCallLimit(uint256 _marginCallLimit) onlyOwner external override returns (bool)
	{
		interestParams.marginCallLimit = _marginCallLimit;
		return true;
	}

	function setMinimumInterestRate(uint256 _minimumInterestRate) onlyOwner external override returns (bool)
	{
		interestParams.minimumInterestRate = _minimumInterestRate;
		return true;
	}

	function setLiquiditySensitivity(uint256 _liquiditySensitivity) onlyOwner external override returns (bool)
	{
		interestParams.liquiditySensitivity = _liquiditySensitivity;
		return true;
	}

	function getLiquidityLimit() external view override returns (uint256)
	{
		return liquidityLimit;
	}

	function setLiquidityLimit(uint256 _liquidityLimit) onlyOwner external override returns (bool)
	{
		liquidityLimit = _liquidityLimit;
		return true;
	}

	function getLimitOfAction() external view override returns (uint256)
	{
		return limitOfAction;
	}

	function setLimitOfAction(uint256 _limitOfAction) onlyOwner external override returns (bool)
	{
		limitOfAction = _limitOfAction;
		return true;
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
