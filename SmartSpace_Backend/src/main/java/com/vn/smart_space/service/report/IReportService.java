package com.vn.smart_space.service.report;

import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import java.util.List;

public interface IReportService {
    List<ReportResponse> getDangerousReports();
    List<ReportResponse> getRecentReports(String filter, Double userLat, Double userLong);
    
    ReportDetailResponse createReport(ReportCreateRequest request, String userId);
    ReportDetailResponse getReportDetail(String reportId);

    List<RecentReportResponse> getAdminRecentReports(String tab, int limit);
    ReportDetailResponse assignReport(String reportId, ReportAssignRequest request, String adminId);
}
