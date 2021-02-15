import "../oracle/oracle.sol";

contract UsdtOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}