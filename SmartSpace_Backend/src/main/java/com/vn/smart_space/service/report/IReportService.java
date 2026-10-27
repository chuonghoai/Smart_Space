package com.vn.smart_space.service.report;

import java.util.List;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.report.ReportCompleteRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.AdminMapReportsResponse;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.admin.ReportListResponse;
import com.vn.smart_space.dto.response.admin.ReportStatisticsResponse;
import com.vn.smart_space.dto.response.admin.ReportTrendResponse;
import com.vn.smart_space.dto.response.report.MapReportsResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;

public interface IReportService {
        List<ReportResponse> getDangerousReports();

        List<ReportResponse> getRecentReports(String filter, Double userLat, Double userLong);

        ReportDetailResponse createReport(ReportCreateRequest request, String userId);

        ReportDetailResponse getReportDetail(String reportId);

        ReportDetailResponse getReportDetail(String reportId, String viewerId, String viewerScope);

        PageResponse<ReportDetailResponse> getFeed(String status, int page, int size,
                        Double userLat, Double userLong);

        // Client Map — reports inside a viewport (bounding box)
        MapReportsResponse getReportsInBounds(Double minLat, Double maxLat, Double minLng, Double maxLng,
                        int limit);

        List<RecentReportResponse> getAdminRecentReports(String tab, int limit);

        ReportDetailResponse assignReport(String reportId, ReportAssignRequest request, String adminId);

        ReportDetailResponse completeReport(String reportId, ReportCompleteRequest request, String staffId);

        List<ReportResponse> getMyReports(String userId, String status, int limit);

        // Dashboard statistics
        ReportStatisticsResponse getReportStatistics();

        ReportTrendResponse getReportTrend(String period);

        // Admin Get List Report
        ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
                        String from, String to, String search);

        // Admin Update Status Report
        ReportDetailResponse updateReportStatus(String reportId, String newStatus, String adminId);

        // Admin Map — lightweight list with lat/lng, optional viewport (all bounds null = whole map)
        AdminMapReportsResponse getAdminMapReports(String status, String severity, String assigneeId,
                        String from, String to, Double minLat, Double maxLat, Double minLng, Double maxLng,
                        int limit);

        List<RecentReportResponse> getStaffAssignedReports(String staffId, String status, int page, int limit);

        ReportStatisticsResponse getStaffReportStatistics(String staffId);

        ReportDetailResponse reviewReport(String reportId, com.vn.smart_space.dto.request.report.ReportReviewRequest request, String userId);

        List<RecentReportResponse> getUnsatisfactoryReports(String tab);

        default com.vn.smart_space.dto.response.report.ReportNearbyAlertResponse checkNearbyReportsAndAlert(Double lat, Double lng, Double radius, String userId) {
                return checkNearbyReportsAndAlert(lat, lng, radius, userId, true);
        }

        com.vn.smart_space.dto.response.report.ReportNearbyAlertResponse checkNearbyReportsAndAlert(Double lat, Double lng, Double radius, String userId, Boolean notify);

        ReportDetailResponse updateReport(String reportId, ReportCreateRequest request, String userId);

        ReportDetailResponse cancelReport(String reportId, String userId);
}

