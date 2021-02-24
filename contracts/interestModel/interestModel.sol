// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/interestModelInterface.sol";
import "../interfaces/marketHandlerDataStorageInterface.sol";
import "../Errors.sol";

 /**
  * @title Bifi interestModel Contract
  * @notice Contract for interestModel
  * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract interestModel is interestModelInterface, InterestErrors {
	address owner;

	uint256 constant blocksPerYear = 2102400;

	uint256 constant unifiedPoint = 10 ** 18;

	struct InterestUpdateModel {
		uint256 SIR;
		uint256 BIR;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 userDepositAmount;
		uint256 userBorrowAmount;
		uint256 deltaDepositAmount;
		uint256 deltaBorrowAmount;
		uint256 globalDepositEXR;
		uint256 globalBorrowEXR;
		uint256 userDepositEXR;
		uint256 userBorrowEXR;
		uint256 actionDepositEXR;
		uint256 actionBorrowEXR;
		uint256 deltaDepositEXR;
		uint256 deltaBorrowEXR;
		bool depositNegativeFlag;
		bool borrowNegativeFlag;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	/**
	* @dev Construct a new interestModel contract
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
	function ownershipTransfer(address payable _owner) onlyOwner external returns (bool)
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
	 * @dev Calculates interest amount for a user
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @param isView Select _view (before action) or _get (after action) function for calculation
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view override returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		if (isView)
		{
			return _viewInterestAmount(handlerDataStorageAddr, userAddr);
		}
		else
		{
			return _getInterestAmount(handlerDataStorageAddr, userAddr);
		}
	}

	/**
	 * @dev Calculates interest amount for a user (before user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view override returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		return _viewInterestAmount(handlerDataStorageAddr, userAddr);
	}

	/**
	 * @dev Get Supply Interest Rate (SIR) and Borrow Interest Rate (BIR) (external)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param totalDepositAmount The amount of total deposit
	 * @param totalBorrowAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function getSIRandBIR(address handlerDataStorageAddr, uint256 totalDepositAmount, uint256 totalBorrowAmount) external view override returns (uint256, uint256)
	{
		return _getSIRandBIR(handlerDataStorageAddr, totalDepositAmount, totalBorrowAmount);
	}

	/**
	 * @dev Calculates interest amount for a user (after user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _getInterestAmount(address handlerDataStorageAddr, address payable userAddr) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		uint256 delta = handlerDataStorage.getInactiveActionDelta();
		uint256 actionDepositEXR;
		uint256 actionBorrowEXR;
		(actionDepositEXR, actionBorrowEXR) = handlerDataStorage.getActionEXR();
		return _calcInterestAmount(handlerDataStorageAddr, userAddr, delta, actionDepositEXR, actionBorrowEXR);
	}

	/**
	 * @dev Calculates interest amount for a user (before user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		uint256 blockDelta = sub(block.number, handlerDataStorage.getLastUpdatedBlock());
		/* check action in block */
		uint256 globalDepositEXR;
		uint256 globalBorrowEXR;
		(globalDepositEXR, globalBorrowEXR) = handlerDataStorage.getGlobalEXR();
		return _calcInterestAmount(handlerDataStorageAddr, userAddr, blockDelta, globalDepositEXR, globalBorrowEXR);
	}

	/**
	 * @dev Calculate interest amount for a user with BIR and SIR (interal)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _calcInterestAmount(address handlerDataStorageAddr, address payable userAddr, uint256 delta, uint256 actionDepositEXR, uint256 actionBorrowEXR) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		InterestUpdateModel memory interestUpdateModel;
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		(interestUpdateModel.depositTotalAmount, interestUpdateModel.borrowTotalAmount, interestUpdateModel.userDepositAmount, interestUpdateModel.userBorrowAmount) = handlerDataStorage.getAmount(userAddr);
		(interestUpdateModel.SIR, interestUpdateModel.BIR) = _getSIRandBIRonBlock(handlerDataStorageAddr, interestUpdateModel.depositTotalAmount, interestUpdateModel.borrowTotalAmount);
		(interestUpdateModel.userDepositEXR, interestUpdateModel.userBorrowEXR) = handlerDataStorage.getUserEXR(userAddr);

		/* deposit start */
		interestUpdateModel.globalDepositEXR = _getNewGlobalEXR(actionDepositEXR, interestUpdateModel.SIR, delta);
		(interestUpdateModel.depositNegativeFlag, interestUpdateModel.deltaDepositAmount) = _getDeltaAmount(interestUpdateModel.userDepositAmount, interestUpdateModel.globalDepositEXR, interestUpdateModel.userDepositEXR);
		/* deposit done */

		/* borrow start */
		interestUpdateModel.globalBorrowEXR = _getNewGlobalEXR(actionBorrowEXR, interestUpdateModel.BIR, delta);
		(interestUpdateModel.borrowNegativeFlag, interestUpdateModel.deltaBorrowAmount) = _getDeltaAmount(interestUpdateModel.userBorrowAmount, interestUpdateModel.globalBorrowEXR, interestUpdateModel.userBorrowEXR);
		/* borrow done */

		return (interestUpdateModel.depositNegativeFlag, interestUpdateModel.deltaDepositAmount, interestUpdateModel.globalDepositEXR, interestUpdateModel.borrowNegativeFlag, interestUpdateModel.deltaBorrowAmount, interestUpdateModel.globalBorrowEXR);
	}

	/**
	 * @dev Calculates the utilization rate of market
	 * @param depositTotalAmount The total amount of deposit
	 * @param borrowTotalAmount The total amount of borrow
	 * @return The utilitization rate of market
	 */
	function _getUtilizationRate(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal pure returns (uint256)
	{
		if ((depositTotalAmount == 0) && (borrowTotalAmount == 0))
		{
			return 0;
		}

		return unifiedDiv(borrowTotalAmount, add(depositTotalAmount, borrowTotalAmount));
	}

	/**
	 * @dev Get SIR and BIR (internal)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIR(address handlerDataStorageAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	{
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		uint256 _minimumInterestRate = handlerDataStorage.getMinimumInterestRate();
		uint256 _liquiditySensitivity = handlerDataStorage.getLiquiditySensitivity();
		/* UtilRate = TotalBorrow / (TotalDeposit + TotalBorrow) */
		uint256 utilRate = _getUtilizationRate(depositTotalAmount, borrowTotalAmount);
		/* BIR = minimumRate + (UtilRate * liquiditySensitivity) */
		uint256 BIR = add(_minimumInterestRate, unifiedMul(utilRate, _liquiditySensitivity));
		/* SIR = UtilRate * BIR */
		uint256 SIR = unifiedMul(utilRate, BIR);
		return (SIR, BIR);
	}

	/**
	 * @dev Get SIR and BIR per block (internal)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIRonBlock(address handlerDataStorageAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	{
		uint256 SIR;
		uint256 BIR;
		(SIR, BIR) = _getSIRandBIR(handlerDataStorageAddr, depositTotalAmount, borrowTotalAmount);
		return (div(SIR, blocksPerYear), div(BIR, blocksPerYear));
	}

	/**
	 * @dev Calculates the rate of globalEXR (for borrowEXR or depositEXR)
	 * @param actionEXR The rate of actionEXR
	 * @param interestRate The rate of interest
	 * @param delta The interval between user actions (in block)
	 * @return The amount of newGlobalEXR
	 */
	function _getNewGlobalEXR(uint256 actionEXR, uint256 interestRate, uint256 delta) internal pure returns (uint256)
	{
		return unifiedMul(actionEXR, add(unifiedPoint, mul(interestRate, delta)));
	}

	/**
	 * @dev Calculates difference between globalEXR and userEXR
	 * @param unifiedAmount The unifiedAmount (for fixed decimal number)
	 * @param globalEXR The amount of globalEXR
	 * @param userEXR The amount of userEXR
	 * @return (bool, uint256)
	 */
	function _getDeltaAmount(uint256 unifiedAmount, uint256 globalEXR, uint256 userEXR) internal pure returns (bool, uint256)
	{
		uint256 deltaEXR;
		bool negativeFlag;
		uint256 deltaAmount;
		if (unifiedAmount != 0)
		{
			(negativeFlag, deltaEXR) = _getDeltaEXR(globalEXR, userEXR);
			deltaAmount = unifiedMul(unifiedAmount, deltaEXR);
		}

		return (negativeFlag, deltaAmount);
	}

	/**
	 * @dev Calculates the delta EXR between globalEXR and userEXR
	 * @param newGlobalEXR The new globalEXR
	 * @param lastUserEXR The last userEXR
	 * @return (bool, uint256)
	 */
	function _getDeltaEXR(uint256 newGlobalEXR, uint256 lastUserEXR) internal pure returns (bool, uint256)
	{
		uint256 EXR = unifiedDiv(newGlobalEXR, lastUserEXR);
		if (EXR >= unifiedPoint)
		{
			return (false, sub(EXR, unifiedPoint));
		}

		return (true, sub(unifiedPoint, EXR));
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
