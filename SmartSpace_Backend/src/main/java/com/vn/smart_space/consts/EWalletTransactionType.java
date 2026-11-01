package com.vn.smart_space.consts;

public enum EWalletTransactionType {
    COMMISSION,
    PENALTY_DEDUCTION,
    WITHDRAWAL,
    WITHDRAWAL_HOLD,
    WITHDRAWAL_REFUND,
    /** Giữ bonus trong ví người nhờ khi gửi yêu cầu nhờ làm giùm (trừ tiền). */
    DELEGATION_HOLD,
    /** Hoàn bonus về ví người nhờ khi yêu cầu không thành (cộng tiền). */
    DELEGATION_REFUND,
    /** Bonus cộng cho người làm giùm khi task hoàn tất (cộng tiền). */
    DELEGATION_BONUS
}
