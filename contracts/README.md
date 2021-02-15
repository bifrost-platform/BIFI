# Contracts

## Description
BiFi contracts in Solidity

<pre>
1. front
  provides the collected information

2. interestModel
  calculates interest rate on BiFi deposit and borrow

3. marketHandler
  implements Market Handlers for user actions (e.g., deposit, withdraw, borrow, and repay)

4. marketManager
  intermediates Market Handlers and checks the market condition and the user eligibility.

5. oracle
  reads the price of tokens and coins.

6. tokenStandard
  mocks ERC-20 token contracts up

7. truffleKit
  tests BiFi with the truffleKit

</pre>
---
### reqCoinProxy.sol, reqTokenProxy.sol
#### Description
The entry point of user actions. These contract maintain the token balances and call the functions in the Market Handlers or the SI contract via delegateCall. Thus, the same type of logic contracts has the identical variable alignment and structure.

#### Global Variable
| Variable | Meaning |
|---|---|
| `handler` | address of Market Handler |
| `SI` | address of the SI contract |
| `DEPOSIT ` | function signature for deposit  |
| `REDEEM ` | function signature for withdraw |
| `BORROW ` | function signature for borrow |
| `REPAY ` | function signature for repay |

---
### Errors.sol
#### Description
Error messages for revert


---

## Description
Solidity로 작성된 BiFi 컨트랙트

<pre>
1. front
  외부와 정보를 제공하기 위한 contracts

2. interestModel
  Bifi의 예금 대출에 대한 이자 계산 contracts

3. marketHandler
  Coin, Token의 Actions(deposit, withdraw ...etc)과 관련 된 logic contracts

4. marketManager
  Bifi의 모든 handler들과 연결되어 시장의 총 상황 및 유저의 자격 요건을 검사하는 contract

5. oracle
  Bifi에 등록 된 Coin, Token에 대한 가격을 가져오는 contract

6. tokenStandard
  test를 위한 erc20 mockup contract

7. truffleKit
  Bifi 동작 test를 위한 truffle kit
</pre>
---
### reqCoinProxy.sol, reqTokenProxy.sol
#### Description
User들의 요청 시작 지점입니다. 실제 자산을 보유하고 요청에 맞춰 Handler, SI contract를 delegateCall을 합니다.
따라서 Handler, SI와 변수의 align이 동일해야 하고 이 때문에 같은 변수를 가집니다. 아래의 변수에서는 Proxy contract에서 사용되는 함수만을 다룹니다.
#### Global Variable
| 변수명 | 의미 |
|---|---|
| `handler` | Handler contract의 주소 |
| `SI` | Service incentive contract의 주소 |
| `DEPOSIT ` | Handler deposit 함수의 string signature |
| `REDEEM ` | handler withdraw 함수의 string signature |
| `BORROW ` | handler borrow 함수의 string signature |
| `REPAY ` | handler repay 함수의 string signature |

---
### Errors.sol
#### Description
모든 Contract에서 발생하는 revert의 message를 관리합니다.
