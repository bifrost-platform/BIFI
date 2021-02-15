import "../marketHandler/marketHandlerDataStorage/marketSIHandlerDataStorage.sol";

contract DaiSIDataStorage is marketSIHandlerDataStorage {
    constructor(address _SIHandlerAddr)
    marketSIHandlerDataStorage(_SIHandlerAddr) public {}
}