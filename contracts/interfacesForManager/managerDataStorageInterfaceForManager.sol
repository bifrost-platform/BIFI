// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

/**
 * @title BiFi's manager data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface managerDataStorageInterfaceForManager  {
	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address);

	function getRewardParamUpdated() external view returns (uint256);
	function setRewardParamUpdated(uint256 _rewardParamUpdated) external returns (bool);

	function getGlobalRewardPerBlock() external view returns (uint256);
	function getGlobalRewardDecrement() external view returns (uint256);
	function getGlobalRewardTotalAmount() external view returns (uint256);
	function getRewardParamUpdateRewardPerBlock() external view returns (uint256);

	function getTokenHandlerAddr(uint256 handlerID) external view returns (address);
	function getLiquidationManagerAddr() external view returns (address);

	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);
	function setLiquidationManagerAddr(address _liquidationManagerAddr) external returns (bool);

	function getInterestRewardUpdated() external view returns (uint256);
	function setInterestRewardUpdated(uint256 _interestRewardLastUpdated) external returns (bool);

	function getInterestUpdateRewardPerblock() external view returns (uint256);

	function getAlphaRate() external view returns (uint256);

	function getTokenHandlerID(uint256 index) external view returns (uint256);

	function getTokenHandlerExist(uint256 handlerID) external view returns (bool);
	function setTokenHandlerSupport(uint256 handlerID, bool support) external returns (bool);

	function setTokenHandler(uint256 handlerID, address handlerAddr) external returns (bool);

	function setGlobalRewardPerBlock(uint256 _globalRewardPerBlock) external returns (bool);
	function setGlobalRewardDecrement(uint256 _globalRewardDecrement) external returns (bool);
	function setGlobalRewardTotalAmount(uint256 _globalRewardTotalAmount) external returns (bool);

	/* unused in marketManager (for savig function signature)
	function setAlphaRate(uint256 _alphaRate) external returns (bool);

	function getAlphaLastUpdated() external view returns (uint256);
	function setAlphaLastUpdated(uint256 _alphaLastUpdated) external returns (bool);

	function setRewardParamUpdateRewardPerBlock(uint256 _rewardParamUpdateRewardPerBlock) external returns (bool);

	function setInterestUpdateRewardPerblock(uint256 _interestUpdateRewardPerblock) external returns (bool);

	function setTokenHandlerAddr(uint256 handlerID, address handlerAddr) external returns (bool);
	function setTokenHandlerExist(uint256 handlerID, bool exist) external returns (bool);

	function setManagerAddr(address _managerAddr) external returns (bool);
	*/
}
