package com.vn.smart_space.dto.response.delegation;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DelegationResponse {

    String id;

    /** PENDING | ACCEPTED | DECLINED | CANCELLED | EXPIRED | COMPLETED | REVOKED */
    String status;

    @JsonProperty("report_id")
    String reportId;

    @JsonProperty("report_title")
    String reportTitle;

    @JsonProperty("report_image_url")
    String reportImageUrl;

    @JsonProperty("report_address")
    String reportAddress;

    @JsonProperty("report_status")
    String reportStatus;

    String severity;

    StaffColleagueResponse requester;

    StaffColleagueResponse helper;

    @JsonProperty("rate_percent")
    Double ratePercent;

    @JsonProperty("commission_amount")
    Double commissionAmount;

    @JsonProperty("bonus_amount")
    Double bonusAmount;

    String note;

    @JsonProperty("expires_at")
    LocalDateTime expiresAt;

    @JsonProperty("responded_at")
    LocalDateTime respondedAt;

    @JsonProperty("completed_at")
    LocalDateTime completedAt;

    @JsonProperty("created_at")
    LocalDateTime createdAt;
}
