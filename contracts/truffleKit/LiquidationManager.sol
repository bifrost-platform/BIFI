import "../marketManager/liquidationManager.sol";

contract LiquidationManager is etherLiquidationManager {
    constructor(address managerAddr)
    etherLiquidationManager(managerAddr) public {}
}