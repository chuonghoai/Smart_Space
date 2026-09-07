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
                                .message("auth.login.success")
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
                                .message("auth.login_google.success")
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
                                .message("auth.refresh_token.success")
                                .build());
        }

        // 4. Logout
        @PostMapping("/logout")
        public ResponseEntity<ApiResponse> logout(@RequestHeader("Authorization") String authHeader) {
                String token = authHeader.replace("Bearer ", "");
                authenticationService.logout(token);
                return ResponseEntity.ok(ApiResponse.success("auth.logout.success", null));
        }

        // 4a. Get Active Sessions
        @GetMapping("/sessions")
        public ResponseEntity<ApiResponse> getActiveSessions(
                @AuthenticationPrincipal Jwt jwt,
                @RequestParam String currentDeviceId) {
                String userId = jwt.getClaim("userId").toString();
                List<SessionResponse> sessions = authenticationService.getActiveSessions(userId, currentDeviceId);
                return ResponseEntity.ok(ApiResponse.success("auth.sessions.get.success", sessions));
        }

        // 4b. Revoke specific session
        @DeleteMapping("/sessions/{deviceId}")
        public ResponseEntity<ApiResponse> revokeSession(
                @AuthenticationPrincipal Jwt jwt,
                @PathVariable String deviceId) {
                String userId = jwt.getClaim("userId").toString();
                authenticationService.revokeSession(userId, deviceId);
                return ResponseEntity.ok(ApiResponse.success("auth.sessions.revoke.success", null));
        }

        // 4c. Revoke all other sessions
        @DeleteMapping("/sessions")
        public ResponseEntity<ApiResponse> revokeAllOtherSessions(
                @AuthenticationPrincipal Jwt jwt,
                @RequestParam String currentDeviceId) {
                String userId = jwt.getClaim("userId").toString();
                authenticationService.revokeAllOtherSessions(userId, currentDeviceId);
                return ResponseEntity.ok(ApiResponse.success("auth.sessions.revoke_all.success", null));
        }

        // Get Me
        @GetMapping("/me")
        public ResponseEntity<ApiResponse> getMe(@AuthenticationPrincipal Jwt jwt) {
                UserResponse userResponse = userService.getMe(jwt.getClaim("userId").toString());
                return ResponseEntity.ok(ApiResponse.success("user.profile.get.success", userResponse));
        }

        // 5. Register
        @PostMapping("/register")
        public ResponseEntity<ApiResponse> register(
                @RequestBody @Valid RegisterRequest request,
                HttpServletRequest httpRequest) {

                request.setIpAddress(httpRequest.getRemoteAddr());
                LoginResponse loginResponse = userService.createUser(request);
                return ResponseEntity.ok(ApiResponse.success("auth.register.success", loginResponse));

        }

        // 6. API FOR REGISTER PROCESS
        @PostMapping("/send-otp-register")
        public ResponseEntity<ApiResponse> sendOtpRegister(@RequestBody @Valid OtpRegisterRequest request) {

                authenticationService.sendOtpRegister(request.getEmail(), request.getRole());
                return ResponseEntity.ok(ApiResponse.success("auth.otp.register.send.success", null));
        }

        @PostMapping("/verify-otp-register")
        public ResponseEntity<ApiResponse> verifyOtpRegister(@RequestBody @Valid VerifyOTPRegisterRequest request) {
                authenticationService.verifyOtpRegister(request.getEmail(), request.getOtp(), request.getRole());
                return ResponseEntity.ok(ApiResponse.success("auth.otp.register.verify.success", null));
        }

        // 7. Reset Password

        @PostMapping("send-otp-forgot-password")
        public ResponseEntity<ApiResponse> sendOtpForgotPassword(@RequestBody @Valid com.vn.smart_space.dto.request.auth.SendOtpForgotPasswordRequest request) {
                authenticationService.sendOtpForgotPassword(request.getEmail());
                return ResponseEntity.ok(ApiResponse.success("auth.otp.forgot_password.send.success", null));
        }

        @PostMapping("/reset-password")
        public ResponseEntity<ApiResponse> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
                userService.resetPassword(request);
                return ResponseEntity.ok(ApiResponse.success("auth.reset_password.success", null));
        }

        // 8. Update Profile
        @PutMapping("/update-profile")
        public ResponseEntity<ApiResponse> updateProfile(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody @Valid UpdateProfileRequest request) {
                UserResponse userResponse = userService.updateProfile(jwt.getClaim("userId").toString(), request);
                return ResponseEntity.ok(ApiResponse.success("user.profile.update.success", userResponse));
        }

        // 9. API local: create USER directly without otp
        @PostMapping("/dev-create-account")
        public ResponseEntity<ApiResponse> devCreateAccount(@RequestBody @Valid DevCreateAccountRequest request) {
                userService.devCreateAccount(request);
                return ResponseEntity.ok(ApiResponse.success("auth.dev_account.success", null));
        }

        // Change Password
        @PutMapping("/change-password")
        public ResponseEntity<ApiResponse> changePassword(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody @Valid ChangePasswordRequest request) {
                userService.changePassword(jwt.getClaim("userId").toString(), request);
                return ResponseEntity.ok(ApiResponse.success("user.password.change.success", null));
        }

}
