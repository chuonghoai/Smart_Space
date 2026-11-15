package com.vn.smart_space.controller.admin;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.AccountLockVoteRequest;
import com.vn.smart_space.dto.request.admin.CreateAccountLockRequest;
import com.vn.smart_space.service.admin.IAccountLockRequestService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Hội đồng quản trị — đề xuất & biểu quyết khóa tài khoản người dùng. */
@RestController
@RequestMapping("/admin/lock-requests")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AccountLockRequestController {

        IAccountLockRequestService lockRequestService;

        @PreAuthorize("hasRole('admin')")
        @PostMapping
        public ResponseEntity<ApiResponse> create(
                        @RequestBody @Valid CreateAccountLockRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("lock_request.create.success",
                                lockRequestService.create(request, adminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping
        public ResponseEntity<ApiResponse> list(
                        @RequestParam(defaultValue = "all") String status,
                        @RequestParam(defaultValue = "1") int page,
                        @RequestParam(defaultValue = "10") int size,
                        @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("system.success",
                                lockRequestService.list(status, page, size, adminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/pending-count")
        public ResponseEntity<ApiResponse> pendingCount(@AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("system.success",
                                lockRequestService.getPendingCount(adminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @GetMapping("/{id}")
        public ResponseEntity<ApiResponse> detail(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("system.success",
                                lockRequestService.getDetail(id, adminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @PostMapping("/{id}/votes")
        public ResponseEntity<ApiResponse> vote(
                        @PathVariable String id,
                        @RequestBody @Valid AccountLockVoteRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("lock_request.vote.success",
                                lockRequestService.vote(id, request, adminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @PostMapping("/{id}/cancel")
        public ResponseEntity<ApiResponse> cancel(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("lock_request.cancel.success",
                                lockRequestService.cancel(id, adminId(jwt))));
        }

        private static String adminId(Jwt jwt) {
                return jwt != null ? jwt.getClaimAsString("userId") : null;
        }
}
