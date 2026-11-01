package com.vn.smart_space.controller.staff;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.delegation.CreateDelegationRequest;
import com.vn.smart_space.service.delegation.IReportDelegationService;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

/** Nhờ staff khác làm giùm task */
@RestController
@RequestMapping({ "/staff", "/api/v1/staff" })
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffDelegationController {

    IReportDelegationService delegationService;

    @PreAuthorize("hasRole('staff')")
    @GetMapping("/colleagues")
    public ResponseEntity<ApiResponse> searchColleagues(
            @RequestParam(name = "q", required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                delegationService.searchColleagues(userId(jwt), search, page, size)));
    }

    @PreAuthorize("hasRole('staff')")
    @GetMapping("/delegations/report/{reportId}")
    public ResponseEntity<ApiResponse> getReportState(
            @PathVariable String reportId,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                delegationService.getReportState(userId(jwt), reportId)));
    }

    @PreAuthorize("hasRole('staff')")
    @PostMapping("/delegations")
    public ResponseEntity<ApiResponse> create(
            @Valid @RequestBody CreateDelegationRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("delegation.created",
                delegationService.create(userId(jwt), request)));
    }

    @PreAuthorize("hasRole('staff')")
    @GetMapping("/delegations")
    public ResponseEntity<ApiResponse> list(
            @RequestParam(defaultValue = "received") String box,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("system.success",
                delegationService.list(userId(jwt), box, page, size)));
    }

    @PreAuthorize("hasRole('staff')")
    @PostMapping("/delegations/{id}/accept")
    public ResponseEntity<ApiResponse> accept(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("delegation.accepted",
                delegationService.accept(userId(jwt), id)));
    }

    @PreAuthorize("hasRole('staff')")
    @PostMapping("/delegations/{id}/decline")
    public ResponseEntity<ApiResponse> decline(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("delegation.declined",
                delegationService.decline(userId(jwt), id)));
    }

    @PreAuthorize("hasRole('staff')")
    @PostMapping("/delegations/{id}/cancel")
    public ResponseEntity<ApiResponse> cancel(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        return ResponseEntity.ok(ApiResponse.success("delegation.cancelled",
                delegationService.cancel(userId(jwt), id)));
    }

    private static String userId(Jwt jwt) {
        return jwt.getClaimAsString("userId");
    }
}
