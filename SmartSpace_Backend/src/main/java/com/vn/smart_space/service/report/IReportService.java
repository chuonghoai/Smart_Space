package com.vn.smart_space.service.report;

import java.util.List;

import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.admin.ReportListResponse;
import com.vn.smart_space.dto.response.admin.ReportStatisticsResponse;
import com.vn.smart_space.dto.response.admin.ReportTrendResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;

public interface IReportService {
    List<ReportResponse> getDangerousReports();

    List<ReportResponse> getRecentReports(String filter, Double userLat, Double userLong);

    ReportDetailResponse createReport(ReportCreateRequest request, String userId);

    ReportDetailResponse getReportDetail(String reportId);

    List<RecentReportResponse> getAdminRecentReports(String tab, int limit);

    ReportDetailResponse assignReport(String reportId, ReportAssignRequest request, String adminId);

    List<ReportResponse> getMyReports(String userId, String status, int limit);

    // Dashboard statistics
    ReportStatisticsResponse getReportStatistics();

    ReportTrendResponse getReportTrend(String period);

    // Admin Get List Report
    ReportListResponse getAdminReportList(int page, int size, String status, String severity, String assigneeId,
            String from, String to, String search);

    // Admin Update Status Report
    ReportDetailResponse updateReportStatus(String reportId, String newStatus, String adminId);
}
