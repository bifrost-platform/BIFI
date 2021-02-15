import "../marketHandler/marketHandlerDataStorage/handlerDataStorage.sol";

contract DaiHandlerDataStorage is marketHandlerDataStorage {
    constructor (uint256 _borrowLimit, uint256 _marginCallLimit, uint256 _minimumInterestRate, uint256 _liquiditySensitivity)
    marketHandlerDataStorage(_borrowLimit, _marginCallLimit, _minimumInterestRate, _liquiditySensitivity) public {}
}