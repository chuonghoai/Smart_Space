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

    int selectedYear;
    int selectedMonth;
    List<AvailableMonthItem> availableMonths;

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
    double teamAvgWeightedLoad;
    long overloadedStaffCount;
    long bottleneckCount;
    List<DeadlinePerformanceItem> deadlinePerformance;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class AvailableMonthItem {
        int year;
        int month;
        String label; // MM/yyyy
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class WorkloadItem {
        StaffResponse staff; // processingCount = số báo cáo đang xử lý
        long resolvedCount; // số báo cáo đã xử lý trong tháng được chọn
        long weightedLoad;
        boolean isOverloaded;
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
        long processingCount; // đang xử lý trong tháng
        long resolvedCount; // đã xử lý trong tháng
        long rehandlingCount; // yêu cầu xử lý lại trong tháng
        long totalTasks; // tổng công việc trong tháng
        long weightedLoad;
        long bottleneckCount;
        boolean isOverloaded;
        Double efficiencyRate; // % công việc đúng hạn / tổng công việc đánh giá hạn
        boolean hasMissedDeadline;
    }
}
