# Handler Data Storage

## Description
This decouples data storage from the logic of Market Handler to follow Upgradable Contract patterns. A single Market Handler has a single Market Data Storage.

All the amount in Data Storage are represented in the unified decimal number.

### Variable
| Variable | Meaning |
|---|---|
| `owner` | Data Storage owner |
| `reservedAddr` | address of the reserve controller |
| `marketHandlerAddr` | Market Handler address  |
| `interestModelAddr` | Interest Model address  |
| `lastUpdatedBlock` | block number of latest action  |
| `inactiveActionDelta` | block number difference between the last action and the current action |
| `actionDepositEXR` | deposit Exchange Rate (EXR) updated by the first action |
| `actionBorrowEXR` | borrow Exchange Rate (EXR) updated by the first action |
| `depositTotalAmount` | total deposit amount of the Market Handler |
| `borrowTotalAmount` |  total borrow amount of the Market Handler |
| `userAccessed` | whether or not the user is a revisited customer of BiFi |
| `intraDepositAmount` | total deposit amount of the Market Handler by users  |
| `intraBorrowAmount` | total borrow amount of the Market Handler by users |
| `globalDepositEXR` | Deposit Exchange Rate updated by the last action |
| `globalBorrowEXR` | Borrow Exchange Rate updated by the last action|
| `userDepositEXR` | globalDepositEXR at the user's latest action |
| `userBorrowEXR` | globalBorrowEXR at the user's latest action |
| `unifiedTokenDecimal` | unified decimal point for the fixed-number calculation |
| `underlyingTokenDecimal` | decimal point of the underlying token |
| `liquidityLimit` | percentage of available liquidity of the Market Handler |


# marketSIHandlerDataStorage.sol
## Description
This stores the data for the Service Incentive (SI) contract.

### Variable
| Variable | Meaning |
|---|---|
| `emergency` | status of the circuit break |
| `owner` | Data Storage owner |
| `SIHandlerAddr` | address of the SI contract |
| `marketRewardInfo` | market reward information |
| `userRewardInfo` | user reward information |
| `betaRate` | weight between deposit and borrow amount in the calculation of rewards |

---

## Description
Handler에서 사용되는 데이터를 분리하여 저장합니다.
Upgradable한 Contract를 위하여 Data Storage를 분리하였습니다. Token Handler와 Data Storage는 1:1
관계를 가집니다.
Data Storage에 모든 Amount는 unifiedTokenAmount를 저장합니다.

### Variable
| 변수명 | 의미 |
|---|---|
| `owner` | Datastorage의 owner |
| `reservedAddr` | Reserve 제어권자 주소 |
| `marketHandlerAddr` | Data Storage와 연결되어 있는 Handler의 주소 |
| `interestModelAddr` | Data Storage와 연결되어 있는 이자 모델의 주소 |
| `lastUpdatedBlock` | Last Action을 한 block의 number (블록 내 공유) |
| `inactiveActionDelta` | First Action(new block)을 한 시점의 block number와 lastUpdatedBlock와의 차 (블록 내 공유) |
| `actionDepositEXR` | First Action(new block)이 갱신한 Deposit Exchange Rate (블록 내 공유)
| `actionBorrowEXR` | First Action(new block)이 갱신한 Borrow Exchange Rate (블록 내 공유)
| `depositTotalAmount` | Handler에 예금 된 총 코인 or 토큰의 양 |
| `borrowTotalAmount` | Handler에서 대출 된 총 코인 or 토큰의 양|
| `userAccessed` | 유저의 Bifi 기존 거래 여부 |
| `intraDepositAmount` | Handler에 유저가 예금한 코인 or 토큰의 양 |
| `intraBorrowAmount` | Handler에서 유저가 대출한 코인 or 토큰의 양 |
| `globalDepositEXR` | Last Action이 갱신한 Deposit Exchange Rate |
| `globalBorrowEXR` | Last Action이 갱신한 Borrow Exchange Rate |
| `userDepositEXR` | User의 Last Action 시점의 globalDepositEXR |
| `userBorrowEXR` | User의 Last Action 시점의 globalBorrowEXR |
| `unifiedTokenDecimal` | Bifi에서 사용되는 통합 된 Token Decimal |
| `underlyingTokenDecimal` | 실제 Token Contract의 Decimal |
| `liquidityLimit` | Token Handler에서 제공할 수 있는 토큰 유동성의 Percent |


# marketSIHandlerDataStorage.sol
## Description
SI Contract에서 사용되는 데이터를 분리하여 저장합니다.
Upgradable한 Contract를 위하여 Data Storage를 분리하였습니다. SI Contract와 Data Storage는 1:1
관계를 가집니다.

### Variable
| 변수명 | 의미 |
|---|---|
| `emergency` | CircuitBreak가 발동 했는지에 대한 여부 |
| `owner` | Datastorage의 owner |
| `SIHandlerAddr` | Service incentive contract의 주소 |
| `marketRewardInfo` | handler의 reward 관련 global variable |
| `userRewardInfo` | handler의 사용자 reward 관련 variable |
| `betaRate` | 사용자의 deposit, borrow의 가중치 |
