package com.vn.smart_space.model;

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
@Table(name = "staff_bank_accounts", indexes = {
        @Index(name = "idx_staff_bank_account_user_id", columnList = "user_id"),
        @Index(name = "idx_staff_bank_account_acc_number", columnList = "bank_account_number")
})
public class StaffBankAccount extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    User user;

    @Column(name = "bank_code")
    String bankCode;

    @Column(name = "bank_name", nullable = false)
    String bankName;

    @Column(name = "bank_account_number", nullable = false)
    String bankAccountNumber;

    @Column(name = "bank_account_name", nullable = false)
    String bankAccountName;
}

