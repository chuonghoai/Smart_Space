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
public class ReportCreateRequest {
    private String title;
    private String description;
    
    @JsonProperty("image_urls")
    private List<String> imageUrls;
    
    private Double latitude;
    private Double longitude;
    
    @JsonProperty("is_anonymous")
    private Boolean isAnonymous;
    
    private String address;
    
    @JsonProperty("location_description")
    private String locationDescription;
}
