// SPDX-License-Identifier: BSD-3-Clause

import "../../oracle/oracle.sol";
pragma solidity 0.6.12;

contract EtherOracle is observerOracle {
    constructor(int256 _price)
    observerOracle(_price) public {}
}

contract DaiOracle is observerOracle {
    constructor(int256 _price)
    observerOracle(_price) public {}
}

contract LinkOracle is observerOracle {
    constructor(int256 _price)
    observerOracle(_price) public {}
}

contract UsdtOracle is observerOracle {
    constructor(int256 _price)
    observerOracle(_price) public {}
}

contract UsdcOracle is observerOracle {
    constructor(int256 _price)
    observerOracle(_price) public {}
}

