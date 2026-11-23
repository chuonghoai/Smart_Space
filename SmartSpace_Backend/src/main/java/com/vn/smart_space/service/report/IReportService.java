package com.vn.smart_space.service.report;

import java.util.List;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.report.ReportCompleteRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.AdminMapReportsResponse;
import com.vn.smart_space.dto.response.admin.AdminSpatialAnalyticsResponse;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.admin.ReportListResponse;
import com.vn.smart_space.dto.response.admin.ReportStatisticsResponse;
import com.vn.smart_space.dto.response.admin.ReportTrendResponse;
import com.vn.smart_space.dto.response.report.MapReportsResponse;
import com.vn.smart_space.dto.response.report.MyReportsSummaryResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;

public interface IReportService {
        List<ReportResponse> getDangerousReports();

        List<ReportResponse> getRecentReports(String filter, Double userLat, Double userLong);

        ReportDetailResponse createReport(ReportCreateRequest request, String userId);

        ReportDetailResponse getReportDetail(String reportId);

        ReportDetailResponse getReportDetail(String reportId, String viewerId, String viewerScope);

        // Client feed — sort "nearby" (needs userLat/userLong) orders by distance in the DB, otherwise newest first
        // from/to: yyyy-MM-dd, both ends inclusive, null = unbounded
        PageResponse<ReportDetailResponse> getFeed(String status, String severity, String search, String from,
                        String to, String sort, int page, int size, Double userLat, Double userLong);

        // Client Map — reports inside a viewport (bounding box), narrowed by filter & timeframe
        MapReportsResponse getReportsInBounds(String viewerId, Double minLat, Double maxLat, Double minLng,
                        Double maxLng, String filter, String timeframe, int limit);

        default MapReportsResponse getReportsInBounds(String viewerId, Double minLat, Double maxLat, Double minLng,
                        Double maxLng, String filter, int limit) {
                return getReportsInBounds(viewerId, minLat, maxLat, minLng, maxLng, filter, null, limit);
        }

        List<RecentReportResponse> getAdminRecentReports(String tab, int limit);

        ReportDetailResponse assignReport(String reportId, ReportAssignRequest request, String adminId);

        ReportDetailResponse completeReport(String reportId, ReportCompleteRequest request, String staffId);

        // Client My Reports — paged, optional status ("rehandling" = owner marked unresolved), severity, overdue & keyword
        default PageResponse<ReportResponse> getMyReports(String userId, String status, String severity, String search,
                        String from, String to, int page, int size) {
                return getMyReports(userId, status, severity, search, from, to, null, page, size);
        }

        PageResponse<ReportResponse> getMyReports(String userId, String status, String severity, String search,
                        String from, String to, Boolean overdue, int page, int size);

        MyReportsSummaryResponse getMyReportsSummary(String userId);

        // Dashboard statistics
        ReportStatisticsResponse getReportStatistics();

        ReportTrendResponse getReportTrend(String period);

        // Admin Get List Report
        default ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
                        String from, String to, String search) {
                return getAdminReportList(page, size, status, severity, assigneeId, from, to, search, null, false);
        }

        /**
         * @param excludeRehandling true: lọc theo trạng thái thì bỏ báo cáo "xử lý lại"
         *                          (khớp nhóm tách riêng trên thẻ thống kê); Kanban
         *                          để false để giữ báo cáo trong cột trạng thái gốc.
         */
        default ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
                        String from, String to, String search, Boolean overdue, boolean excludeRehandling) {
                return getAdminReportList(page, size, status, severity, assigneeId, from, to, search, overdue,
                                excludeRehandling, null, null);
        }

        ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
                        String from, String to, String search, Boolean overdue, boolean excludeRehandling,
                        Boolean atRisk, Boolean bottleneck);

        AdminSpatialAnalyticsResponse getSpatialAnalytics(int limit);

        // Admin Update Status Report
        default ReportDetailResponse updateReportStatus(String reportId, String newStatus, String adminId) {
                return updateReportStatus(reportId, newStatus, null, adminId);
        }

        ReportDetailResponse updateReportStatus(String reportId, String newStatus, String reason, String adminId);

        // Admin Map — lightweight list with lat/lng, optional viewport (all bounds null = whole map)
        default AdminMapReportsResponse getAdminMapReports(String status, String severity, String assigneeId,
                        String from, String to, Double minLat, Double maxLat, Double minLng, Double maxLng,
                        int limit) {
                return getAdminMapReports(status, severity, assigneeId, from, to, null, minLat, maxLat, minLng, maxLng, limit);
        }

        AdminMapReportsResponse getAdminMapReports(String status, String severity, String assigneeId,
                        String from, String to, String timeframe, Double minLat, Double maxLat, Double minLng, Double maxLng,
                        int limit);

        default List<RecentReportResponse> getStaffAssignedReports(String staffId, String status, int page, int limit) {
                return getStaffAssignedReports(staffId, status, null, page, limit);
        }

        List<RecentReportResponse> getStaffAssignedReports(String staffId, String status, Boolean overdue, int page, int limit);

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
