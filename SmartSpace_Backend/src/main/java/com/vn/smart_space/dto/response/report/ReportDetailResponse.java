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
public class ReportDetailResponse {
    private String id;
    private String title;
    private String description;

    @JsonProperty("image_urls")
    private List<String> imageUrls;

    private Double latitude;
    private Double longitude;
    private String status;
    private String severity;

    @JsonProperty("is_anonymous")
    private Boolean isAnonymous;
    
    private String address;
    
    @JsonProperty("location_description")
    private String locationDescription;

    @JsonProperty("created_at")
    private String createdAt;

    @JsonProperty("distance_in_meters")
    private Double distanceInMeters;

    @JsonProperty("user_name")
    private String userName;

    @JsonProperty("user_phone")
    private String userPhone;

    @JsonProperty("user_avatar_url")
    private String userAvatarUrl;

    @JsonProperty("assigned_staff_id")
    private String assignedStaffId;

    @JsonProperty("assigned_staff_name")
    private String assignedStaffName;

    @JsonProperty("assigned_staff_phone")
    private String assignedStaffPhone;

    @JsonProperty("assigned_staff_email")
    private String assignedStaffEmail;

    @JsonProperty("assigned_staff_avatar_url")
    private String assignedStaffAvatarUrl;
}
