// SPDX-License-Identifier: BSD-3-Clause

import "../../oracle/oracle.sol";
pragma solidity 0.6.12;

contract EtherOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}

contract DaiOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}

contract LinkOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}

contract UsdtOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}

contract UsdcOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}

