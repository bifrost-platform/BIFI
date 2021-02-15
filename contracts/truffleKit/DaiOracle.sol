import "../oracle/oracle.sol";

contract DaiOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}