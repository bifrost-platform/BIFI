// SPDX-License-Identifier: BSD-3-Clause

import "../../marketHandler/marketHandlerDataStorage/marketSIHandlerDataStorage.sol";
pragma solidity 0.6.12;

contract CoinSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}

contract UsdtSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}

contract DaiSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}

contract LinkSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}

contract UsdcSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}

