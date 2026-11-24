package com.vn.smart_space.controller.report;

import java.util.Locale;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.report.AutoAssignConfigRequest;
import com.vn.smart_space.dto.request.report.AutoAssignSimulateRequest;
import com.vn.smart_space.service.autoassign.IAutoAssignService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@RestController
@RequestMapping("/admin/auto-assign")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminAutoAssignController {

    IAutoAssignService autoAssignService;

    @GetMapping("/config")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getConfig() {
        return ResponseEntity.ok(ApiResponse.success("system.success", autoAssignService.getConfig()));
    }

    @PutMapping("/config")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> updateConfig(
            @Valid @RequestBody AutoAssignConfigRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        String adminId = jwt != null ? jwt.getClaimAsString("userId") : null;
        return ResponseEntity.ok(
                ApiResponse.success("auto_assign.config.updated", autoAssignService.updateConfig(request, adminId)));
    }

    @PostMapping("/simulate")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> simulate(
            @Valid @RequestBody AutoAssignSimulateRequest request,
            Locale locale) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", autoAssignService.simulate(request, locale)));
    }

    @GetMapping("/analytics")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getAnalytics() {
        return ResponseEntity.ok(
                ApiResponse.success("system.success", autoAssignService.getAnalytics()));
    }

    @GetMapping("/logs")
    @PreAuthorize("hasRole('admin')")
    public ResponseEntity<ApiResponse> getDecisionLogs(
            @RequestParam(required = false) String outcome,
            @RequestParam(required = false) String source,
            @RequestParam(required = false) String categoryId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "15") int size,
            Locale locale) {
        return ResponseEntity.ok(
                ApiResponse.success("system.success",
                        autoAssignService.getDecisionLogs(outcome, source, categoryId, page, size, locale)));
    }
}
