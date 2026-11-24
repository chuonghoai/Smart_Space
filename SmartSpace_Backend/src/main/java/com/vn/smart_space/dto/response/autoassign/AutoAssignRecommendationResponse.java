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
public class AutoAssignRecommendationResponse {

    @JsonProperty("report_id")
    String reportId;

    @JsonProperty("category_id")
    String categoryId;

    @JsonProperty("category_code")
    String categoryCode;

    @JsonProperty("category_name_vi")
    String categoryNameVi;

    @JsonProperty("category_name_en")
    String categoryNameEn;

    @JsonProperty("current_mode")
    String currentMode;

    @JsonProperty("max_radius_km")
    double maxRadiusKm;

    @JsonProperty("max_concurrent_tasks")
    int maxConcurrentTasks;

    @JsonProperty("total_eligible_candidates")
    int totalEligibleCandidates;

    @JsonProperty("fallback_reason")
    String fallbackReason;

    @JsonProperty("fallback_message")
    String fallbackMessage;

    List<StaffCandidateScoreResponse> candidates;
}
