package com.vn.smart_space.dto.response.admin;

import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminOverviewResponse {
    long userCount;
    long staffCount;
    long adminCount;
    long issueCount;
    long pendingCount;
    long processingCount; // Không gồm báo cáo xử lý lại
    long rehandlingCount; // = unsatisfactoryProcessedCount + rehandlingProcessingCount
    long unsatisfactoryProcessedCount;
    long rehandlingProcessingCount;

    // Smart Analytics & Early Warning (Section 4.1)
    VolumeSpikeAlert volumeSpike;
    long atRiskCount;
    long pendingAtRiskCount;
    long processingAtRiskCount;
    long overloadedStaffCount;
    long pendingOver24hCount;
    List<DailyPulseItem> pulse7Days;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class VolumeSpikeAlert {
        boolean isSpike;
        boolean insufficientData;
        long todayCount;
        double baselineAvg14d;
        double baselineStdDev14d;
        double zScore;
        int activeDays;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class DailyPulseItem {
        String date; // dd/MM
        long inflow;
        long outflow;
    }
}
