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

    @JsonProperty("assigned_at")
    private String assignedAt;

    @JsonProperty("resolved_note")
    private String resolvedNote;

    @JsonProperty("resolved_image_urls")
    private List<String> resolvedImageUrls;

    @JsonProperty("resolved_at")
    private String resolvedAt;

    @JsonProperty("is_review_resolved")
    private Boolean isReviewResolved;

    @JsonProperty("rating")
    private Integer rating;

    @JsonProperty("review_note")
    private String reviewNote;

    @JsonProperty("review_image_urls")
    private List<String> reviewImageUrls;

    @JsonProperty("reviewed_at")
    private String reviewedAt;

    @JsonProperty("user_id")
    private String userId;

    @JsonProperty("base_commission")
    private Double baseCommission;

    @JsonProperty("deducted_commission")
    private Double deductedCommission;

    @JsonProperty("final_commission")
    private Double finalCommission;

    @JsonProperty("expected_commission")
    private Double expectedCommission;

    @JsonProperty("commission_awarded")
    private Boolean commissionAwarded;

    @JsonProperty("rehandling_penalty_count")
    private Integer rehandlingPenaltyCount;
}
