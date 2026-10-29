package com.vn.smart_space.model;

import com.vn.smart_space.consts.EWithdrawalStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "staff_withdrawal_requests", indexes = {
        @Index(name = "idx_staff_withdraw_user_id", columnList = "user_id"),
        @Index(name = "idx_staff_withdraw_status", columnList = "status"),
        @Index(name = "idx_staff_withdraw_created_at", columnList = "created_at")
})
public class StaffWithdrawalRequest extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    User user;

    @Column(name = "amount", nullable = false)
    Double amount;

    @Column(name = "bank_code", nullable = false)
    String bankCode;

    @Column(name = "bank_name", nullable = false)
    String bankName;

    @Column(name = "bank_account_number", nullable = false)
    String bankAccountNumber;

    @Column(name = "bank_account_name", nullable = false)
    String bankAccountName;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false)
    EWithdrawalStatus status = EWithdrawalStatus.PENDING;

    @Column(name = "note")
    String note;

    @Column(name = "admin_note")
    String adminNote;

    @Column(name = "processed_at")
    LocalDateTime processedAt;
}

