package com.vn.smart_space.model;

import com.vn.smart_space.consts.EReportSeverity;
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

    // Tỷ lệ bonus (%) người làm giùm nhận thêm, tính trên hoa hồng của task, trả từ ví người nhờ.
    // DEFAULT trong columnDefinition để ddl-auto=update điền sẵn cho dòng cấu hình đã có.
    @Builder.Default
    @Column(name = "delegation_rate_low", nullable = false, columnDefinition = "DOUBLE DEFAULT 50")
    Double delegationRateLow = 50.0;

    @Builder.Default
    @Column(name = "delegation_rate_medium", nullable = false, columnDefinition = "DOUBLE DEFAULT 40")
    Double delegationRateMedium = 40.0;

    @Builder.Default
    @Column(name = "delegation_rate_high", nullable = false, columnDefinition = "DOUBLE DEFAULT 30")
    Double delegationRateHigh = 30.0;

    @Builder.Default
    @Column(name = "delegation_rate_critical", nullable = false, columnDefinition = "DOUBLE DEFAULT 20")
    Double delegationRateCritical = 20.0;

    /** Hoa hồng hệ thống của task theo mức độ (chưa đánh giá → mức thấp, như luồng hoa hồng hiện tại). */
    public double commissionFor(EReportSeverity severity) {
        if (severity == null) return commissionLow;
        return switch (severity) {
            case low -> commissionLow;
            case medium -> commissionMedium;
            case high -> commissionHigh;
            case critical -> commissionCritical;
        };
    }

    /** Tỷ lệ bonus nhờ làm giùm (%) theo mức độ. */
    public double delegationRateFor(EReportSeverity severity) {
        if (severity == null) return delegationRateLow;
        return switch (severity) {
            case low -> delegationRateLow;
            case medium -> delegationRateMedium;
            case high -> delegationRateHigh;
            case critical -> delegationRateCritical;
        };
    }
}

