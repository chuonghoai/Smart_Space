package com.vn.smart_space.dto.response.report;

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
public class AssignmentDecisionLogResponse {

    String id;
    String reportId;
    String reportTitle;
    String categoryId;
    String categoryCode;
    String categoryNameVi;
    String categoryNameEn;
    String modeAtDecision;
    String source;
    String outcome;
    String selectedStaffId;
    String selectedStaffName;
    String selectedStaffPositionName;
    Integer eligibleCandidateCount;
    Double distanceKm;
    Double distanceScore;
    Integer monthlyWorkload;
    Double monthlyWorkloadScore;
    Integer activeProcessingCount;
    Double activeLoadScore;
    Double onTimeRate30d;
    Double onTimeRateScore;
    Double finalScore;
    String fallbackReason;
    String fallbackMessage;
    String overriddenByAdminId;
    String overriddenToStaffId;
    String overriddenToStaffName;
    String overriddenAt;
    String createdAt;
}
