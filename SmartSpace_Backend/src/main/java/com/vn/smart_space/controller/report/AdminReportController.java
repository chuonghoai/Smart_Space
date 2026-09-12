package com.vn.smart_space.controller.report;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.service.report.IReportService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

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
        return ResponseEntity.ok(ApiResponse.success("system.success", reportService.getAdminRecentReports(tab, limit)));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> assignReport(
            @PathVariable String id,
            @RequestBody ReportAssignRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(ApiResponse.success("report.assign.success", reportService.assignReport(id, request, adminId)));
    }
}
