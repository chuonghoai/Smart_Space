package com.vn.smart_space.model;

import com.vn.smart_space.consts.EWalletTransactionType;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "staff_wallet_transactions", indexes = {
        @Index(name = "idx_staff_wallet_trans_wallet_id", columnList = "wallet_id"),
        @Index(name = "idx_staff_wallet_trans_created_at", columnList = "created_at")
})
public class StaffWalletTransaction extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wallet_id", nullable = false)
    StaffWallet wallet;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    EWalletTransactionType type;

    @Column(name = "amount", nullable = false)
    Double amount;

    @Column(name = "balance_after", nullable = false)
    Double balanceAfter;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id")
    Report report;

    @Column(name = "title_i18n_key")
    String titleI18nKey;

    @Column(name = "title_params")
    String titleParams;
}

