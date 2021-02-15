# Market Handler
## Description
Support the functions of the ERC-20 tokens and native coins.
A Market Handler has a DataStorage contract to store user and market data; use the InterestModel contract in calculating interest of users.

### Variable
#### Global Variable
| Variable | Meaning | Unique Key | Only Token |
|---|---|---|---|
| `owner` | owner of the handler  |
| `handlerID` | handler ID |O|
| `tokenName` | token name of the handler |O|
| `unifiedPoint` | unified decimal point for the fixed-number calculation | |
| `underlyingTokenDecimal` | decimal point of the underlying token ||O|
| `marketManager` | Market Manager instance  |
| `interestModelInstance` | InterestModel instance  |
| `handlerDataStorage` | Data Storage instance |
| `SIHandlerDataStorage`| Data Storage of the SI Handler |
| `erc20Instance`| address of the underlying ERC-20 token ||O|

## Action
### User Action
<pre>
1. DEPOSIT
  Deposit tokens to BiFi

2. WITHDRAW
  Withdraw tokens from BiFi

3. BORROW
  Borrow tokens by using the deposit as a collateral

4. REPAY
  Repay the borrowed tokens.

</pre>
### System Action
<pre>
1. _applyInterest
  It calculates interest by using the connected InterestModel and update the balances of users and the market. It is executed for every user action.

2. reserveDeposit and reserveWithdraw
  Deposit and withdraw the reserve amount of the Market Manager

3. partialLiquidationUser
  Check the eligibility of the liquidation and liquidate the borrow of the liquidation target.

4. partialLiquidationUserReward
  After `partialLiquidationUser` has finished, give the liquidation reward to the liquidator.
</pre>
# SI (Service Incentive)
## Description
Handles the logic of the BiFi service incentives. BiFi incentivizes every user action.

### Variable
#### Global Variable
| Variable | Meaning | Unique Key | Only Token |
|---|---|---|---|
| `owner` | owner of the handler |
| `handlerID` | handler ID |O|
| `tokenName` | token name of the handler |O|
| `unifiedPoint` |unified decimal point for the fixed-number calculation| |
| `underlyingTokenDecimal` |decimal point of the underlying token||O|
| `marketManager` | Market Manager instance  |
| `interestModelInstance` | InterestModel instance |
| `handlerDataStorage` | Data Storage instance |
| `SIHandlerDataStorage`| Data Storage of the SI Handle |
| `erc20Instance`| address of the underlying ERC-20 token ||O|

## Action
<pre>
1. updateRewardLane
  Update the market reward lane and the user reward lane (executed for every action).
</pre>

---

## Description
Bifi에서 지원하고자하는 Coin 과 Token을 추상화하여 지원합니다.
DataStorage의 별도 contract에 사용자와 시장 전체에 대한 코인/토큰 정보를 저장하고, InterestModel을 통해서 이자를 계산합니다.

### Variable
#### Global Variable
| 변수명 | 의미 | Unique Key | Only Token |
|---|---|---|---|
| `owner` | Handler의 Owner |
| `handlerID` | Handler마다 부여되는 값|O|
| `tokenName` | Handler가 처리하는 token의 이름|O|
| `unifiedPoint` |Bifi 내에서 통일화 되는 Decimal| |
| `underlyingTokenDecimal` |Wrapping 된 token이 가지고 있는 실제 Decimal||O|
| `marketManager` | Handler와 mapping 된 Token Manager instance |
| `interestModelInstance` | Handler와 mapping 된 Interest Model |
| `handlerDataStorage` | Handler와 mapping 된 Data Storage |
| `SIHandlerDataStorage`| SI Handler의 Datastorage (variable align을 위함)|
| `erc20Instance`|Handler가 Wrapping한 Token Contract의 주소||O|

## Action
### User Action
<pre>
1. DEPOSIT
  Bifi에 토큰을 예금하는 행위

2. WITHDRAW
  Bifi에 예금 된 토큰을 출금하는 행위

3. BORROW
  Bifi에 예금 된 토큰을 담보로 대출하는 행위

4. REPAY
  Bifi에 대출한 토큰을 갚는 행위
</pre>
### System Action
<pre>
1. _applyInterest
  User Action이 발생 할 때 마다 실행되며 이는 Handler와 mapping된
  Interest Model을 통해 이자를 계산하고 사용자의 Deposit, Borrow의 양,
  시장의 Total Deposit, Borrow를 변화시킵니다.

2. reserveDeposit and reserveWithdraw
  Market Handler에 reserve 물량을 예금하거나 출금합니다.

3. partialLiquidationUser
  청산 대상자에 대해서 부분적인 청산을 진행합니다. 진행하는 도중
  청산 실행자에 대해 실행자가 될 수 있는가에 대한 검증도 이뤄지며,
  청산 대상자의 대출량을 감소시키고 청산 진행자의 예금량을 감소시킵니다.

4. partialLiquidationUserReward
  청산에 대한 Reward를 지급하며 우선적으로 partialLiquidationUser가
  실행 되고 난 후 이뤄집니다. 이는 청산 실행자의 자격이 충족되었다는 뜻이며,
  대출을 대신 갚아줬다는 의미를 가집니다. 따라서 Reward 함수 내에서는
  Reward를 포함한 청산량 만큼을 예금량에서 감소시키고 청산 실행자의 예금량을 증가시킵니다.
</pre>
# SI (Service Incentive)
## Description
Bifi를 사용하는 사용자에게 Incentive를 주기 위한 Contract입니다. 사용자가 Handler에서 User Action을 할 때마다 리워드가 계산됩니다.

### Variable
#### Global Variable
| 변수명 | 의미 | Unique Key | Only Token |
|---|---|---|---|
| `owner` | Handler의 Owner |
| `handlerID` | Handler마다 부여되는 값|O|
| `tokenName` | Handler가 처리하는 token의 이름|O|
| `unifiedPoint` |Bifi 내에서 통일화 되는 Decimal| |
| `underlyingTokenDecimal` |Wrapping 된 token이 가지고 있는 실제 Decimal||O|
| `marketManager` | Handler와 mapping 된 Token Manager instance |
| `interestModelInstance` | Handler와 mapping 된 Interest Model (variable align을 위함)|
| `handlerDataStorage` | Handler와 mapping 된 Data Storage |
| `SIHandlerDataStorage`| SI Handler의 Datastorage |
| `erc20Instance`|Handler가 Wrapping한 Token Contract의 주소(variable align을 위함)||O|

## Action
<pre>
1. updateRewardLane
  사용자가 Handler의 Action을 할 때마다 실행되며 사용자와 마켓의
  Reward Lane을 update하고 이를 통해 SI dataStorage에 user reward가 증가하게 됩니다.
</pre>
