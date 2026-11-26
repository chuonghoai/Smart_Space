package com.vn.smart_space.service.report;

import java.time.LocalDateTime;

import com.vn.smart_space.dto.response.report.ReportDensityResponse;
import com.vn.smart_space.dto.response.report.ReportDensityStatusResponse;

public interface IReportDensityService {

    ReportDensityResponse getDensity(Double north, Double south, Double east, Double west, Double zoom, String timeframe);

    default ReportDensityResponse getDensity(Double north, Double south, Double east, Double west, Double zoom) {
        return getDensity(north, south, east, west, zoom, "all");
    }

    ReportDensityStatusResponse triggerFullRecalculation(boolean async, String timeframe);

    default ReportDensityStatusResponse triggerFullRecalculation(boolean async) {
        return triggerFullRecalculation(async, null);
    }

    ReportDensityStatusResponse getStatus(String timeframe);

    default ReportDensityStatusResponse getStatus() {
        return getStatus("all");
    }

    void initializeCacheIfAbsent();

    void onReportCreated(String reportId, Double latitude, Double longitude, LocalDateTime createdAt);

    default void onReportCreated(String reportId, Double latitude, Double longitude) {
        onReportCreated(reportId, latitude, longitude, LocalDateTime.now());
    }

    void onReportMoved(String reportId, Double oldLat, Double oldLng, Double newLat, Double newLng, LocalDateTime createdAt);

    default void onReportMoved(String reportId, Double oldLat, Double oldLng, Double newLat, Double newLng) {
        onReportMoved(reportId, oldLat, oldLng, newLat, newLng, LocalDateTime.now());
    }

    void onReportRejected(String reportId, Double latitude, Double longitude, LocalDateTime createdAt);

    default void onReportRejected(String reportId, Double latitude, Double longitude) {
        onReportRejected(reportId, latitude, longitude, LocalDateTime.now());
    }
}
