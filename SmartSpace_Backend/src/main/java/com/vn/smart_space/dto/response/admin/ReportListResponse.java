package com.vn.smart_space.dto.response.admin;

import com.vn.smart_space.dto.PageResponse;

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
public class ReportListResponse {
    PageResponse<RecentReportResponse> reports;
}
