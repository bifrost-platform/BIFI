// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.12;

/**
 * @title BiFi's mockup Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract oracleSample  {
	int256 price;

	constructor (int256 _price) public
	{
		price = _price;
	}

	function latestAnswer() external view returns (int256)
	{
		return price;
	}

	function setPrice(int256 _price) public
	{
		price = _price;
	}
}
