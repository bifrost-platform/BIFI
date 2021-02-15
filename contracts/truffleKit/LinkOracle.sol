import "../oracle/oracle.sol";

contract LinkOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}