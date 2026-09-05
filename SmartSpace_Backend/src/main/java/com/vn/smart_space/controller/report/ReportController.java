package com.vn.smart_space.controller.report;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.response.report.ReportResponse;
import com.vn.smart_space.service.report.IReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final IReportService reportService;

    @GetMapping("/dangerous")
    public ResponseEntity<ApiResponse> getDangerousReports() {
        List<ReportResponse> reports = reportService.getDangerousReports();
        return ResponseEntity.ok(ApiResponse.success("Success", reports));
    }

    @GetMapping("/recent")
    public ResponseEntity<ApiResponse> getRecentReports(
            @RequestParam(required = false) String filter,
            @RequestParam(name = "user_lat", required = false) Double userLat,
            @RequestParam(name = "user_long", required = false) Double userLong) {
        
        List<ReportResponse> reports = reportService.getRecentReports(filter, userLat, userLong);
        return ResponseEntity.ok(ApiResponse.success("Success", reports));
    }

    @PostMapping
    public ResponseEntity<ApiResponse> createReport(
            @org.springframework.security.core.annotation.AuthenticationPrincipal org.springframework.security.oauth2.jwt.Jwt jwt,
            @org.springframework.web.bind.annotation.RequestBody com.vn.smart_space.dto.request.report.ReportCreateRequest request) {
        String userId = null;
        if (jwt != null && jwt.hasClaim("userId")) {
            userId = jwt.getClaim("userId").toString();
        }
        com.vn.smart_space.dto.response.report.ReportDetailResponse response = reportService.createReport(request, userId);
        return ResponseEntity.ok(ApiResponse.success("Report created successfully", response));
    }
}
