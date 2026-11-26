package com.vn.smart_space.dto.response.autoassign;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AssignmentDecisionSummaryResponse {

    String id;

    @JsonProperty("mode_at_decision")
    String modeAtDecision;

    String source;

    String outcome;

    @JsonProperty("selected_staff_id")
    String selectedStaffId;

    @JsonProperty("selected_staff_name")
    String selectedStaffName;

    @JsonProperty("selected_staff_email")
    String selectedStaffEmail;

    @JsonProperty("selected_staff_position_name")
    String selectedStaffPositionName;

    @JsonProperty("final_score")
    Double finalScore;

    @JsonProperty("distance_km")
    Double distanceKm;

    @JsonProperty("distance_score")
    Double distanceScore;

    @JsonProperty("monthly_workload")
    Integer monthlyWorkload;

    @JsonProperty("monthly_workload_score")
    Double monthlyWorkloadScore;

    @JsonProperty("active_processing_count")
    Integer activeProcessingCount;

    @JsonProperty("active_load_score")
    Double activeLoadScore;

    @JsonProperty("on_time_rate_30d")
    Double onTimeRate30d;

    @JsonProperty("on_time_rate_score")
    Double onTimeRateScore;

    @JsonProperty("eligible_candidate_count")
    Integer eligibleCandidateCount;

    @JsonProperty("fallback_reason")
    String fallbackReason;

    @JsonProperty("fallback_message")
    String fallbackMessage;

    @JsonProperty("overridden_by_admin_id")
    String overriddenByAdminId;

    @JsonProperty("overridden_to_staff_id")
    String overriddenToStaffId;

    @JsonProperty("overridden_to_staff_name")
    String overriddenToStaffName;

    @JsonProperty("overridden_at")
    String overriddenAt;

    @JsonProperty("created_at")
    String createdAt;

    @JsonProperty("candidates_snapshot")
    List<StaffCandidateScoreResponse> candidatesSnapshot;
}
