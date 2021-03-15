// SPDX-License-Identifier: BSD-3-Clause

import "../interestModel/interestModel.sol";
pragma solidity 0.6.12;

contract InterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}

contract CoinInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}

contract UsdtInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}

contract DaiInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}

contract LinkInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}

contract UsdcInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}
