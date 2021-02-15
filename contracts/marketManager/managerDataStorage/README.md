# Manager Data Storage
## Description
This decouples data storage from the logic of Market Manager to follow Upgradable Contract patterns. A single Market Manager has a single Market Data Storage.

## Variable
| Variable | Meaning |
|---|---|
| owner | Manager Data Storage owner|
| managerAddr | address of the Market Manager logic contract |
| liquidationManagerAddr | address of the liquidation manager |
| TokenHandler.addr | address of the handler |
| TokenHandler.support | support status of the handler |
| TokenHandler.exist | whether or not the handler exists  |
| globalRewardPerBlock | reward amount assigned for a single block |
| globalRewardDecrement | decrement amount of reward for a single block  |
| globalRewardTotalAmount | Total reward amount |
| alphaRate | weight between deposit and borrow amount in the calculation of rewards |
| alphaLastUpdated | latest block number of the alphaRate update  |
| rewardParamUpdateRewardPerBlock | incentives for the reward parameter update |
| rewardParamUpdated | latest block number of the reward parameter update (currently unused) |
| interestUpdateRewardPerblock | incentives for the interest parameter update |
| interestRewardLastUpdated | atest block number of the interest parameter update |
| tokenHandlers | map from a handlerID to a Market Handler address  |
| tokenHandlerList | list of handlerIDs |

---

## Description
Manager에서 사용되는 데이터를 분리하여 저장합니다.
Upgradable한 Contract를 위하여 Data Storage를 분리하였습니다. Market Manager와 Data Storage는 1:1 관계를 가집니다.

## Variable
| 변수명 | 의미 |
|---|---|
| owner | manager datastorage owner|
| managerAddr | manager logic contract의 주소|
| liquidationManagerAddr | liquidation manager의 주소 |
| TokenHandler.addr | handler의 주소 |
| TokenHandler.support | handler의 지원 여부 |
| TokenHandler.exist | handler의 유무 |
| globalRewardPerBlock | block당 할당 된 reward의 개수 |
| globalRewardDecrement | block당 감소하는 reward의 개수 |
| globalRewardTotalAmount | 총 reward의 개수 |
| alphaRate | handler의 deposit, borrow의 가중치 |
| alphaLastUpdated | alphaRate의 마지막 업데이트 된 block.number |
| rewardParamUpdateRewardPerBlock | reward 관련 variable update에 대한 block 당 보상 |
| rewardParamUpdated | rewardParamUpdated reward 관련 변수가 업데이트 된 마지막 block number (unused) |
| interestUpdateRewardPerblock | 이자에 관한 global variable update에 대한 block 당 보상|
| interestRewardLastUpdated | 이자에 관한 global variable update를 한 block number |
| tokenHandlers | handlerID와 tokenHandler의 mapping |
| tokenHandlerList | handlerID의 리스트 |