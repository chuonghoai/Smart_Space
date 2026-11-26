package com.vn.smart_space.service.auth;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.Duration;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.HashOperations;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.TokenPayload;
import com.vn.smart_space.dto.request.auth.GoogleLoginRequest;
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
class AuthenticationServiceSecurityTest {

    private static final String USER_ID = "user-1";
    private static final String EMAIL = "someone@example.com";
    private static final String BLOCKED_KEY = "blocked_user:" + USER_ID;
    private static final String GOOGLE_ID_TOKEN = "google-id-token";

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
    @Mock
    HashOperations<String, Object, Object> hashOperations;

    @InjectMocks
    AuthenticationService authenticationService;

    // ---------- helpers ----------

    private User user(ERole role, EUserStatus status) {
        User user = User.builder()
                .email(EMAIL)
                .password("hashed")
                .role(role)
                .status(status)
                .build();
        user.setId(USER_ID);
        return user;
    }

    private LoginRequest loginRequest(ERole role) {
        LoginRequest request = new LoginRequest();
        request.setEmail(EMAIL);
        request.setPassword("secret");
        request.setRole(role);
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

    private GoogleLoginRequest googleRequest(ERole role) {
        GoogleLoginRequest request = new GoogleLoginRequest();
        request.setIdToken(GOOGLE_ID_TOKEN);
        request.setDeviceId("device-1");
        request.setRole(role);
        return request;
    }

    /** Spy để bỏ qua bước gọi Google thật, trả về payload với email cố định. */
    private AuthenticationService serviceWithVerifiedGoogleToken() {
        GoogleIdToken.Payload payload = new GoogleIdToken.Payload();
        payload.setEmail(EMAIL);
        payload.set("name", "Someone");

        AuthenticationService spied = spy(authenticationService);
        doReturn(payload).when(spied).verifyGoogleIdToken(GOOGLE_ID_TOKEN);
        return spied;
    }

    private void stubTokenIssuing() {
        TokenPayload tokenPayload = TokenPayload.builder()
                .token("jwt")
                .expiryTime(new Date(System.currentTimeMillis() + 60_000))
                .build();
        when(jwtService.generateAccessToken(any(User.class), anyString())).thenReturn(tokenPayload);
        when(jwtService.generateRefreshToken(any(User.class), anyBoolean())).thenReturn(tokenPayload);
    }

    // ---------- blocked account enforcement ----------

    @Nested
    @DisplayName("Chặn tài khoản bị khóa")
    class BlockedAccount {

        // Test Case ID: SMP-274
        // Description: Từ chối đăng nhập loginBasic cho tài khoản staff bị khóa dù đúng mật khẩu và không cấp token.
        @Test
        @DisplayName("loginBasic: bị khóa + đúng mật khẩu → auth.account.blocked, không cấp token")
        void loginBasic_blocked_isRejected() {
            when(userRepository.findByEmailAndRole(EMAIL, ERole.staff))
                    .thenReturn(Optional.of(user(ERole.staff, EUserStatus.blocked)));
            when(passwordEncoder.matches("secret", "hashed")).thenReturn(true);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> authenticationService.loginBasic(loginRequest(ERole.staff)));

            assertEquals("auth.account.blocked", ex.getMessage());
            verify(jwtService, never()).generateAccessToken(any(), anyString());
        }

        // Test Case ID: SMP-275
        // Description: Trả về auth.invalid_credentials khi tài khoản admin bị khóa nhưng sai mật khẩu để tránh lộ trạng thái khóa.
        @Test
        @DisplayName("loginBasic: bị khóa + sai mật khẩu → chỉ báo sai thông tin (không lộ trạng thái)")
        void loginBasic_blockedWrongPassword_doesNotLeakStatus() {
            when(userRepository.findByEmailAndRole(EMAIL, ERole.admin))
                    .thenReturn(Optional.of(user(ERole.admin, EUserStatus.blocked)));
            when(passwordEncoder.matches("secret", "hashed")).thenReturn(false);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> authenticationService.loginBasic(loginRequest(ERole.admin)));

            assertEquals("auth.invalid_credentials", ex.getMessage());
        }

        // Test Case ID: SMP-276
        // Description: Từ chối đăng nhập loginGoogle đối với tài khoản client bị khóa với mã lỗi auth.account.blocked và không cấp token.
        @Test
        @DisplayName("loginGoogle: tài khoản tồn tại nhưng bị khóa → auth.account.blocked")
        void loginGoogle_blocked_isRejected() {
            AuthenticationService service = serviceWithVerifiedGoogleToken();
            when(userRepository.findByEmailAndRole(EMAIL, ERole.client))
                    .thenReturn(Optional.of(user(ERole.client, EUserStatus.blocked)));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.loginGoogle(googleRequest(ERole.client)));

