import "../marketHandler/marketHandlerDataStorage/marketSIHandlerDataStorage.sol";

contract LinkSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}