import "../oracle/oracleProxy.sol";

contract OracleProxy is oracleProxy {
    constructor (address coinOracle, address usdtOracle, address daiOracle, address linkOracle)
    oracleProxy(coinOracle, usdtOracle, daiOracle, linkOracle) public {}
}