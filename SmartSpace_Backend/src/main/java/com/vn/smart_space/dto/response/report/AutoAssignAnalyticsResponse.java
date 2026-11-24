package com.vn.smart_space.dto.response.report;

import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AutoAssignAnalyticsResponse {

    long totalDecisions;
    long autoAssignedCount;
    long recommendAssignedCount;
    long fallbackCount;
    long overriddenCount;

    /**
     * Tỷ lệ phân công tự động/gợi ý thành công (không bị fallback về pending), 0..100
     */
    double autoAssignSuccessRate;

    /**
     * Tỷ lệ Admin giữ nguyên kết quả hệ thống phân công (không bị override), 0..100
     */
    double adminAcceptanceRate;

    /**
     * Chỉ số công bằng phân bổ tải tháng (0..100%, càng cao càng đồng đều)
     */
    double monthlyFairnessIndex;

    double averageMonthlyWorkload;
    long minMonthlyWorkload;
    long maxMonthlyWorkload;
    double workloadStandardDeviation;

    List<StaffWorkloadFairnessItem> staffWorkloads;

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class StaffWorkloadFairnessItem {
        String staffId;
        String fullName;
        String email;
        String avatarUrl;
        String positionName;
        String baseAddress;
        boolean hasBaseLocation;
        long activeProcessingCount;
        int maxConcurrentTasks;
        long monthlyWorkload;
        int targetMonthlyTasks;
        double onTimeRate30d;
        /**
         * Tỷ lệ tải tháng so với định mức targetMonthlyTasks (0.0 -> 1.0+)
         */
        double monthlyLoadRatio;
    }
}
