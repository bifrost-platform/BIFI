import "../tokenStandard/token.sol";

contract Usdt is openzeppelinERC20 {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    openzeppelinERC20(_name, _symbol, _decimals) public {}
}
