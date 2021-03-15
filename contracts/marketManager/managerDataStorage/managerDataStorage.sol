// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

import "../../interfaces/managerDataStorageInterface.sol";
import "../../Errors.sol";

/**
 * @title BiFi's manager data storage contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract managerDataStorage is managerDataStorageInterface, ManagerDataStorageErrors {
	address payable owner;

	address managerAddr;

	address liquidationManagerAddr;

	struct TokenHandler {
		address addr;
		bool support;
		bool exist;
	}

	uint256 globalRewardPerBlock;
	uint256 globalRewardDecrement;
	uint256 globalRewardTotalAmount;

	uint256 alphaRate;
	uint256 alphaLastUpdated;

	uint256 rewardParamUpdateRewardPerBlock;
	uint256 rewardParamUpdated;

	uint256 interestUpdateRewardPerblock;
	uint256 interestRewardLastUpdated;

	mapping(uint256 => TokenHandler) tokenHandlers;

	/* handler Array */
	uint256[] private tokenHandlerList;

	modifier onlyManager {
		address msgSender = msg.sender;
		require((msgSender == managerAddr) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	constructor () public
	{
		owner = msg.sender;
		uint256 this_block_number = block.number;

		globalRewardPerBlock = 0x478291c1a0e982c98;
		globalRewardDecrement = 0x7ba42eb3bfc;
		globalRewardTotalAmount = (4 * 100000000) * (10 ** 18);

		alphaRate = 2 * (10 ** 17);

		alphaLastUpdated = this_block_number;
		rewardParamUpdated = this_block_number;
		interestRewardLastUpdated = this_block_number;
	}

	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	function getGlobalRewardPerBlock() external view override returns (uint256)
	{
		return globalRewardPerBlock;
	}

	function setGlobalRewardPerBlock(uint256 _globalRewardPerBlock) onlyManager external override returns (bool)
	{
		globalRewardPerBlock = _globalRewardPerBlock;
		return true;
	}

	function getGlobalRewardDecrement() external view override returns (uint256)
	{
		return globalRewardDecrement;
	}

	function setGlobalRewardDecrement(uint256 _globalRewardDecrement) onlyManager external override returns (bool)
	{
		globalRewardDecrement = _globalRewardDecrement;
		return true;
	}

	function getGlobalRewardTotalAmount() external view override returns (uint256)
	{
		return globalRewardTotalAmount;
	}

	function setGlobalRewardTotalAmount(uint256 _globalRewardTotalAmount) onlyManager external override returns (bool)
	{
		globalRewardTotalAmount = _globalRewardTotalAmount;
		return true;
	}

	function getAlphaRate() external view override returns (uint256)
	{
		return alphaRate;
	}

	function setAlphaRate(uint256 _alphaRate) onlyOwner external override returns (bool)
	{
		alphaRate = _alphaRate;
		return true;
	}

	function getAlphaLastUpdated() external view override returns (uint256)
	{
		return alphaLastUpdated;
	}

	function setAlphaLastUpdated(uint256 _alphaLastUpdated) onlyOwner external override returns (bool)
	{
		alphaLastUpdated = _alphaLastUpdated;
		return true;
	}

	function getRewardParamUpdateRewardPerBlock() external view override returns (uint256)
	{
		return rewardParamUpdateRewardPerBlock;
	}

	function setRewardParamUpdateRewardPerBlock(uint256 _rewardParamUpdateRewardPerBlock) onlyOwner external override returns (bool)
	{
		rewardParamUpdateRewardPerBlock = _rewardParamUpdateRewardPerBlock;
		return true;
	}

	function getRewardParamUpdated() external view override returns (uint256)
	{
		return rewardParamUpdated;
	}

	function setRewardParamUpdated(uint256 _rewardParamUpdated) onlyManager external override returns (bool)
	{
		rewardParamUpdated = _rewardParamUpdated;
		return true;
	}

	function getInterestUpdateRewardPerblock() external view override returns (uint256)
	{
		return interestUpdateRewardPerblock;
	}

	function setInterestUpdateRewardPerblock(uint256 _interestUpdateRewardPerblock) onlyOwner external override returns (bool)
	{
		interestUpdateRewardPerblock = _interestUpdateRewardPerblock;
		return true;
	}

	function getInterestRewardUpdated() external view override returns (uint256)
	{
		return interestRewardLastUpdated;
	}

	function setInterestRewardUpdated(uint256 _interestRewardLastUpdated) onlyManager external override returns (bool)
	{
		interestRewardLastUpdated = _interestRewardLastUpdated;
		return true;
	}

	function setManagerAddr(address _managerAddr) onlyOwner external override returns (bool)
	{
		_setManagerAddr(_managerAddr);
		return true;
	}

	function _setManagerAddr(address _managerAddr) internal returns (bool)
	{
		require(_managerAddr != address(0), NULL_ADDRESS);
		managerAddr = _managerAddr;
		return true;
	}

	function setLiquidationManagerAddr(address _liquidationManagerAddr) onlyManager external override returns (bool)
	{
		liquidationManagerAddr = _liquidationManagerAddr;
		return true;
	}

	function getLiquidationManagerAddr() external view override returns (address)
	{
		return liquidationManagerAddr;
	}

	function setTokenHandler(uint256 handlerID, address handlerAddr) onlyManager external override returns (bool)
	{
		TokenHandler memory handler;
		handler.addr = handlerAddr;
		handler.exist = true;
		handler.support = true;
		/* regist Storage*/
		tokenHandlers[handlerID] = handler;
		tokenHandlerList.push(handlerID);
	}

	function setTokenHandlerAddr(uint256 handlerID, address handlerAddr) onlyOwner external override returns (bool)
	{
		tokenHandlers[handlerID].addr = handlerAddr;
		return true;
	}

	function setTokenHandlerExist(uint256 handlerID, bool exist) onlyOwner external override returns (bool)
	{
		tokenHandlers[handlerID].exist = exist;
		return true;
	}

	function setTokenHandlerSupport(uint256 handlerID, bool support) onlyManager external override returns (bool)
	{
		tokenHandlers[handlerID].support = support;
		return true;
	}

	function getTokenHandlerInfo(uint256 handlerID) external view override returns (bool, address)
	{
		return (tokenHandlers[handlerID].support, tokenHandlers[handlerID].addr);
	}

	function getTokenHandlerAddr(uint256 handlerID) external view override returns (address)
	{
		return tokenHandlers[handlerID].addr;
	}

	function getTokenHandlerExist(uint256 handlerID) external view override returns (bool)
	{
		return tokenHandlers[handlerID].exist;
	}

	function getTokenHandlerSupport(uint256 handlerID) external view override returns (bool)
	{
		return tokenHandlers[handlerID].support;
	}

	function getTokenHandlerID(uint256 index) external view override returns (uint256)
	{
		return tokenHandlerList[index];
	}

	function getOwner() public view returns (address)
	{
		return owner;
	}
}
