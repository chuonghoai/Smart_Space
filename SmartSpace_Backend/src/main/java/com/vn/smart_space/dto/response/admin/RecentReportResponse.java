package com.vn.smart_space.dto.response.admin;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecentReportResponse {
    String id;
    String title;
    EReportStatus status;
    EReportSeverity severity;
    LocalDateTime createdAt;
    String imageUrl;
    String address;
    String assignedStaffName;
    String assignedStaffAvatarUrl;

    Double latitude;
    Double longitude;

    String userName;
    String userEmail;
    String userAvatarUrl;
    String description;

    @JsonProperty("is_anonymous")
    Boolean isAnonymous;
}
