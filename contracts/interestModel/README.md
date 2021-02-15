# Interest Model
## Description
This module implements the interest model. A Market Handler can have its own interest model.

### Variable
| Variable | Meaning |
|---|---|
| `blocksPerYear` | the number of blocks for a year (approximated) |
| `minimumInterestRate` | minimum interest rate |
| `liquiditySensitivity` | sensitivity of the interest rate on utilization |
| `interestIndex` | the latest interest index of the user |
| `tokenUnit` | unit for the fixed-number calculation |

### [Interest Model Parameters](https://github.com/bifrost-platform/BIFI/blob/master/docs/ENG/(ENG)_BiFi_Smart_Contract_Interest_Model_Design.pdf)
**Utilization Ratio (U)** : Borrow / (Deposit + Borrow) <br>
**Borrow Interest Rate (BIR)** : minimumInterestRate + (U * liquiditySensitivity)<br>
**Supply Interest Rate (SIR)** : BIR * U <br> <br>

**Global Deposit Exchange Rate(GDEXR)** : Main exchange rate for deposit, updated for every action  <br>
**Global Borrow Exchange Rate(GBEXR)** : Main exchange rate for borrow, updated for every action  <br> <br>

**Action Deposit Exchange Rate(ADEXR)** : GDEXR that is updated at the first action of a block <br>
**Action Borrow Exchange Rate(ABEXR)** : GBEXR that is updated at the first action of a block <br> <br>

**User Deposit Exchange Rate(UDEXR)** : calculated from ADEXR <br>
**User Borrow Exchange Rate(UBEXR)** : calculated from ABEXR <br> <br>

---

## Description
시장에 적용되는 이자율 모델이 정의 되어있습니다. 이자율은 예금, 대출에 대해서 부가되며 Token Handler와 1:1 관계를 가집니다.

### Variable
| 변수명 | 의미 |
|---|---|
| `blocksPerYear` | Mapping된 Token Handler의 Domain에 1년간 생성되는 블록의 대략적인 값|
| `minimumInterestRate` | 최소 이자율|
| `liquiditySensitivity` | 유동성 변화에 따른 민감성 (민감율) |
| `interestIndex` | 유저의 마지막 이자 갱신 블록 넘버 |
| `tokenUnit` | 소수점 연산을 위한 토큰 단위 |

### [Interest Model Parameters](https://github.com/bifrost-platform/BIFI/blob/master/docs/KOR/(KOR)_BiFi_Smart_Contract_Interest_Model_Design.pdf)
**Utilization Ratio (U)** : Borrow / (Deposit + Borrow) <br>
**Borrow Interest Rate (BIR)** : minimumInterestRate + (U * liquiditySensitivity)<br>
**Supply Interest Rate (SIR)** : BIR * U <br> <br>

**Global Deposit Exchange Rate(GDEXR)** : 모든 Action에서 업데이트된 UDEXR <br>
**Global Borrow Exchange Rate(GBEXR)** : 모든 Action에서 업데이트된 UBEXR <br> <br>

**Action Deposit Exchange Rate(ADEXR)** : Block내 첫 Action에서 업데이트 되는 GDEXR <br>
**Action Borrow Exchange Rate(ABEXR)** : Block내 첫 Action에서 업데이트 되는 GBEXR <br> <br>

**User Deposit Exchange Rate(UDEXR)** : 각 액션에서 ADEXR기반으로 계산된 사용자의 UDEXR<br>
**User Borrow Exchange Rate(UBEXR)** : 각 액션에서 ABEXR기반으로 계산된 사용자의 UBEXR<br> <br>
