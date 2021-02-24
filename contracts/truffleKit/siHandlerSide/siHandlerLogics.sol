// SPDX-License-Identifier: BSD-3-Clause

import "../../marketHandler/tokenSI.sol";
import "../../marketHandler/coinSI.sol";
pragma solidity 0.6.12;

contract CoinSI is coinSI {
  constructor()
  coinSI() public {}
}

contract UsdtSI is tokenSI {
    constructor()
    tokenSI() public {}
}

contract DaiSI is tokenSI {
    constructor()
    tokenSI() public {}
}

contract LinkSI is tokenSI {
    constructor()
    tokenSI() public {}
}

contract UsdcSI is tokenSI {
    constructor()
    tokenSI() public {}
}
