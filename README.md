# BIFI

## Description

BiFi is a decentralized finance (DeFi) project that offers a financial service, which enables users to deposit various digital assets and borrow other digital assets against the deposits as collateral. BiFi consists of Solidity smart contracts, which operates on top of EVM-compatible blockchains.

Each supported digital asset on BiFi has a dedicated Market Handler Contract ("Market Handler"). All Market Handlers are intermediated by Market Manager Contract ("Market Manager").

Service Incentive Handler ("SI Handler") manages the reward program that rewards participants (service users and operators) that contributed in the growth and operation of BiFi with Service Incentive Tokens ("SI Tokens"). Liquidation Manager Contract ("Liquidation Manager") manages the liquidation process for users whose Loan-To-Value (LTV) Ratio has exceeded a set threshold.

The BiFi components interact with each other. For example, a user may borrow up to 75% of the value of previously deposited assets, and the value of any digital asset can be expressed as the product of its amount and current price. For this user (borrowing) operation, each Market Handler provides the user balance and the Oracle contract provides the current prices of each Token. Market Manager then validates and executes the action. The user also gets a service incentive for this action; The SI Handler will provide SI Tokens when the user claims. When a price of the user token significantly decreases, the user's debt can be liquidated by anyone via the Liquidation Manager contract.

The logic contracts (Market Handler, SI Handler and Market Manager) are designed so that they can be updated without changing the data storage. Each logic contract has its own data storage contracts to store the data.

## Overview
![alt text](https://github.com/bifrost-platform/BIFI/blob/master/assets/overview.png?raw=true)

### actions
+ Solidity CI

### contracts
+ Solidity contracts for BiFi

### migrations
+ Truffle script for testing

---

## Description

BiFi 서비스는 가상화폐를 예치하여 이자를 얻거나, 예치금을 담보로 가상화폐를 대출할 수 있는 DeFi 금융서비스이다. BiFi 서비스는 Solidity로 작성된 Smart Contract로 구성되어 있으며 EVM 호환 블록체인에서 동작한다.

BiFi가 지원하는 여러 가상화폐는 고유의 Market Handler Contract(Market Handler)를 가지고 있으며, 모든 Market Handler Contract는 Market Manager Contract(Market Manager)에 연결되어 Handler 간 연계 작업이 가능하다.

Service Incentive Handler(SI Handler)는 BiFi 서비스 유지에 공헌한 참여자에게 BiFi Token을 보상으로 지급하고, Liquidation Manager Contract(Liquidation Manager)는 총 예치 자산 대비 총 대출 자산의 비율(LTV, Loan-To-Value)이 정해진 수준을 넘긴 사용자의 자산을 청산하는 기능을 제공한다.

BiFi 의 컴포넌트는 각각의 기능이 서로 상호작용 한다. 예를 들어 사용자는 이전에 예치한 모든 가상화폐 가치의 75%만큼 대출을 실행할 수 있는데, Market Manager는 Oracle Contract에서 제공하는 각 가상화폐의 가격정보를 이용하여 사용자가 예치한 가상화폐 가치의 합계를 도출한다. 사용자의 요청("대출")이 발생하면, 각각의 Market Handler는 사용자의 잔액을 제공하고 Oracle 컨트랙트는 각 토큰의 가격을 제공한다.

한편, BiFi 서비스의 로직 Contract(Market Handler, SI Handler, Market Manager)들은 Data를 유지한 상태로 업데이트 할 수 있도록 설계 되어 있다. 로직 Contract들은 데이터를 저장하는 각각의 Data Storage Contract를 보유하며, Handler Proxy를 이용하여 효과적으로 로직 Contract는 교체될 수 있다.

## Overview
![alt text](https://github.com/bifrost-platform/BIFI/blob/master/assets/overview.png?raw=true)

### actions
+ Solidity CI

### contracts
+ BiFi를 구성하는 solidity로 짜여진 contracts

### migrations
+ Test용 truffle script
