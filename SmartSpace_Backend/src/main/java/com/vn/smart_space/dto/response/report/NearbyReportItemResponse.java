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
public class NearbyReportItemResponse {
    private String id;
    private String title;
    private String description;

    @JsonProperty("image_urls")
    private List<String> imageUrls;

    @JsonProperty("image_url")
    private String imageUrl;

    private Double latitude;
    private Double longitude;
    private String status;
    private String severity;

    @JsonProperty("distance_in_meters")
    private Double distanceInMeters;

    @JsonProperty("created_at")
    private String createdAt;
}
