let InterestModel = artifacts.require("InterestModel");
let CoinHandlerDataStorage = artifacts.require("CoinHandlerDataStorage");
let UsdtHandlerDataStorage = artifacts.require("UsdtHandlerDataStorage");
let DaiHandlerDataStorage = artifacts.require("DaiHandlerDataStorage");
let LinkHandlerDataStorage = artifacts.require("LinkHandlerDataStorage");
let Dai = artifacts.require("Dai");
let Link = artifacts.require("Link");
let Usdt = artifacts.require("Usdt");
let Bifi = artifacts.require("Bifi");
let ManagerDataStorage = artifacts.require("ManagerDataStorage");
let Manager = artifacts.require("etherManager");
let LiquidationManager = artifacts.require("LiquidationManager");
let CoinHandlerLogic = artifacts.require("CoinHandlerLogic");
let UsdtHandlerLogic = artifacts.require("UsdtHandlerLogic");
let DaiHandlerLogic = artifacts.require("DaiHandlerLogic");
let LinkHandlerLogic = artifacts.require("LinkHandlerLogic");
let OracleProxy = artifacts.require("OracleProxy");
let EtherOracle = artifacts.require("EtherOracle");
let UsdtOracle = artifacts.require("UsdtOracle");
let DaiOracle = artifacts.require("DaiOracle");
let LinkOracle = artifacts.require("LinkOracle");
let CoinHandlerProxy = artifacts.require("CoinHandlerProxy");
let UsdtHandlerProxy = artifacts.require("UsdtHandlerProxy");
let DaiHandlerProxy = artifacts.require("DaiHandlerProxy");
let LinkHandlerProxy = artifacts.require("LinkHandlerProxy");
let CoinSIHandlerDataStorage = artifacts.require("marketSIHandlerDataStorage");
let UsdtSIDataStorage = artifacts.require("UsdtSIDataStorage");
let DaiSIDataStorage = artifacts.require("DaiSIDataStorage");
let LinkSIDataStorage = artifacts.require("LinkSIDataStorage");
let coinSI = artifacts.require("coinSI");
let usdtSI = artifacts.require("UsdtSI");
let daiSI = artifacts.require("DaiSI");
let linkSI = artifacts.require("LinkSI");
let callProxy = artifacts.require("callProxyManagerCallProxyHandlerCallProxyMarketCallProxyUserCallProxySISafeMath");
let fs = require('fs');


