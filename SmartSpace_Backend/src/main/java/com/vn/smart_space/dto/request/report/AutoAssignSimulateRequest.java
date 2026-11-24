package com.vn.smart_space.dto.request.report;

import jakarta.validation.constraints.DecimalMin;
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
public class AutoAssignSimulateRequest {

    String categoryId;
    String categoryCode;

    @NotNull(message = "report.latitude.required")
    Double latitude;

    @NotNull(message = "report.longitude.required")
    Double longitude;

    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double distanceWeight;

    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double monthlyWorkloadWeight;

    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double activeLoadWeight;

    @DecimalMin(value = "0.0", message = "auto_assign.weight.range")
    Double onTimeRateWeight;

    Double maxRadiusKm;
    Integer maxConcurrentTasks;
    Integer targetMonthlyTasks;
    Integer limit;
}
