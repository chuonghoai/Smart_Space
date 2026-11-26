package com.vn.smart_space.controller.admin;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.admin.CreateAdminRequest;
import com.vn.smart_space.dto.request.admin.UpdateAdminStatusRequest;
import com.vn.smart_space.service.admin.IAdminAccountService;

import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Hội đồng quản trị — quản lý tài khoản quản trị viên. Mọi admin ngang quyền. */
@RestController
@RequestMapping("/admin/admins")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminAccountController {

        IAdminAccountService adminAccountService;

        @PreAuthorize("hasRole('admin')")
        @GetMapping
        public ResponseEntity<ApiResponse> getAdmins(
                        @RequestParam(defaultValue = "1") int page,
                        @RequestParam(defaultValue = "10") int size,
                        @RequestParam(required = false) String search,
                        @RequestParam(required = false) String status,
                        @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("system.success",
                                adminAccountService.getAdmins(page, size, search, status, currentAdminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @PostMapping
        public ResponseEntity<ApiResponse> createAdmin(
                        @RequestBody @Valid CreateAdminRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                return ResponseEntity.ok(ApiResponse.success("admin.account.create.success",
                                adminAccountService.createAdmin(request, currentAdminId(jwt))));
        }

        @PreAuthorize("hasRole('admin')")
        @PutMapping("/{id}/status")
        public ResponseEntity<ApiResponse> updateAdminStatus(
                        @PathVariable String id,
                        @RequestBody @Valid UpdateAdminStatusRequest request,
                        @AuthenticationPrincipal Jwt jwt) {
                adminAccountService.updateAdminStatus(id, request, currentAdminId(jwt));
                return ResponseEntity.ok(ApiResponse.success("admin.account.status.success", null));
        }

        private static String currentAdminId(Jwt jwt) {
                return jwt != null ? jwt.getClaimAsString("userId") : null;
        }
}