module.exports = async function (deployer) {

  let receipt;
  let instances = {};

  // Oracle
  // TODO: something problem, first deploy not assing into instances DICT
  // instances["trash"] = await deployer.deploy(EtherOracle, (100000000).toString());
  instances["EtherOracle"] = await deployer.deploy(EtherOracle, (100000000).toString());
  instances["EtherOracle"] = EtherOracle;
  instances["UsdtOracle"] = await deployer.deploy(UsdtOracle, (1000000000000000000).toString());
  instances["DaiOracle"] = await deployer.deploy(DaiOracle, (100000000).toString());
  instances["LinkOracle"] = await deployer.deploy(LinkOracle, (100000000).toString());
  instances["OracleProxy"] = await deployer.deploy(OracleProxy, EtherOracle.address, UsdtOracle.address, DaiOracle.address, LinkOracle.address);

  // SI
  instances["coinSI"] = await deployer.deploy(coinSI);
  instances["usdtSI"] = await deployer.deploy(usdtSI);
  instances["daiSI"] = await deployer.deploy(daiSI);
  instances["linkSI"] = await deployer.deploy(linkSI);

  // ERC20
  instances["Dai"] = await deployer.deploy(Dai, "dai", "DAI", 18);
  instances["Link"] = await deployer.deploy(Link, "link", "LINK", 18);
  instances["Usdt"] = await deployer.deploy(Usdt, "usdt", "USDT", 6);
  instances["Bifi"] = await deployer.deploy(Bifi, "bifi", "BIFI", 18);

  // Manager
  instances["ManagerDataStorage"] = await deployer.deploy(ManagerDataStorage);
  instances["Manager"] = await deployer.deploy(Manager, "ether", ManagerDataStorage.address, OracleProxy.address, "0x6d3A0d57Aa65fe133802c48F659521F7693fa477", Bifi.address)
  receipt = await instances["ManagerDataStorage"].setManagerAddr(Manager.address);

  let transferAmount = web3.utils.toWei('1000000000', 'ether');
  receipt = await instances["Bifi"].transfer(Manager.address, transferAmount);

  instances["LiquidationManager"] = await deployer.deploy(LiquidationManager, Manager.address);
  receipt = await instances["Manager"].setLiquidationManager(LiquidationManager.address);


  // MarketHandlerDataStorage
  let betaRate = await web3.utils.toWei('0.5', 'ether');
  let borrowLimit = await web3.utils.toWei('0.8', 'ether');
  let martinCallLimit = await web3.utils.toWei('0.93', 'ether');
  let minimumInterestRate = await web3.utils.toWei('0.02', 'ether');
  let liquiditySensitive = await web3.utils.toWei('0.1', 'ether');
  instances["CoinHandlerDataStorage"] = await deployer.deploy(CoinHandlerDataStorage, borrowLimit, martinCallLimit, minimumInterestRate, liquiditySensitive);

  borrowLimit = await web3.utils.toWei('0.5', 'ether');
  minimumInterestRate = 0;
  liquiditySensitive = await web3.utils.toWei('0.04', 'ether');
  instances["UsdtHandlerDataStorage"] = await deployer.deploy(UsdtHandlerDataStorage, borrowLimit, martinCallLimit, minimumInterestRate, liquiditySensitive);

  borrowLimit = await web3.utils.toWei('0.75', 'ether');
  minimumInterestRate = 0;
  liquiditySensitive = await web3.utils.toWei('0.05', 'ether');
  instances["DaiHandlerDataStorage"] = await deployer.deploy(DaiHandlerDataStorage, borrowLimit, martinCallLimit, minimumInterestRate, liquiditySensitive);

  borrowLimit = await web3.utils.toWei('0.6', 'ether');
  martinCallLimit = await web3.utils.toWei('0.90', 'ether');
  minimumInterestRate = await web3.utils.toWei('0.02', 'ether');
  liquiditySensitive = await web3.utils.toWei('0.1', 'ether');
  instances["LinkHandlerDataStorage"] = await deployer.deploy(LinkHandlerDataStorage, borrowLimit, martinCallLimit, minimumInterestRate, liquiditySensitive);

  // interestModel
  instances["InterestModel"] = await deployer.deploy(InterestModel);

  // handlerProxy
  instances["CoinHandlerProxy"] = await deployer.deploy(CoinHandlerProxy);
  instances["UsdtHandlerProxy"] = await deployer.deploy(UsdtHandlerProxy);
  instances["DaiHandlerProxy"] = await deployer.deploy(DaiHandlerProxy);
  instances["LinkHandlerProxy"] = await deployer.deploy(LinkHandlerProxy);

  // SI DataStorage
  instances["CoinSIHandlerDataStorage"] = await deployer.deploy(CoinSIHandlerDataStorage, CoinHandlerProxy.address);
  instances["LinkSIDataStorage"] = await deployer.deploy(LinkSIDataStorage, LinkHandlerProxy.address);
  instances["DaiSIDataStorage"] = await deployer.deploy(DaiSIDataStorage, DaiHandlerProxy.address);
  instances["UsdtSIDataStorage"] = await deployer.deploy(UsdtSIDataStorage, UsdtHandlerProxy.address);

  let marginCallLimit = (930000000000000000).toString();
  let limitOfActionAmount = web3.utils.toWei('100000', 'ether');
  let liquidityLimitAmount = web3.utils.toWei('1', 'ether');

  // COIN Handler
  instances["CoinHandlerLogic"] = await deployer.deploy(CoinHandlerLogic);
  let coinBorrowLimit = web3.utils.toWei('0.8', 'ether');
  receipt = await instances["Manager"].handlerRegister(0, CoinHandlerProxy.address);
  receipt = await instances["CoinHandlerDataStorage"].setCoinHandler(CoinHandlerProxy.address, InterestModel.address);
  receipt = await instances["CoinHandlerProxy"].initialize(0, CoinHandlerLogic.address, Manager.address, InterestModel.address, CoinHandlerDataStorage.address, coinSI.address, CoinSIHandlerDataStorage.address);
  receipt = await instances["CoinHandlerDataStorage"].setLimitOfAction(limitOfActionAmount);
  receipt = await instances["CoinHandlerDataStorage"].setLiquidityLimit(liquidityLimitAmount);


  // USDT Handler
  instances["UsdtHandlerLogic"] = await deployer.deploy(UsdtHandlerLogic);
  let usdtBorrowLimit = web3.utils.toWei('0.5', 'ether');
  receipt = await instances["Manager"].handlerRegister(1, UsdtHandlerProxy.address);
  receipt = await instances["UsdtHandlerDataStorage"].setTokenHandler(UsdtHandlerProxy.address, InterestModel.address);
  receipt = await instances["UsdtHandlerProxy"].initialize(1, UsdtHandlerLogic.address, Manager.address, InterestModel.address, UsdtHandlerDataStorage.address, Usdt.address, "usdt", usdtSI.address, UsdtSIDataStorage.address);
  receipt = await instances["UsdtHandlerDataStorage"].setLimitOfAction(limitOfActionAmount);
  receipt = await instances["UsdtHandlerDataStorage"].setLiquidityLimit(liquidityLimitAmount);

  let callBytes = await web3.eth.abi.encodeFunctionCall({
    name: 'setUnderlyingTokenDecimal',
    type: 'function',
    inputs: [{
        type: 'uint256',
        name: '_underlyingTokenDecimal'
    }]
  }, [(10 ** 6).toString()]);

  receipt = await instances["UsdtHandlerProxy"].handlerViewProxy(callBytes);

  // DAI Handler
  instances["DaiHandlerLogic"] = await deployer.deploy(DaiHandlerLogic);
  let daiBorrowLimit = web3.utils.toWei('0.75', 'ether');
  receipt = await instances["Manager"].handlerRegister(2, DaiHandlerProxy.address);
  receipt = await instances["DaiHandlerDataStorage"].setTokenHandler(DaiHandlerProxy.address, InterestModel.address);
  receipt = await instances["DaiHandlerProxy"].initialize(2, DaiHandlerLogic.address, Manager.address, InterestModel.address, DaiHandlerDataStorage.address, Dai.address, "dai", daiSI.address, DaiSIDataStorage.address);
  receipt = await instances["DaiHandlerDataStorage"].setLimitOfAction(limitOfActionAmount);
  receipt = await instances["DaiHandlerDataStorage"].setLiquidityLimit(liquidityLimitAmount);

  callBytes = await web3.eth.abi.encodeFunctionCall({
    name: 'setUnderlyingTokenDecimal',
    type: 'function',
    inputs: [{
        type: 'uint256',
        name: '_underlyingTokenDecimal'
    }]
  }, [(10 ** 18).toString()]);

  receipt = await instances["DaiHandlerProxy"].handlerViewProxy(callBytes);

  // LINK Handler
  instances["LinkHandlerLogic"] = await deployer.deploy(LinkHandlerLogic);
  let linkBorrowLimit = web3.utils.toWei('0.6', 'ether');
  receipt = await instances["Manager"].handlerRegister(3, LinkHandlerProxy.address);
  receipt = await instances["LinkHandlerDataStorage"].setTokenHandler(LinkHandlerProxy.address, InterestModel.address);
  receipt = await instances["LinkHandlerProxy"].initialize(3, LinkHandlerLogic.address, Manager.address, InterestModel.address, LinkHandlerDataStorage.address, Link.address, "link", linkSI.address, LinkSIDataStorage.address);
  receipt = await instances["LinkHandlerDataStorage"].setLimitOfAction(limitOfActionAmount);
  receipt = await instances["LinkHandlerDataStorage"].setLiquidityLimit(liquidityLimitAmount);

  callBytes = await web3.eth.abi.encodeFunctionCall({
    name: 'setUnderlyingTokenDecimal',
    type: 'function',
    inputs: [{
        type: 'uint256',
        name: '_underlyingTokenDecimal'
    }]
  }, [(10 ** 18).toString()]);

  receipt = await instances["LinkHandlerProxy"].handlerViewProxy(callBytes);

  // CallProxy
  instances["callProxy"] = await deployer.deploy(callProxy, Manager.address);

  let output = {};

  for(let key in instances) {
    if(instances[key] == undefined) console.log(key);
    else output[key] = instances[key].address;
  }

  let json = JSON.stringify(output);
  fs.writeFileSync('accounts.json', json);
};