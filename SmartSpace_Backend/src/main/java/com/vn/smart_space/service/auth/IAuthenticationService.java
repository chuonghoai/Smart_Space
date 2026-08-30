package com.vn.smart_space.service.auth;

import com.vn.smart_space.consts.ERegistrationStatus;
import com.vn.smart_space.dto.TokenPayload;
import com.vn.smart_space.dto.request.auth.GoogleLoginRequest;
import com.vn.smart_space.dto.request.auth.IntrospectRequest;
import com.vn.smart_space.dto.request.auth.LoginRequest;
import com.vn.smart_space.dto.request.auth.RefreshTokenRequest;
import com.vn.smart_space.dto.response.IntrospectResponse;
import com.vn.smart_space.dto.response.auth.LoginResponse;
import com.vn.smart_space.dto.response.auth.SessionResponse;
import com.vn.smart_space.model.User;
import java.util.List;

public interface IAuthenticationService {

    // Introspect Token
    IntrospectResponse introspect(IntrospectRequest request);

    // Login Basic
    LoginResponse loginBasic(LoginRequest request);

    // Login Google
    LoginResponse loginGoogle(GoogleLoginRequest request);

    // Refresh Token
    LoginResponse refreshToken(RefreshTokenRequest request);

    // Logout
    void logout(String token);

    // Session Management
    List<SessionResponse> getActiveSessions(String userId, String currentDeviceId);
    void revokeSession(String userId, String deviceId);
    void revokeAllOtherSessions(String userId, String currentDeviceId);

    // OTP for Registration
    void sendOtpRegister(String email);

    void verifyOtpRegister(String email, String otp);

    // OTP for Forgot Password
    void sendOtpForgotPassword(String email);

    void verifyOtpForgotPassword(String otpKey, String otp);

    void saveRefreshTokenToRedis(String userId, TokenPayload refreshToken, String deviceId, String deviceName, String platform, String ipAddress);

    ERegistrationStatus determineRegistrationStatus(User user);

}
