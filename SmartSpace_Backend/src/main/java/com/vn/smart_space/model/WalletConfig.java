package com.vn.smart_space.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "wallet_configs")
public class WalletConfig extends AbstractEntity {

    @Builder.Default
    @Column(name = "commission_low", nullable = false)
    Double commissionLow = 2000.0;

    @Builder.Default
    @Column(name = "commission_medium", nullable = false)
    Double commissionMedium = 5000.0;

    @Builder.Default
    @Column(name = "commission_high", nullable = false)
    Double commissionHigh = 7000.0;

    @Builder.Default
    @Column(name = "commission_critical", nullable = false)
    Double commissionCritical = 10000.0;

    @Builder.Default
    @Column(name = "penalty_rate_1", nullable = false)
    Double penaltyRate1 = 20.0;

    @Builder.Default
    @Column(name = "penalty_rate_2", nullable = false)
    Double penaltyRate2 = 20.0;

    @Builder.Default
    @Column(name = "penalty_rate_3", nullable = false)
    Double penaltyRate3 = 60.0;
}

