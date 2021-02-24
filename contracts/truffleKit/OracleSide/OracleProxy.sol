// SPDX-License-Identifier: BSD-3-Clause

import "../../oracle/oracleProxy.sol";
pragma solidity 0.6.12;

contract OracleProxy is oracleProxy {
    constructor (address coinOracle, address usdtOracle, address daiOracle, address linkOracle, address usdcOracle)
    oracleProxy(coinOracle, usdtOracle, daiOracle, linkOracle, usdcOracle) public {}
}

