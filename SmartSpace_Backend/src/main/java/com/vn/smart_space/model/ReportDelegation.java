package com.vn.smart_space.model;

import com.vn.smart_space.consts.EDelegationStatus;
import com.vn.smart_space.consts.EReportSeverity;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

/**
 * Yêu cầu nhờ một staff khác làm giùm task.
 * Mức độ, tỷ lệ, hoa hồng và bonus được chốt lúc gửi yêu cầu → admin đổi cấu
 * hình.
 */
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "report_delegations", indexes = {
        @Index(name = "idx_delegation_report_status", columnList = "report_id, status"),
        @Index(name = "idx_delegation_helper_status", columnList = "helper_id, status"),
        @Index(name = "idx_delegation_requester", columnList = "requester_id"),
        @Index(name = "idx_delegation_status_expires", columnList = "status, expires_at")
})
public class ReportDelegation extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = false)
    Report report;

    /** Staff đang được giao task, người trả bonus. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    User requester;

    /** Staff được nhờ, người nhận hoa hồng + bonus khi hoàn tất. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "helper_id", nullable = false)
    User helper;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false, columnDefinition = "VARCHAR(30)")
    EDelegationStatus status = EDelegationStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "severity", columnDefinition = "VARCHAR(20)")
    EReportSeverity severity;

    @Column(name = "rate_percent", nullable = false)
    Double ratePercent;

    @Column(name = "commission_amount", nullable = false)
    Double commissionAmount;

    @Column(name = "bonus_amount", nullable = false)
    Double bonusAmount;

    @Column(name = "note", length = 500)
    String note;

    @Column(name = "expires_at", nullable = false)
    LocalDateTime expiresAt;

    @Column(name = "responded_at")
    LocalDateTime respondedAt;

    @Column(name = "completed_at")
    LocalDateTime completedAt;
}
