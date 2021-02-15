# callProxy
## Description
callProxy is a data feed about BiFi. The data is collected from the multiple BiFi components.

## Returns
### callProxyMarket_getMarket
1. callProxyMarket_HandlerAsset[]
    Provide the asset information on Market Handlers (in an array)
    | Variable | Meaning |
    |---|---|
    | handlerID | handler's ID |
    | handlerAddr | handler's address |
    | tokenPrice | token price of the handler |
    | depositTotalAmount | total deposit of the handler (in the unified amount) |
    | borrowTotalAmount | total borrow of the handler (in the unified amount) |
    | depositInterestRate | deposit interest rate |
    | borrowInterestRate | borrow interest rate |
2. bool
    Indicate the status of the circuit break.

### callProxyUser_getUser
1. callProxyUser_UserHandlerAsset[]
    Provide the handler information on the given user (in an array)
    | Variable | Meaning |
    |---|---|
    | handlerAddr | handler's address |
    | tokenPrice | token price of the handler |
    | depositAmount | deposit amount of the user |
    | borrowAmount | borrow amount of the user |
    | depositInterestAmount | user's interest amount on deposit |
    | borrowInterestAmount | user's interest amount on borrow |
    | depositInterestRate | yearly interest rate on deposit |
    | borrowInterestRate | yearly interest rate on borrow  |
    | borrowLimit | the rate of the allowed rate for borrow  |
    | userMaxWithdrawAmount | maximum amount of withdraw for the user  |
    | userMaxBorrowAmount | maximum amount of borrow for the user |
    | userMaxRepayAmount | maximum amount of repay for the user  |
    | limitOfAction | maximum amount that can be handled in a single transaction |

2. callProxyUser_UserAsset
    Provide the credit information for the BiFi user
    | Variable | Meaning |
    |---|---|
    | userTotalBorrowLimitAsset | borrow limit by the user deposit |
    | userTotalMarginCallLimitAsset | margin call limit of the user |
    | userDepositCreditAsset | current deposit credit of the user |
    | userBorrowCreditAsset | current borrow credit of the user |


### callProxySI_getSI
1. callProxySI_MarketRewardInfo[]
    Provide the reward information of the handlers (in an array)
    | Variable | Meaning |
    |---|---|
    | handlerID | handler ID |
    | tokenPrice | token price of the handler |
    | dailyReward | daily reward amount of the handler  |
    | claimedReward | claimed reward amount of the handler (currently unused) |
    | depositReward | daily reward amount assigned to deposit  |
    | borrowReward | daily reward amount assigned to borrow |

2. callProxySI_GlobalRewardInfo
    Provide the summary collected from the handlers.
    | Variable | Meaning |
    |---|---|
    | totalReward | total reward amount of Bifi |
	  | dailyReward | daily reward amount  |
	  | claimedReward | claimed reward amount (currently unused) |
	  | remainReward | remained reward amount |

3. uint256
    Reward amount of the user

---

## Description
callProxy는 외부에서 Bifi의 분산되어 있는 정보를 한번에 얻어올 수 있도록 작성 된 contract입니다.

## Returns
### callProxyMarket_getMarket
1. callProxyMarket_HandlerAsset[]
    N개의 handler에 대한 정보들을 제공한다.
    | 변수명 | 의미 |
    |---|---|
    | handlerID | handler의 ID |
    | handlerAddr | handler의 address |
    | tokenPrice | handler가 wrapping한 token의 가격 |
    | depositTotalAmount | handler에 총 예금 된 token의 개수 (unified amount) |
    | borrowTotalAmount | handler에 총 대출 된 token의 개수 (unified amount) |
    | depositInterestRate | handler의 예금에 대한 연 이자율 |
    | borrowInterestRate | handler의 대출에 대한 연 이자율 |
2. bool
    CircuitBreak의 여부를 반환한다.

### callProxyUser_getUser
1. callProxyUser_UserHandlerAsset[]
    N개의 handler의 정보와 사용자의 정보를 제공한다.
    | 변수명 | 의미 |
    |---|---|
    | handlerAddr | handler의 address |
    | tokenPrice | handler가 wrapping한 token의 가격 |
    | depositAmount | handler에 사용자가 예금한 token의 개수 |
    | borrowAmount | handler에 사용자가 대출한 token의 갯수 |
    | depositInterestAmount | 사용자의 예금을 통해 쌓인 예금 이자 |
    | borrowInterestAmount | 사용자의 대출을 통해 쌓인 대출 이자 |
    | depositInterestRate | handler의 예금에 대한 연 이자율 |
    | borrowInterestRate | handler의 대출에 대한 연 이자율 |
    | borrowLimit | handler의 예금을 담보로 대출 할 수 있는 비율 |
    | userMaxWithdrawAmount | 사용자가 최대 출금 가능한 금액 |
    | userMaxBorrowAmount | 사용자가 최대 대출 가능한 금액 |
    | userMaxRepayAmount | 사용자가 최대 상환 가능한 금액 |
    | limitOfAction | 출금과 대출시 1회 최대 거래 가능 금액 |

2. callProxyUser_UserAsset
    BiFi의 내에서 사용자의 신용 가치를 제공한다.
    | 변수명 | 의미 |
    |---|---|
    | userTotalBorrowLimitAsset | 사용자의 예금을 통해 최대 대출 가능 금액 |
    | userTotalMarginCallLimitAsset | 사용자가 청산 대상자가 되는 대출의 금액 |
    | userDepositCreditAsset | 사용자의 총 예금을 통해 대출 가능한 금액 |
    | userBorrowCreditAsset | 사용자의 총 대출 금액 |


### callProxySI_getSI
1. callProxySI_MarketRewardInfo[]
    N개의 handler에 대한 reward 정보를 제공한다.
    | 변수명 | 의미 |
    |---|---|
    | handlerID | handler의 ID |
    | tokenPrice | handler가 wrapping한 token의 가격 |
    | dailyReward | handler에서 제공하는 일일 reward의 개수 |
    | claimedReward | handler에서 제공한 reward의 개수 (currently unused) |
    | depositReward | handler에서 제공하는 예금에 대한 일일 reward 개수 |
    | borrowReward | handler에서 제공하는 대출에 대한 일일 reward 개수 |

2. callProxySI_GlobalRewardInfo
    N개의 handler의 모든 정보를 통합한 Bifi reward 정보를 제공한다.
    | 변수명 | 의미 |
    |---|---|
    | totalReward | Bifi에서 제공하는 총 reward의 개수 |
	  | dailyReward | N개의 handler에서 제공하는 일일 reward의 총 개수 |
	  | claimedReward | 제공 된 reward의 개수 (currently unused) |
	  | remainReward | 남은 reward의 개수 |

3. uint256
    사용자가 받을 수 있는 Reward의 개수
