// SPDX-License-Identifier: BSD-3-Clause

import "../../marketHandler/marketHandlerDataStorage/handlerDataStorage.sol";
pragma solidity 0.6.12;

contract CoinHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}

contract DaiHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}

contract LinkHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}

contract UsdtHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}

contract UsdcHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}
