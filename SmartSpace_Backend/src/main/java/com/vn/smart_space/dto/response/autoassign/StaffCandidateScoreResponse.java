package com.vn.smart_space.dto.response.autoassign;

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
public class StaffCandidateScoreResponse {

    int rank;

    @JsonProperty("staff_id")
    String staffId;

    @JsonProperty("full_name")
    String fullName;

    String email;

    @JsonProperty("phone_number")
    String phoneNumber;

    @JsonProperty("avatar_url")
    String avatarUrl;

    @JsonProperty("position_id")
    String positionId;

    @JsonProperty("position_name")
    String positionName;

    @JsonProperty("base_latitude")
    Double baseLatitude;

    @JsonProperty("base_longitude")
    Double baseLongitude;

    @JsonProperty("base_address")
    String baseAddress;

    @JsonProperty("distance_km")
    double distanceKm;

    @JsonProperty("monthly_workload")
    int monthlyWorkload;

    @JsonProperty("active_processing_count")
    int activeProcessingCount;

    @JsonProperty("on_time_rate_30d")
    double onTimeRate30d;

    @JsonProperty("distance_score")
    double distanceScore;

    @JsonProperty("monthly_workload_score")
    double monthlyWorkloadScore;

    @JsonProperty("active_load_score")
    double activeLoadScore;

    @JsonProperty("on_time_rate_score")
    double onTimeRateScore;

    @JsonProperty("final_score")
    double finalScore;

    @JsonProperty("weight_distance")
    double weightDistance;

    @JsonProperty("weight_monthly_workload")
    double weightMonthlyWorkload;

    @JsonProperty("weight_active_load")
    double weightActiveLoad;

    @JsonProperty("weight_on_time_rate")
    double weightOnTimeRate;
}
