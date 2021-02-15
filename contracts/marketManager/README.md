# Market Manager
## Description
A single Market Manager manages multiple Market Handlers on a single blockchain domain.
1. Market Manager checks the eligibility for deposit and borrow. To do so, it checks all Market Handler states.
2. It internally coordinates the interest calculation process,
3. and updates the user interests and rewards for every user action.
4. It provides service-wide information on liquidity, user credits, and token prices during user actions and liquidation process.

## Variable
### Global Variable
| Variable  | Meaning |
|---|---|
| `owner` | owner address of Market Manager |
| `emergency` | status of the circuit break |
| `dataStorageInstance` | Manager Data Storage instance  |
| `oracleProxy` | address of oracle proxy |
| `rewardErc20Instance` | address of the reward token |
| `updateRewardLane` | function signature to call the update reward function in Market Handler |
| `breakerTable` | authorized addresses to set the circuit break |
| `UserAssetsInfo` | temporary storage for user information (used in applyInterestHandlers) |
| `tokenHandlerLength` | the number of the Market Handlers |

## Action
### User Action
<pre>
1. rewardClaimAll
  Claim all (Service Incentive) rewards
</pre>

### System Action
<pre>
1. handlerRegister
  Register a Market Handler. The constructor initializes the basic Market Handlers; this function can add new Market Handlers to BiFi.

2. checkReceiverRequirements
  Check the withdraw eligibility of the user (service-wide)

3. checkBorrowRequirements
  Check the borrow eligibility of the user (service-wide)
</pre>

### Admin Action
<pre>
1. setCircuitBreaker
  Set the circuit break
</pre>
### Operator Action
<pre>
1. updateRewardParams
  Update all the reward parameters. BiFi incentives the operational action by giving reward tokens.

2. interestUpdateReward
  Update all the interest parameters. BiFi incentives the operational action by giving reward tokens.
</pre>
---
# Liquidation Manager
## Description
Handle the liquidation process. Liquidate the deposit of the underwater users.

## Variable
### Global Variable
| 변수명 | 의미 |
|---|---|
| `owner` | owner of LiquidationManager |
| `emergency` | status of the circuit break |
| `unifiedPoint` | unified decimal point for the fixed-number calculation |
| `marketManager` | Market Manager instance |
| `LiquidationModel` | temporary storage to store the information of the liquidation target |

### Operator Action
<pre>
1. partialLiquidation
  Execute the liquidation. The liquidator receives the corresponding deposit of the liquidation target as for the incentive.
</pre>

---

## Description
Market Manager는 Domain(블록체인 네트워크)에 하나씩 존재하며, Market Manager는 N개의 Market Handler를 관리합니다.
1. 주요한 역할은 예금 출금과 대출에 대한 자격 요건 검사입니다. 앞의 두 가지의 행위는 모든 Market Handler의 Deposit, Borrow의 상태를 알아야 가능하므로 Market Manager는 모든 Market Handler와 양방향으로 연결되어 있습니다.
2. 사용자 액션(Tx)마다 전체 marketHandler에 이자 업데이트 프로세스를 라우팅 합니다.
3. 핸들러에서 발생한 유저액션에 따라, 연결된 모든 marketHandler의 이자 및 리워드 업데이트
4. 유저 액션이나 청산 과정 중에 시장 유동성/유저 신용/토큰 가격 등의 정보 제공

## Variable
### Global Variable
| 변수명 | 의미 |
|---|---|
| `owner` | Manager의 Owner |
| `emergency` | CircuitBreak가 발동 했는지에 대한 여부 |
| `dataStorageInstance` | Manager의 Data Storage |
| `oracleProxy` | Token의 가격을 받아오는 contract의 주소|
| `rewardErc20Instance` | Reward token의 주소 |
| `updateRewardLane` | Handler의 Reward 함수를 호출하기 위한 signature |
| `breakerTable` | CircuitBreak를 발동 시킬수 있는 권한 |
| `UserAssetsInfo` | applyInterestHandlers에서 사용되는 유저의 정보를 임시 저장하는 구조체 |
| `tokenHandlerLength` | token manager에 등록되어 있는 Handler의 개수 |

## Action
### User Action
<pre>
1. rewardClaimAll
  Service Incentive로 쌓인 Reward를 모두 출금합니다.
</pre>

### System Action
<pre>
1. handlerRegister
  Market Handler의 Constructor에서 호출되며 Bifi에서
  지원하는 토큰이 생성될 때 마다 호출됩니다.

2. checkReceiverRequirements
  예금에 대해 특정 양 출금을 할 자격이 있는지 모든
  Market Handler의 Borrow Amount를 기반으로 검사합니다.

3. checkBorrowRequirements
  특정 양을 대출 할 자격이 있는지 모든 Market Handler
  Deposit Amount를 기반으로 검사합니다.
</pre>

### Admin Action
<pre>
1. setCircuitBreaker
  긴급 상황 혹은 Version update를 위해 Bifi의 사용을 중지할 수 있다.
</pre>
### Operator Action
<pre>
1. updateRewardParams
  Reward와 관련 된 variable을 업데이트하고 이에 상응하는 Reward를 지급 받습니다.

2. interestUpdateReward
  interest와 관련 된 variable을 업데이트하고 이에 상응하는 Reward를 지급 받습니다.
</pre>
---
# Liquidation Manager
## Description
유저의 대출금이 담보금의 일정 비율을 넘으면 청산을 진행합니다.

## Variable
### Global Variable
| 변수명 | 의미 |
|---|---|
| `owner` | LiquidationManager의 Owner |
| `emergency` | CircuitBreak가 발동 했는지에 대한 여부 |
| `unifiedPoint` | Bifi 내에서 통일화 되는 Decimal |
| `marketManager` | manager의 instance |
| `LiquidationModel` | 청산 시 청산자와 청산 대상자의 정보를 임시 저장하는 struct |

### Operator Action
<pre>
1. partialLiquidation
  유저에 대해서 청산을 진행합니다. 청산자는 청산 대상자에 Deposit을 Reward로 받게 됩니다.
</pre>
