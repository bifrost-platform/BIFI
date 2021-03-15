// SPDX-License-Identifier: BSD-3-Clause
import "../Errors.sol";

pragma solidity 0.6.12;

/**
 * @title BiFi's mockup Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract observerOracle is Modifier {
  address payable owner;
  mapping(address => bool) operators;

  int256 price;

	modifier onlyOwner {
		require(msg.sender == owner, "onlyOwner");
		_;
	}

	modifier onlyOperators {
		address sender = msg.sender;
		require(operators[sender] || sender == owner, "onlyOperators");
		_;
	}

	constructor (int256 _price) public
	{
		address payable sender = msg.sender;
		owner = sender;
		operators[sender] = true;
		price = _price;
	}

	function ownershipTransfer(address payable _owner) onlyOwner external returns (bool) {
		owner = _owner;
		return true;
	}

	function setOperator(address payable addr, bool flag) onlyOwner external returns (bool) {
		operators[addr] = flag;
		return flag;
	}
	function latestAnswer() external view returns (int256)
	{
		return price;
	}

	function setPrice(int256 _price) onlyOwner public
	{
	  price = _price;
	}
}
