package com.vn.smart_space.controller.auth;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.auth.DevCreateAccountRequest;
import com.vn.smart_space.dto.request.auth.GoogleLoginRequest;
import com.vn.smart_space.dto.request.auth.LoginRequest;
import com.vn.smart_space.dto.request.auth.OtpRegisterRequest;
import com.vn.smart_space.dto.request.auth.RefreshTokenRequest;
import com.vn.smart_space.dto.request.auth.RegisterRequest;
import com.vn.smart_space.dto.request.auth.ResetPasswordRequest;
import com.vn.smart_space.dto.request.auth.VerifyOTPRegisterRequest;
import com.vn.smart_space.dto.request.user.ChangePasswordRequest;
import com.vn.smart_space.dto.request.user.UpdateProfileRequest;
import com.vn.smart_space.dto.response.auth.LoginResponse;
import com.vn.smart_space.dto.response.auth.SessionResponse;
import com.vn.smart_space.dto.response.user.UserResponse;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.user.IUserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

        private final IAuthenticationService authenticationService;
        private final IUserService userService;

        // 1. Login Basic
        @PostMapping("/login")
        public ResponseEntity<ApiResponse> login(
                @RequestBody @Valid LoginRequest request,
                HttpServletRequest httpRequest) {

                request.setIpAddress(httpRequest.getRemoteAddr());
                LoginResponse loginResponse = authenticationService.loginBasic(request);
                return ResponseEntity.ok(ApiResponse.builder()
                                .success(true)
                                .data(loginResponse)
                                .message("Login success")
                                .build());

        }

        // 2. Login Google
        @PostMapping("/login/google")
        public ResponseEntity<ApiResponse> loginGoogle(
                @RequestBody @Valid GoogleLoginRequest request,
                HttpServletRequest httpRequest) {

                request.setIpAddress(httpRequest.getRemoteAddr());
                LoginResponse loginResponse = authenticationService.loginGoogle(request);
                return ResponseEntity.ok(ApiResponse.builder()
                                .success(true)
                                .data(loginResponse)
                                .message("Login Google success")
                                .build());

        }

        // 3. Refresh Token
        @PostMapping("/refresh-token")
        public ResponseEntity<ApiResponse> refresh(
                        @RequestBody @Valid RefreshTokenRequest request) {
                LoginResponse loginResponse = authenticationService
                                .refreshToken(request);
                return ResponseEntity.ok(ApiResponse.builder()
                                .success(true)
                                .data(loginResponse)
                                .message("Refresh token success")
                                .build());
        }

        // 4. Logout
        @PostMapping("/logout")
        public ResponseEntity<ApiResponse> logout(@RequestHeader("Authorization") String authHeader) {
                String token = authHeader.replace("Bearer ", "");
                authenticationService.logout(token);
                return ResponseEntity.ok(ApiResponse.success("Logout success", null));
        }

        // 4a. Get Active Sessions
        @GetMapping("/sessions")
        public ResponseEntity<ApiResponse> getActiveSessions(
                @AuthenticationPrincipal Jwt jwt,
                @RequestParam String currentDeviceId) {
                String userId = jwt.getClaim("userId").toString();
                List<SessionResponse> sessions = authenticationService.getActiveSessions(userId, currentDeviceId);
                return ResponseEntity.ok(ApiResponse.success("Get sessions success", sessions));
        }

        // 4b. Revoke specific session
        @DeleteMapping("/sessions/{deviceId}")
        public ResponseEntity<ApiResponse> revokeSession(
                @AuthenticationPrincipal Jwt jwt,
                @PathVariable String deviceId) {
                String userId = jwt.getClaim("userId").toString();
                authenticationService.revokeSession(userId, deviceId);
                return ResponseEntity.ok(ApiResponse.success("Session revoked", null));
        }

        // 4c. Revoke all other sessions
        @DeleteMapping("/sessions")
        public ResponseEntity<ApiResponse> revokeAllOtherSessions(
                @AuthenticationPrincipal Jwt jwt,
                @RequestParam String currentDeviceId) {
                String userId = jwt.getClaim("userId").toString();
                authenticationService.revokeAllOtherSessions(userId, currentDeviceId);
                return ResponseEntity.ok(ApiResponse.success("All other sessions revoked", null));
        }

        // Get Me
        @GetMapping("/me")
        public ResponseEntity<ApiResponse> getMe(@AuthenticationPrincipal Jwt jwt) {
                UserResponse userResponse = userService.getMe(jwt.getSubject());
                return ResponseEntity.ok(ApiResponse.success("Get profile success", userResponse));
        }

        // 5. Register
        @PostMapping("/register")
        public ResponseEntity<ApiResponse> register(
                @RequestBody @Valid RegisterRequest request,
                HttpServletRequest httpRequest) {

                request.setIpAddress(httpRequest.getRemoteAddr());
                LoginResponse loginResponse = userService.createUser(request);
                return ResponseEntity.ok(ApiResponse.success("User registered successfully", loginResponse));

        }

        // 6. API FOR REGISTER PROCESS
        @PostMapping("/send-otp-register")
        public ResponseEntity<ApiResponse> sendOtpRegister(@RequestBody @Valid OtpRegisterRequest request) {

                authenticationService.sendOtpRegister(request.getEmail());
                return ResponseEntity.ok(ApiResponse.success("Send OTP register successfully", null));
        }

        @PostMapping("/verify-otp-register")
        public ResponseEntity<ApiResponse> verifyOtpRegister(@RequestBody @Valid VerifyOTPRegisterRequest request) {
                authenticationService.verifyOtpRegister(request.getEmail(), request.getOtp());
                return ResponseEntity.ok(ApiResponse.success("Verify OTP register successfully", null));
        }

        // 7. Reset Password

        @PostMapping("send-otp-forgot-password")
        public ResponseEntity<ApiResponse> sendOtpForgotPassword(@RequestBody @Valid OtpRegisterRequest request) {
                authenticationService.sendOtpForgotPassword(request.getEmail());
                return ResponseEntity.ok(ApiResponse.success("Send OTP forgot password successfully", null));
        }

        @PostMapping("/reset-password")
        public ResponseEntity<ApiResponse> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
                userService.resetPassword(request);
                return ResponseEntity.ok(ApiResponse.success("Reset password successfully", null));
        }

        // 8. Update Profile
        @PutMapping("/update-profile")
        public ResponseEntity<ApiResponse> updateProfile(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody @Valid UpdateProfileRequest request) {
                UserResponse userResponse = userService.updateProfile(jwt.getSubject(), request);
                return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", userResponse));
        }

        // 9. API local: create USER directly without otp
        @PostMapping("/dev-create-account")
        public ResponseEntity<ApiResponse> devCreateAccount(@RequestBody @Valid DevCreateAccountRequest request) {
                userService.devCreateAccount(request);
                return ResponseEntity.ok(ApiResponse.success("Developer account created successfully", null));
        }

        // Change Password
        @PutMapping("/change-password")
        public ResponseEntity<ApiResponse> changePassword(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody @Valid ChangePasswordRequest request) {
                userService.changePassword(jwt.getSubject(), request);
                return ResponseEntity.ok(ApiResponse.success("Change password successfully", null));
        }

}
