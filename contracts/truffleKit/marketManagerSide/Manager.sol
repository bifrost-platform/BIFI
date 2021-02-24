// SPDX-License-Identifier: BSD-3-Clause

import "../../marketManager/tokenManager.sol";
pragma solidity 0.6.12;

contract Manager is etherManager {
    constructor (address managerDataStorageAddr, address oracleProxyAddr, address breaker, address erc20Addr)
    etherManager(managerDataStorageAddr, oracleProxyAddr, breaker, erc20Addr) public {}
}
