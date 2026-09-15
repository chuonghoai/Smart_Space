package com.vn.smart_space.dto.response.admin;

import java.util.List;
import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StaffChartResponse {
    // Donut chart data
    long totalStaff;
    long activeStaff;
    long blockedStaff;

    // Bar chart data
    List<WorkloadItem> topWorkload;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class WorkloadItem {
        String staffId;
        String staffName;
        long processingCount;
    }
}
