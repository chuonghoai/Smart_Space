package com.vn.smart_space.dto.response.admin;

import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * KPI + bảng khối lượng công việc cho màn Quản lý nhân viên.
 * "current/previous" so sánh 30 ngày gần nhất với 30 ngày liền trước.
 * Thời điểm "đã xử lý" lấy theo updatedAt của báo cáo processed (processed là trạng thái cuối).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StaffStatisticsResponse {

    long totalStaff;
    long activeStaff;
    long blockedStaff;
    long processingReports;
    long resolved;
    long resolvedPrevious;
    Long avgResolutionMinutes; // null khi chưa có báo cáo đủ dữ liệu (thiếu assignedAt)
    Long avgResolutionMinutesPrevious;
    List<WorkloadItem> workload;

    boolean anyStaffMissedDeadline;
    long overdueReports;
    long completedOnTime;
    long completedLate;
    Double onTimeRate; // null khi chưa có báo cáo đã hoàn tất có deadline
    List<DeadlinePerformanceItem> deadlinePerformance;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class WorkloadItem {
        StaffResponse staff; // processingCount = số báo cáo đang xử lý
        long resolvedCount; // số báo cáo đã xử lý trong 30 ngày
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class DeadlinePerformanceItem {
        StaffResponse staff;
        long overdueCount; // đang xử lý nhưng quá deadline
        long completedLateCount; // đã hoàn tất sau deadline
        long completedOnTimeCount; // đã hoàn tất đúng/trước deadline
        boolean hasMissedDeadline;
    }
}
