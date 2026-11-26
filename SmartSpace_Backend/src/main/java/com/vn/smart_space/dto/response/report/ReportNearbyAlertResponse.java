package com.vn.smart_space.dto.response.report;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReportNearbyAlertResponse {
    private int count;

    @JsonProperty("nearest_distance")
    private Double nearestDistance;

    private List<NearbyReportItemResponse> reports;
}
