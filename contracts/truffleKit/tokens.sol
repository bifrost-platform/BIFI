// SPDX-License-Identifier: BSD-3-Clause

import "../tokenStandard/openzeppelinERC20.sol";
pragma solidity 0.6.12;

// BiFi project
contract Bifi is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}

// HandlerSide
contract Usdt is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}

contract Dai is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}

contract Link is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}

contract Usdc is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}
