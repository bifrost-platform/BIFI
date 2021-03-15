// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

/**
 * @title BiFi's oracle proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface oracleProxyInterfaceForManager  {
	function getTokenPrice(uint256 tokenID) external view returns (uint256);
}
