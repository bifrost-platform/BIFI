import "../marketHandler/marketHandlerDataStorage/marketSIHandlerDataStorage.sol";

contract UsdtSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}