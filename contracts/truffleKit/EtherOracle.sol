import "../oracle/oracle.sol";

contract EtherOracle is oracleSample {
    constructor(int256 _price)
    oracleSample(_price) public {}
}