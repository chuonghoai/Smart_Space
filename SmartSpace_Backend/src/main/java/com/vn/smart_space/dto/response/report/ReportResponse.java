package com.vn.smart_space.dto.response.report;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ReportResponse {
    private String id;
    private String title;
    private String description;

    @JsonProperty("image_url")
    private String imageUrl;

    private Double latitude;
    private Double longitude;
    private String status;

    private String severity;

    @JsonProperty("created_at")
    private String createdAt;

    @JsonProperty("distance_in_meters")
    private Double distanceInMeters;

    @JsonProperty("assigned_at")
    private String assignedAt;

    @JsonProperty("is_review_resolved")
    private Boolean isReviewResolved;

    @JsonProperty("user_id")
    private String userId;
}
