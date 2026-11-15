package com.vn.smart_space.controller.auth;

import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.auth.DevCreateAccountRequest;
import com.vn.smart_space.service.user.IUserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/**
 * API tiện ích chỉ dành cho môi trường phát triển local.
 *
 * <p>Bean chỉ được đăng ký khi chạy với profile {@code dev}
 * (vd: {@code SPRING_PROFILES_ACTIVE=dev}). Ở mọi profile khác endpoint
 * không tồn tại, tránh việc tạo tài khoản admin/staff bỏ qua quy trình cấp quyền.
 */
@Profile("dev")
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class DevAuthController {

        private final IUserService userService;

        // API local: create account (any role) directly without OTP
        @PostMapping("/dev-create-account")
        public ResponseEntity<ApiResponse> devCreateAccount(@RequestBody @Valid DevCreateAccountRequest request) {
                userService.devCreateAccount(request);
                return ResponseEntity.ok(ApiResponse.success("auth.dev_account.success", null));
        }
}
