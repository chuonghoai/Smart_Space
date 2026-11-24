package com.vn.smart_space.service.autoassign;

import java.util.Locale;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.report.AutoAssignConfigRequest;
import com.vn.smart_space.dto.request.report.AutoAssignSimulateRequest;
import com.vn.smart_space.dto.response.autoassign.AssignmentDecisionSummaryResponse;
import com.vn.smart_space.dto.response.autoassign.AutoAssignRecommendationResponse;
import com.vn.smart_space.dto.response.report.AssignmentDecisionLogResponse;
import com.vn.smart_space.dto.response.report.AutoAssignAnalyticsResponse;
import com.vn.smart_space.dto.response.report.AutoAssignConfigResponse;
import com.vn.smart_space.model.AssignmentDecisionLog;
import com.vn.smart_space.model.AutoAssignConfig;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;

public interface IAutoAssignService {

    /**
     * Lấy khoá phân công tuần tự và trả về cấu hình hiện hành. Phải là câu lệnh DB đầu tiên
     * của transaction phân công để các truy vấn đếm tải phía sau đọc dữ liệu mới nhất.
     */
    AutoAssignConfig lockDispatchConfig();

    AutoAssignDispatchResult evaluateOnReportCreated(Report report, AutoAssignConfig config);

    AutoAssignDispatchResult evaluateManualTrigger(Report report, AutoAssignConfig config);

    AutoAssignRecommendationResponse getRecommendations(Report report, int limit, Locale locale);

    AssignmentDecisionLog recordRecommendClick(Report report, User staff, String adminId);

    void markOverriddenIfNeeded(Report report, User newStaff, String adminId);

    AssignmentDecisionSummaryResponse getDecisionSummary(Report report, Locale locale);

    AutoAssignConfigResponse getConfig();

    AutoAssignConfigResponse updateConfig(AutoAssignConfigRequest request, String adminId);

    AutoAssignRecommendationResponse simulate(AutoAssignSimulateRequest request, Locale locale);

    AutoAssignAnalyticsResponse getAnalytics();

    PageResponse<AssignmentDecisionLogResponse> getDecisionLogs(
            String outcome,
            String source,
            String categoryId,
            int page,
            int size,
            Locale locale);
}