            assertEquals("auth.account.blocked", ex.getMessage());
            verify(jwtService, never()).generateAccessToken(any(), anyString());
        }

        // Test Case ID: SMP-277
        // Description: Từ chối refreshToken khi tài khoản staff bị khóa, xóa toàn bộ phiên đăng nhập và không cấp access token mới.
        @Test
        @DisplayName("refreshToken: bị khóa → xóa mọi phiên và từ chối")
        void refreshToken_blocked_revokesSessions() {
            RefreshTokenSession session = RefreshTokenSession.builder()
                    .id(USER_ID + ":device-1").userId(USER_ID).refreshToken("rt").build();
            when(jwtService.verifyToken("rt")).thenReturn(token("refresh"));
            when(userRepository.findById(USER_ID)).thenReturn(Optional.of(user(ERole.staff, EUserStatus.blocked)));
            when(sessionRepository.findByUserId(USER_ID)).thenReturn(List.of(session));

            UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                    () -> authenticationService.refreshToken(RefreshTokenRequest.builder().refreshToken("rt").build()));

            assertEquals("auth.account.blocked", ex.getMessage());
            verify(sessionRepository).deleteAll(List.of(session));
            verify(jwtService, never()).generateAccessToken(any(), anyString());
        }

        // Test Case ID: SMP-278
        // Description: Kiểm tra introspect trả về isValid=false đối với access token của user có khóa blocked_user trong Redis.
        @Test
        @DisplayName("introspect: access token của user vừa bị khóa → không hợp lệ")
        void introspect_revokedUser_isInvalid() {
            when(jwtService.verifyToken("at")).thenReturn(token("access"));
            when(invalidatedTokenRepository.existsById("jti-1")).thenReturn(false);
            when(stringRedisTemplate.hasKey(BLOCKED_KEY)).thenReturn(true);

            assertFalse(authenticationService.introspect(IntrospectRequest.builder().token("at").build()).isValid());
        }

        // Test Case ID: SMP-279
        // Description: Kiểm tra introspect trả về isValid=true đối với access token hợp lệ của user không bị đánh dấu khóa trong Redis.
        @Test
        @DisplayName("introspect: user không bị khóa → hợp lệ")
        void introspect_activeUser_isValid() {
            when(jwtService.verifyToken("at")).thenReturn(token("access"));
            when(invalidatedTokenRepository.existsById("jti-1")).thenReturn(false);
            when(stringRedisTemplate.hasKey(BLOCKED_KEY)).thenReturn(false);

            assertTrue(authenticationService.introspect(IntrospectRequest.builder().token("at").build()).isValid());
        }

        // Test Case ID: SMP-280
        // Description: Xác minh revokeUserAccess xóa toàn bộ RefreshTokenSession của user và đặt cờ blocked_user trong Redis lâu hơn TTL access token.
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

        // Test Case ID: SMP-281
        // Description: Xác minh restoreUserAccess xóa khóa blocked_user khỏi Redis cho user tương ứng.
        @Test
        @DisplayName("restoreUserAccess: gỡ cờ chặn")
        void restoreUserAccess_removesMarker() {
            authenticationService.restoreUserAccess(USER_ID);

            verify(stringRedisTemplate).delete(BLOCKED_KEY);
        }
    }

    // ---------- Google login provisioning ----------

    @Nested
    @DisplayName("Google login chỉ tự tạo tài khoản client")
    class GoogleProvisioning {

        // Test Case ID: SMP-282
        // Description: Từ chối loginGoogle với tài khoản admin/staff chưa được cấp trước (auth.account.not_provisioned), không tự tạo user hay cấp token.
        @ParameterizedTest
        @EnumSource(value = ERole.class, names = { "admin", "staff" })
        @DisplayName("admin/staff chưa được cấp → auth.account.not_provisioned, không tạo user")
        void loginGoogle_unprovisionedPrivilegedRole_isRejected(ERole role) {
            AuthenticationService service = serviceWithVerifiedGoogleToken();
            when(userRepository.findByEmailAndRole(EMAIL, role)).thenReturn(Optional.empty());

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.loginGoogle(googleRequest(role)));

            assertEquals("auth.account.not_provisioned", ex.getMessage());
            verify(userRepository, never()).save(any());
            verifyNoInteractions(jwtService);
        }

        // Test Case ID: SMP-283
        // Description: Cho phép loginGoogle thành công đối với tài khoản staff active đã được cấp sẵn mà không gọi save user mới.
        @Test
        @DisplayName("staff đã được cấp tài khoản → đăng nhập bình thường")
        void loginGoogle_provisionedStaff_succeeds() {
            AuthenticationService service = serviceWithVerifiedGoogleToken();
            when(userRepository.findByEmailAndRole(EMAIL, ERole.staff))
                    .thenReturn(Optional.of(user(ERole.staff, EUserStatus.active)));
            stubTokenIssuing();

            assertNotNull(service.loginGoogle(googleRequest(ERole.staff)));
            verify(userRepository, never()).save(any());
        }

        // Test Case ID: SMP-284
        // Description: Tự động tạo tài khoản mới với role client và status active khi user chưa tồn tại đăng nhập qua loginGoogle.
        @Test
        @DisplayName("client mới → tự tạo tài khoản với role client")
        void loginGoogle_newClient_isCreated() {
            AuthenticationService service = serviceWithVerifiedGoogleToken();
            when(userRepository.findByEmailAndRole(EMAIL, ERole.client)).thenReturn(Optional.empty());
            when(userRepository.save(any(User.class))).thenAnswer(inv -> {
                User saved = inv.getArgument(0);
                saved.setId(USER_ID);
                return saved;
            });
            stubTokenIssuing();

            assertNotNull(service.loginGoogle(googleRequest(ERole.client)));

            ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
            verify(userRepository).save(captor.capture());
            assertEquals(ERole.client, captor.getValue().getRole());
            assertEquals(EUserStatus.active, captor.getValue().getStatus());
        }
    }

    // ---------- Self-registration role guard ----------

    @Nested
    @DisplayName("Đăng ký public chỉ dành cho client")
    class SelfRegistration {

        // Test Case ID: SMP-285
        // Description: Từ chối sendOtpRegister với vai trò đặc quyền admin và staff (auth.role.invalid) trước khi gọi mailService, Redis hoặc DB.
        @ParameterizedTest
        @EnumSource(value = ERole.class, names = { "admin", "staff" })
        @DisplayName("sendOtpRegister với admin/staff → auth.role.invalid, không gửi mail")
        void sendOtpRegister_privilegedRole_isRejectedBeforeMail(ERole role) {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> authenticationService.sendOtpRegister(EMAIL, role));

            assertEquals("auth.role.invalid", ex.getMessage());
            verifyNoInteractions(mailService, stringRedisTemplate, userRepository);
        }

        // Test Case ID: SMP-286
        // Description: Từ chối verifyOtpRegister với vai trò đặc quyền admin và staff (auth.role.invalid) và không tương tác Redis.
        @ParameterizedTest
        @EnumSource(value = ERole.class, names = { "admin", "staff" })
        @DisplayName("verifyOtpRegister với admin/staff → auth.role.invalid, không đánh dấu verified")
        void verifyOtpRegister_privilegedRole_isRejected(ERole role) {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> authenticationService.verifyOtpRegister(EMAIL, "123456", role));

            assertEquals("auth.role.invalid", ex.getMessage());
            verifyNoInteractions(stringRedisTemplate);
        }

        // Test Case ID: SMP-287
        // Description: Từ chối vai trò null trong assertSelfRegistrableRole với BadRequestException chứa mã lỗi auth.role.invalid.
        @Test
        @DisplayName("assertSelfRegistrableRole: role null → auth.role.invalid")
        void assertSelfRegistrableRole_null_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> authenticationService.assertSelfRegistrableRole(null));

            assertEquals("auth.role.invalid", ex.getMessage());
        }

        // Test Case ID: SMP-288
        // Description: Cho phép vai trò ERole.client vượt qua kiểm tra assertSelfRegistrableRole mà không ném ngoại lệ.
        @Test
        @DisplayName("assertSelfRegistrableRole: client → hợp lệ")
        void assertSelfRegistrableRole_client_passes() {
            assertDoesNotThrow(() -> authenticationService.assertSelfRegistrableRole(ERole.client));
        }

        // Test Case ID: SMP-289
        // Description: Thực hiện gửi email OTP thành công khi gọi sendOtpRegister với vai trò client hợp lệ, chưa tồn tại và không đang cooldown.
        @Test
        @DisplayName("sendOtpRegister với client → tiếp tục luồng gửi OTP")
        void sendOtpRegister_client_sendsOtp() {
            when(userRepository.existsByEmailAndRole(EMAIL, ERole.client)).thenReturn(false);
            when(stringRedisTemplate.hasKey("cooldown:otp:" + EMAIL + ":client")).thenReturn(false);
            when(stringRedisTemplate.<Object, Object>opsForHash()).thenReturn(hashOperations);
            when(stringRedisTemplate.opsForValue()).thenReturn(valueOperations);

            authenticationService.sendOtpRegister(EMAIL, ERole.client);

            verify(mailService).sendOtpEmail(anyString(), anyString());
        }
    }
}
