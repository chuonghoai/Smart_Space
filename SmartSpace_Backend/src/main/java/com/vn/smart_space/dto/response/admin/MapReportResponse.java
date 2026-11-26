package com.vn.smart_space.dto.response.admin;

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
public class MapReportResponse {
    String id;
    String title;
    EReportStatus status;
    EReportSeverity severity;
    Double latitude;
    Double longitude;
    String imageUrl;
    String address;
    LocalDateTime createdAt;
}
