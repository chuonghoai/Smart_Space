package com.vn.smart_space.model;

import com.vn.smart_space.consts.EAutoAssignMode;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "auto_assign_configs")
public class AutoAssignConfig extends AbstractEntity {

    @Enumerated(EnumType.STRING)
    @Column(name = "mode", nullable = false, length = 20)
    @Builder.Default
    EAutoAssignMode mode = EAutoAssignMode.ASSIST;

    @Column(name = "distance_weight", nullable = false)
    @Builder.Default
    Double distanceWeight = 0.45;

    @Column(name = "monthly_workload_weight", nullable = false)
    @Builder.Default
    Double monthlyWorkloadWeight = 0.35;

    @Column(name = "active_load_weight", nullable = false)
    @Builder.Default
    Double activeLoadWeight = 0.15;

    @Column(name = "on_time_rate_weight", nullable = false)
    @Builder.Default
    Double onTimeRateWeight = 0.05;

    @Column(name = "max_radius_km", nullable = false)
    @Builder.Default
    Double maxRadiusKm = 15.0;

    @Column(name = "max_concurrent_tasks", nullable = false)
    @Builder.Default
    Integer maxConcurrentTasks = 10;

    @Column(name = "target_monthly_tasks", nullable = false)
    @Builder.Default
    Integer targetMonthlyTasks = 20;

    @Column(name = "updated_by_admin_id")
    String updatedByAdminId;
}
