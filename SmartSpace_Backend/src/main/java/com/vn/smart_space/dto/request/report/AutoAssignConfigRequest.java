package com.vn.smart_space.dto.request.report;

import com.vn.smart_space.consts.EAutoAssignMode;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
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
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AutoAssignConfigRequest {

    @NotNull(message = "auto_assign.mode.required")
    EAutoAssignMode mode;

    @NotNull(message = "auto_assign.weight.required")
    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double distanceWeight;

    @NotNull(message = "auto_assign.weight.required")
    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double monthlyWorkloadWeight;

    @NotNull(message = "auto_assign.weight.required")
    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double activeLoadWeight;

    @NotNull(message = "auto_assign.weight.required")
    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double onTimeRateWeight;

    @NotNull(message = "auto_assign.max_radius.required")
    @DecimalMin(value = "0.5", message = "auto_assign.max_radius.min")
    Double maxRadiusKm;

    @NotNull(message = "auto_assign.max_concurrent.required")
    @Min(value = 1, message = "auto_assign.max_concurrent.min")
    Integer maxConcurrentTasks;

    @NotNull(message = "auto_assign.target_monthly.required")
    @Min(value = 1, message = "auto_assign.target_monthly.min")
    Integer targetMonthlyTasks;
}
