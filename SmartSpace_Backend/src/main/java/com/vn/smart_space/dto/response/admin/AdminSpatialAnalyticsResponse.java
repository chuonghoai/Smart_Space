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
public class AdminSpatialAnalyticsResponse {

    int h3Resolution;
    long totalHotspots;
    long acceleratingHotspots;
    List<HotspotItem> hotspots;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class HotspotItem {
        String h3Index;
        double centerLat;
        double centerLng;
        String sampleAddress;
        long countLast30d;
        double prev90dAvg30d;
        double growthRatio;
        boolean isAccelerating;
        long pendingCount;
        long processingCount;
        long highCriticalCount;
        long overdueCount;
        long riskScore;
    }
}
