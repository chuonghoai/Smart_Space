package com.vn.smart_space.dto.response.report;

import com.vn.smart_space.consts.EAutoAssignMode;

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
public class AutoAssignConfigResponse {

    String id;
    EAutoAssignMode mode;
    Double distanceWeight;
    Double monthlyWorkloadWeight;
    Double activeLoadWeight;
    Double onTimeRateWeight;
    Double maxRadiusKm;
    Integer maxConcurrentTasks;
    Integer targetMonthlyTasks;
    String updatedByAdminId;
    String updatedAt;
}
