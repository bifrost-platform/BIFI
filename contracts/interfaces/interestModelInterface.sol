// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

/**
 * @title BiFi's interest model interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface interestModelInterface {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
}
