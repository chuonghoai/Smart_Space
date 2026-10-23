package com.vn.smart_space.dto.response.admin;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Chi tiết người dùng cho Admin. Thống kê và danh sách báo cáo không tính báo cáo ẩn danh. */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminUserDetailResponse {

    String id;
    String fullName;
    String email;
    String phoneNumber;
    String avatarUrl;
    String gender;
    LocalDate dateOfBirth;
    String language;
    String status;
    LocalDateTime createdAt;
    ReportStats reportStats;
    List<RecentReport> recentReports;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class ReportStats {
        long total;
        long pending;
        long processing;
        long processed;
        long rejected;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class RecentReport {
        String id;
        String title;
        EReportStatus status;
        EReportSeverity severity;
        LocalDateTime createdAt;
    }
}
