package com.vn.smart_space.service.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Duration;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.auth.IntrospectRequest;
import com.vn.smart_space.dto.request.auth.LoginRequest;
import com.vn.smart_space.dto.request.auth.RefreshTokenRequest;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.UnauthorizedException;
import com.vn.smart_space.mapper.UserMapper;
import com.vn.smart_space.model.RefreshTokenSession;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.InvalidatedTokenRepository;
import com.vn.smart_space.repository.RefreshTokenSessionRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.jwt.IJwtService;
import com.vn.smart_space.service.jwt.JwtService;
import com.vn.smart_space.service.mail.IMailService;

@ExtendWith(MockitoExtension.class)
class AuthenticationServiceBlockedAccountTest {

    private static final String USER_ID = "user-1";
    private static final String BLOCKED_KEY = "blocked_user:" + USER_ID;

    @Mock
    UserRepository userRepository;
    @Mock
    InvalidatedTokenRepository invalidatedTokenRepository;
    @Mock
    RefreshTokenSessionRepository sessionRepository;
    @Mock
    IJwtService jwtService;
    @Mock
    IMailService mailService;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    StringRedisTemplate stringRedisTemplate;
    @Mock
    UserMapper userMapper;
    @Mock
    ValueOperations<String, String> valueOperations;

    @InjectMocks
    AuthenticationService authenticationService;

    private User staff(EUserStatus status) {
        User user = User.builder()
                .email("staff@example.com")
                .password("hashed")
                .role(ERole.staff)
                .status(status)
                .build();
        user.setId(USER_ID);
        return user;
    }

    private LoginRequest loginRequest() {
        LoginRequest request = new LoginRequest();
        request.setEmail("staff@example.com");
        request.setPassword("secret");
        request.setRole(ERole.staff);
        request.setDeviceId("device-1");
        return request;
    }

    private SignedJWT token(String tokenType) {
        JWTClaimsSet claims = new JWTClaimsSet.Builder()
                .jwtID("jti-1")
                .claim("userId", USER_ID)
                .claim("tokenType", tokenType)
                .build();
        return new SignedJWT(new JWSHeader(JWSAlgorithm.HS512), claims);
    }

    @Test
    @DisplayName("loginBasic: tài khoản bị khóa + đúng mật khẩu → auth.account.blocked, không cấp token")
    void loginBasic_blockedAccount_isRejected() {
        when(userRepository.findByEmailAndRole("staff@example.com", ERole.staff))
                .thenReturn(Optional.of(staff(EUserStatus.blocked)));
        when(passwordEncoder.matches("secret", "hashed")).thenReturn(true);

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> authenticationService.loginBasic(loginRequest()));

        assertEquals("auth.account.blocked", ex.getMessage());
        verify(jwtService, never()).generateAccessToken(any(), anyString());
    }

    @Test
    @DisplayName("loginBasic: tài khoản bị khóa + sai mật khẩu → vẫn chỉ báo sai thông tin (không lộ trạng thái)")
    void loginBasic_blockedAccountWrongPassword_doesNotLeakStatus() {
        when(userRepository.findByEmailAndRole("staff@example.com", ERole.staff))
                .thenReturn(Optional.of(staff(EUserStatus.blocked)));
        when(passwordEncoder.matches("secret", "hashed")).thenReturn(false);

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> authenticationService.loginBasic(loginRequest()));

        assertEquals("auth.invalid_credentials", ex.getMessage());
    }

    @Test
    @DisplayName("refreshToken: tài khoản bị khóa → xóa mọi phiên và từ chối")
    void refreshToken_blockedAccount_revokesSessions() {
        RefreshTokenSession session = RefreshTokenSession.builder()
                .id(USER_ID + ":device-1").userId(USER_ID).refreshToken("rt").build();
        when(jwtService.verifyToken("rt")).thenReturn(token("refresh"));
        when(userRepository.findById(USER_ID)).thenReturn(Optional.of(staff(EUserStatus.blocked)));
        when(sessionRepository.findByUserId(USER_ID)).thenReturn(List.of(session));

        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                () -> authenticationService.refreshToken(RefreshTokenRequest.builder().refreshToken("rt").build()));

        assertEquals("auth.account.blocked", ex.getMessage());
        verify(sessionRepository).deleteAll(List.of(session));
        verify(jwtService, never()).generateAccessToken(any(), anyString());
    }

    @Test
    @DisplayName("introspect: access token của user vừa bị khóa → không hợp lệ")
    void introspect_revokedUser_isInvalid() {
        when(jwtService.verifyToken("at")).thenReturn(token("access"));
        when(invalidatedTokenRepository.existsById("jti-1")).thenReturn(false);
        when(stringRedisTemplate.hasKey(BLOCKED_KEY)).thenReturn(true);

        assertFalse(authenticationService.introspect(IntrospectRequest.builder().token("at").build()).isValid());
    }

    @Test
    @DisplayName("introspect: user không bị khóa → hợp lệ")
    void introspect_activeUser_isValid() {
        when(jwtService.verifyToken("at")).thenReturn(token("access"));
        when(invalidatedTokenRepository.existsById("jti-1")).thenReturn(false);
        when(stringRedisTemplate.hasKey(BLOCKED_KEY)).thenReturn(false);

        assertTrue(authenticationService.introspect(IntrospectRequest.builder().token("at").build()).isValid());
    }

    @Test
    @DisplayName("revokeUserAccess: xóa mọi phiên + đặt cờ chặn sống lâu hơn access token")
    void revokeUserAccess_deletesSessionsAndSetsMarker() {
        List<RefreshTokenSession> sessions = List.of(RefreshTokenSession.builder().id(USER_ID + ":d").build());
        when(sessionRepository.findByUserId(USER_ID)).thenReturn(sessions);
        when(stringRedisTemplate.opsForValue()).thenReturn(valueOperations);

        authenticationService.revokeUserAccess(USER_ID);

        verify(sessionRepository).deleteAll(sessions);
        verify(valueOperations).set(BLOCKED_KEY, "1",
                Duration.ofMinutes(JwtService.ACCESS_TOKEN_TTL_MINUTES + 1));
    }

    @Test
    @DisplayName("restoreUserAccess: gỡ cờ chặn")
    void restoreUserAccess_removesMarker() {
        authenticationService.restoreUserAccess(USER_ID);

        verify(stringRedisTemplate).delete(BLOCKED_KEY);
    }
}
