package com.vn.smart_space.service.report;

import com.vn.smart_space.dto.response.report.ReportDensityResponse;
import com.vn.smart_space.dto.response.report.ReportDensityStatusResponse;

public interface IReportDensityService {

    ReportDensityResponse getDensity(Double north, Double south, Double east, Double west, Double zoom);

    ReportDensityStatusResponse triggerFullRecalculation(boolean async);

    ReportDensityStatusResponse getStatus();

    void initializeCacheIfAbsent();

    void onReportCreated(String reportId, Double latitude, Double longitude);

    void onReportMoved(String reportId, Double oldLat, Double oldLng, Double newLat, Double newLng);

    void onReportRejected(String reportId, Double latitude, Double longitude);
}

