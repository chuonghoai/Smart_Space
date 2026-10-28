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
@Table(name = "staff_wallets", uniqueConstraints = {
        @UniqueConstraint(columnNames = { "user_id" })
})
public class StaffWallet extends AbstractEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    User user;

    @Builder.Default
    @Column(name = "balance", nullable = false)
    Double balance = 0.0;
}

