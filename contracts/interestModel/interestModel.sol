// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../interfaces/interestModelInterface.sol";
import "../interfaces/marketHandlerDataStorageInterface.sol";
import "../SafeMath.sol";
import "../Errors.sol";

 /**
  * @title Bifi interestModel Contract
  * @notice Contract for interestModel
  * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract interestModel is interestModelInterface, InterestErrors {
	using SafeMath for uint256;

	address owner;
	mapping(address => bool) public operators;

	uint256 public blocksPerYear;
	uint256 constant unifiedPoint = 10 ** 18;

	uint256 minRate;
	uint256 basicSensitivity;

	/* jump rate model prams */
	uint256 jumpPoint;
	uint256 jumpSensitivity;

	uint256 spreadRate;

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

	modifier onlyOperator {
		address sender = msg.sender;
		require(operators[sender] || sender == owner, "Only Operators");
		_;
	}

	/**
	* @dev Construct a new interestModel contract
	* @param _minRate minimum interest rate
	* @param _jumpPoint Threshold of utilizationRate to which normal interest model
	* @param _basicSensitivity liquidity basicSensitivity
	* @param _jumpSensitivity The value used to calculate the BIR if the utilizationRate is greater than the jumpPoint.
	* @param _spreadRate spread rate
	*/
	constructor (uint256 _minRate, uint256 _jumpPoint, uint256 _basicSensitivity, uint256 _jumpSensitivity, uint256 _spreadRate) public
	{
		address sender = msg.sender;
		owner = sender;
		operators[owner] = true;

		minRate = _minRate;
		basicSensitivity = _basicSensitivity;

		jumpPoint = _jumpPoint;
		jumpSensitivity = _jumpSensitivity;

		spreadRate = _spreadRate;
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
	* @dev set Operator or not
	* @param _operator the address of the operator
	* @param flag operator permission
	* @return true (TODO: validate results)
	*/
	function setOperators(address payable _operator, bool flag) onlyOwner external returns (bool) {
		operators[_operator] = flag;
		return true;
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
	 * @param totalDepositAmount The amount of total deposit
	 * @param totalBorrowAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function getSIRandBIR(uint256 totalDepositAmount, uint256 totalBorrowAmount) external view override returns (uint256, uint256)
	{
		return _getSIRandBIR(totalDepositAmount, totalBorrowAmount);
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
		uint256 blockDelta = block.number.sub(handlerDataStorage.getLastUpdatedBlock());
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
		(interestUpdateModel.SIR, interestUpdateModel.BIR) = _getSIRandBIRonBlock(interestUpdateModel.depositTotalAmount, interestUpdateModel.borrowTotalAmount);
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

		return borrowTotalAmount.unifiedDiv(depositTotalAmount);
	}

	/**
	 * @dev Get SIR and BIR (internal)
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	// TODO: update comment(jump rate)
	{
		/* UtilRate = TotalBorrow / (TotalDeposit + TotalBorrow) */
		uint256 utilRate = _getUtilizationRate(depositTotalAmount, borrowTotalAmount);
		uint256 BIR;
		uint256 _jmpPoint = jumpPoint;
		/* BIR = minimumRate + (UtilRate * liquiditySensitivity) */
		if(utilRate < _jmpPoint) {
			BIR = utilRate.unifiedMul(basicSensitivity).add(minRate);
		} else {
      /*
      Formula : BIR = minRate + jumpPoint * basicSensitivity + (utilRate - jumpPoint) * jumpSensitivity

			uint256 _baseBIR = _jmpPoint.unifiedMul(basicSensitivity);
			uint256 _jumpBIR = utilRate.sub(_jmpPoint).unifiedMul(jumpSensitivity);
			BIR = minRate.add(_baseBIR).add(_jumpBIR);
      */
      BIR = minRate
      .add( _jmpPoint.unifiedMul(basicSensitivity) )
      .add( utilRate.sub(_jmpPoint).unifiedMul(jumpSensitivity) );
		}

		/* SIR = UtilRate * BIR */
		uint256 SIR = utilRate.unifiedMul(BIR).unifiedMul(spreadRate);
		return (SIR, BIR);
	}

	/**
	 * @dev Get SIR and BIR per block (internal)
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIRonBlock(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	{
		uint256 SIR;
		uint256 BIR;
		(SIR, BIR) = _getSIRandBIR(depositTotalAmount, borrowTotalAmount);
		return ( SIR.div(blocksPerYear), BIR.div(blocksPerYear) );
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
		return interestRate.mul(delta).add(unifiedPoint).unifiedMul(actionEXR);
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
			deltaAmount = unifiedAmount.unifiedMul(deltaEXR);
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
		uint256 EXR = newGlobalEXR.unifiedDiv(lastUserEXR);
		if (EXR >= unifiedPoint)
		{
			return ( false, EXR.sub(unifiedPoint) );
		}

		return ( true, unifiedPoint.sub(EXR) );
	}
	//TODO: Need comment
	function getMinRate() external view returns (uint256) {
		return minRate;
	}

	function setMinRate(uint256 _minRate) external onlyOperator returns (bool) {
		minRate = _minRate;
		return true;
	}

	function getBasicSensitivity() external view returns (uint256) {
		return basicSensitivity;
	}

	function setBasicSensitivity(uint256 _sensitivity) external onlyOperator returns (bool) {
		basicSensitivity = _sensitivity;
		return true;
	}

	function getJumpPoint() external view returns (uint256) {
		return jumpPoint;
	}

	function setJumpPoint(uint256 _jumpPoint) external onlyOperator returns (bool) {
		jumpPoint = _jumpPoint;
		return true;
	}

	function getJumpSensitivity() external view returns (uint256) {
		return jumpSensitivity;
	}

	function setJumpSensitivity(uint256 _sensitivity) external onlyOperator returns (bool) {
		jumpSensitivity = _sensitivity;
		return true;
	}

	function getSpreadRate() external view returns (uint256) {
		return spreadRate;
	}

	function setSpreadRate(uint256 _spreadRate) external onlyOperator returns (bool) {
		spreadRate = _spreadRate;
		return true;
	}
	function setBlocksPerYear(uint256 _blocksPerYear) external onlyOperator returns (bool) {
		blocksPerYear = _blocksPerYear;
		return true;
	}
}
