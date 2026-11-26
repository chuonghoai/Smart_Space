package com.vn.smart_space.dto.response.sos;

import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class SosAlertResponse {

    String id;

    /** ACTIVE | ACKNOWLEDGED | RESOLVED */
    String status;

    /** SAFE_BY_USER | RESOLVED_BY_ADMIN | FALSE_ALARM, null khi còn mở. */
    String resolution;

    SosUserResponse user;

    Double latitude;

    Double longitude;

    Double accuracy;

    @JsonProperty("last_location_at")
    LocalDateTime lastLocationAt;

    String message;

    @JsonProperty("notified_contacts")
    Integer notifiedContacts;

    @JsonProperty("acknowledged_by")
    SosUserResponse acknowledgedBy;

    @JsonProperty("acknowledged_at")
    LocalDateTime acknowledgedAt;

    @JsonProperty("resolved_by")
    SosUserResponse resolvedBy;

    @JsonProperty("resolved_at")
    LocalDateTime resolvedAt;

    @JsonProperty("resolution_note")
    String resolutionNote;

    @JsonProperty("created_at")
    LocalDateTime createdAt;

    /** Đường di chuyển, mới nhất trước; chỉ có ở màn chi tiết của admin. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    List<SosLocationPointResponse> track;
}
