package com.vn.smart_space.controller.report;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.service.report.IReportService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/reports")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminReportController {

    IReportService reportService;

    @GetMapping("/recent")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getRecentReports(
            @RequestParam(defaultValue = "all") String tab,
            @RequestParam(defaultValue = "6") int limit) {
        return ResponseEntity
                .ok(ApiResponse.success("system.success", reportService.getAdminRecentReports(tab, limit)));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> assignReport(
            @PathVariable String id,
            @RequestBody ReportAssignRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity
                .ok(ApiResponse.success("report.assign.success", reportService.assignReport(id, request, adminId)));
    }

    @GetMapping("/statistics")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getReportStatistics() {
        return ResponseEntity.ok(ApiResponse.success("system.success", reportService.getReportStatistics()));
    }

    @GetMapping("/trend")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getReportTrend(
            @RequestParam(defaultValue = "daily") String period) {
        return ResponseEntity.ok(ApiResponse.success("system.success", reportService.getReportTrend(period)));
    }

    // Get List Report + Filter
    @GetMapping("")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getReportList(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String assigneeId,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(required = false) String search) {

        return ResponseEntity.ok(ApiResponse.success("system.success",
                reportService.getAdminReportList(page, size, status, severity, assigneeId, from, to, search)));
    }

    // Update Status Report For Kanban
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> updateStatus(
            @PathVariable String id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(ApiResponse.success("system.success",
                reportService.updateReportStatus(id, body.get("status"), adminId)));
    }
}
