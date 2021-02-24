// SPDX-License-Identifier: BSD-3-Clause

import "../../reqCoinProxy.sol";
import "../../reqTokenProxy.sol";
pragma solidity 0.6.12;

contract CoinHandlerProxy is coinProxy {
    constructor()
    coinProxy() public {}
}

contract UsdtHandlerProxy is tokenProxy {
    constructor()
    tokenProxy() public {}
}

contract DaiHandlerProxy is tokenProxy {
    constructor()
    tokenProxy() public {}
}

contract LinkHandlerProxy is tokenProxy {
    constructor()
    tokenProxy() public {}
}

contract UsdcHandlerProxy is tokenProxy {
    constructor()
    tokenProxy() public {}
}

