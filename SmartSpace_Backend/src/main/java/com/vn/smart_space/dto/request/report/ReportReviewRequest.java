package com.vn.smart_space.dto.request.report;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ReportReviewRequest {

    @JsonProperty("is_resolved")
    private Boolean isResolved;

    @JsonProperty("rating")
    private Integer rating;

    @JsonProperty("reason")
    private String reason;

    @JsonProperty("image_urls")
    private List<String> imageUrls;
}
