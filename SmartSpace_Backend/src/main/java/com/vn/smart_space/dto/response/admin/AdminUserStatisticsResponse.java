package com.vn.smart_space.dto.response.admin;

import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * KPI + Top người đóng góp cho màn Quản lý người dùng.
 * Các chỉ số "current/previous" so sánh 30 ngày gần nhất với 30 ngày liền trước.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminUserStatisticsResponse {

    long totalUsers;
    long newUsers;
    long newUsersPrevious;
    long activeReporters; // Số người dùng (distinct) có >= 1 báo cáo trong 30 ngày
    long reports;
    long reportsPrevious;
    List<TopReporter> topReporters; // Không tính báo cáo ẩn danh

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class TopReporter {
        String userId;
        String fullName;
        String avatarUrl;
        long reportCount;
    }
}
