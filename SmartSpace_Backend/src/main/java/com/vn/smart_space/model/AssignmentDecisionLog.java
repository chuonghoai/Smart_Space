package com.vn.smart_space.model;

import java.time.LocalDateTime;

import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.consts.EAutoAssignMode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
@Table(name = "assignment_decision_logs", indexes = {
        @Index(name = "idx_decision_report_created", columnList = "report_id, created_at"),
        @Index(name = "idx_decision_outcome_created", columnList = "outcome, created_at")
})
public class AssignmentDecisionLog extends AbstractEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = false)
    Report report;

    @Column(name = "category_id")
    String categoryId;

    @Column(name = "category_code", length = 50)
    String categoryCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "mode_at_decision", nullable = false, length = 20)
    EAutoAssignMode modeAtDecision;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 30)
    EAssignmentSource source;

    @Enumerated(EnumType.STRING)
    @Column(name = "outcome", nullable = false, length = 30)
    EAssignmentOutcome outcome;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "selected_staff_id")
    User selectedStaff;

    @Column(name = "final_score")
    Double finalScore;

    @Column(name = "distance_km")
    Double distanceKm;

    @Column(name = "distance_score")
    Double distanceScore;

    @Column(name = "monthly_workload")
    Integer monthlyWorkload;

    @Column(name = "monthly_workload_score")
    Double monthlyWorkloadScore;

    @Column(name = "active_processing_count")
    Integer activeProcessingCount;

    @Column(name = "active_load_score")
    Double activeLoadScore;

    @Column(name = "on_time_rate_30d")
    Double onTimeRate30d;

    @Column(name = "on_time_rate_score")
    Double onTimeRateScore;

    @Column(name = "eligible_candidate_count")
    Integer eligibleCandidateCount;

    @Column(name = "candidates_snapshot_json", columnDefinition = "TEXT")
    String candidatesSnapshotJson;

    @Column(name = "fallback_reason", length = 120)
    String fallbackReason;

    @Column(name = "overridden_by_admin_id")
    String overriddenByAdminId;

    @Column(name = "overridden_to_staff_id")
    String overriddenToStaffId;

    @Column(name = "overridden_at")
    LocalDateTime overriddenAt;
}
