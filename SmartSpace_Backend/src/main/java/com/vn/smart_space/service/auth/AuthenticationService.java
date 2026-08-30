package com.vn.smart_space.service.auth;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.text.ParseException;
import java.time.Duration;
import java.util.Collections;
import java.util.Date;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.nimbusds.jwt.SignedJWT;
import com.vn.smart_space.consts.ERegistrationStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.JwtInfo;
import com.vn.smart_space.dto.TokenPayload;
import com.vn.smart_space.dto.request.auth.GoogleLoginRequest;
import com.vn.smart_space.dto.request.auth.IntrospectRequest;
import com.vn.smart_space.dto.request.auth.LoginRequest;
import com.vn.smart_space.dto.request.auth.RefreshTokenRequest;
import com.vn.smart_space.dto.response.IntrospectResponse;
import com.vn.smart_space.dto.response.auth.LoginResponse;
import com.vn.smart_space.dto.response.auth.SessionResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.UnauthorizedException;
import com.vn.smart_space.mapper.UserMapper;
import com.vn.smart_space.model.InvalidatedToken;
import com.vn.smart_space.model.RefreshTokenSession;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.InvalidatedTokenRepository;
import com.vn.smart_space.repository.RefreshTokenSessionRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.jwt.IJwtService;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.utils.OtpGenerator;

import lombok.RequiredArgsConstructor;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AuthenticationService implements IAuthenticationService {

    private final UserRepository userRepository;
    private final InvalidatedTokenRepository invalidatedTokenRepository;
    private final RefreshTokenSessionRepository sessionRepository;

    private final IJwtService jwtService;
    private final IMailService mailService;

    private final PasswordEncoder passwordEncoder;

    private final StringRedisTemplate stringRedisTemplate;

    private final UserMapper userMapper;

    @Value("${google.client-id}")
    private String googleClientId;

    // Introspect Token
    @Override
    public IntrospectResponse introspect(IntrospectRequest request) {
        var token = request.getToken();
        boolean isValid = true;
        try {
            var signedJWT = jwtService.verifyToken(token);

            // Check blacklist
            String jwtId = signedJWT.getJWTClaimsSet().getJWTID();
            if (invalidatedTokenRepository.existsById(jwtId)) {
                isValid = false;
            }
        } catch (Exception e) {
            isValid = false;
        }
        return IntrospectResponse.builder()
                .valid(isValid)
                .build();

    }

    // Login Basic
    @Override
    public LoginResponse loginBasic(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("Email hoặc mật khẩu không chính xác"));

        boolean isPasswordMatch = passwordEncoder.matches(request.getPassword(), user.getPassword());
        if (!isPasswordMatch) {
            throw new BadRequestException("Email hoặc mật khẩu không chính xác");
        }

        // Generate Access Token
        TokenPayload accessToken = jwtService.generateAccessToken(user, request.getDeviceId());

        // Generate Refresh Token
        boolean rememberMe = Boolean.TRUE.equals(request.getRememberMe());
        TokenPayload refreshToken = jwtService.generateRefreshToken(user, rememberMe);

        saveRefreshTokenToRedis(
            user.getId(), refreshToken,
            request.getDeviceId(),
            request.getDeviceName(),
            request.getPlatform(),
            request.getIpAddress()
        );

        return LoginResponse.builder()
                .accessToken(accessToken.getToken())
                .refreshToken(refreshToken.getToken())
                .registrationStatus(determineRegistrationStatus(user))
                .user(userMapper.toUserResponse(user))
                .build();
    }

    // Login Google
    @Override
    @Transactional
    public LoginResponse loginGoogle(GoogleLoginRequest request) {
        // Verify Google ID Token
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(),
                GsonFactory.getDefaultInstance())
                .setAudience(Collections.singletonList(googleClientId))
                .build();

        GoogleIdToken idToken;
        try {
            idToken = verifier.verify(request.getIdToken());
        } catch (GeneralSecurityException | IOException e) {
            throw new BadRequestException("Google token không hợp lệ");
        }

        if (idToken == null) {
            throw new BadRequestException("Google token không hợp lệ hoặc đã hết hạn");
        }

        // Extract info user
        GoogleIdToken.Payload payload = idToken.getPayload();
        String email = payload.getEmail();
        String fullName = (String) payload.get("name");

        // Find or create User
        User user = userRepository.findByEmail(email)
                .orElseGet(() -> {
                    User newUser = User.builder()
                            .email(email)
                            .fullName(fullName != null ? fullName : email.split("@")[0])
                            .role(ERole.client)
                            .status(EUserStatus.active)
                            .build();
                    return userRepository.save(newUser);
                });

        // Generate JWT tokens
        TokenPayload accessToken = jwtService.generateAccessToken(user, request.getDeviceId());
        TokenPayload refreshToken = jwtService.generateRefreshToken(user, true);
        
        saveRefreshTokenToRedis(
            user.getId(), refreshToken,
            request.getDeviceId(),
            request.getDeviceName(),
            request.getPlatform(),
            request.getIpAddress()
        );

        return LoginResponse.builder()
                .accessToken(accessToken.getToken())
                .refreshToken(refreshToken.getToken())
                .registrationStatus(determineRegistrationStatus(user))
                .user(userMapper.toUserResponse(user))
                .build();
    }

    // Logout
    @Override
    @Transactional
    public void logout(String token) {
        JwtInfo jwtInfo = jwtService.parseToken(token);

        Date expiryTime = jwtInfo.getExpiryTime();
        if (expiryTime.before(new Date())) {
            return;
        }

        // Set TTL
        long ttlSeconds = (expiryTime.getTime() - System.currentTimeMillis()) / 1000;

        invalidatedTokenRepository.save(InvalidatedToken.builder()
                .id(jwtInfo.getJwtId())
                .ttl(ttlSeconds)
                .build());

        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            String email = signedJWT.getJWTClaimsSet().getSubject();
            String deviceId = (String) signedJWT.getJWTClaimsSet().getClaim("deviceId");
            
            userRepository.findByEmail(email).ifPresent(user -> {
                if (deviceId != null) {
                    revokeSession(user.getId(), deviceId);
                }
            });
        } catch (ParseException e) {
            // Access token đã blacklist
        }
    }

    // Refresh Token
    @Override
    @Transactional
    public LoginResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();

        SignedJWT signedJWT = jwtService.verifyToken(refreshToken);
        try {
            // Check refresh Token
            String tokenType = (String) signedJWT.getJWTClaimsSet()
                    .getClaim("tokenType");

            if (!"refresh".equals(tokenType)) {
                throw new UnauthorizedException("Token không hợp lệ");
            }

            String email = signedJWT.getJWTClaimsSet().getSubject();
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new UnauthorizedException(
                            "User không tồn tại"));

            List<RefreshTokenSession> sessions = sessionRepository.findByUserId(user.getId());
            RefreshTokenSession currentSession = sessions.stream()
                .filter(s -> s.getRefreshToken().equals(refreshToken))
                .findFirst()
                .orElseThrow(() -> new UnauthorizedException("Refresh token đã bị thu hồi hoặc không hợp lệ trên thiết bị này"));

            TokenPayload newAccessToken = jwtService
                    .generateAccessToken(user, currentSession.getDeviceId());

            Boolean rememberMe = (Boolean) signedJWT.getJWTClaimsSet().getClaim("rememberMe");
            boolean isRememberMe = Boolean.TRUE.equals(rememberMe);
            TokenPayload newRefreshToken = jwtService
                    .generateRefreshToken(user, isRememberMe);

            saveRefreshTokenToRedis(
                user.getId(), newRefreshToken,
                currentSession.getDeviceId(),
                currentSession.getDeviceName(),
                currentSession.getPlatform(),
                currentSession.getIpAddress()
            );
            
            return LoginResponse.builder()
                    .accessToken(newAccessToken.getToken())
                    .refreshToken(newRefreshToken.getToken())
                    .registrationStatus(determineRegistrationStatus(user))
                    .user(userMapper.toUserResponse(user))
                    .build();
        } catch (ParseException e) {
            throw new UnauthorizedException("Token không hợp lệ");
        }
    }

    @Override
    public List<SessionResponse> getActiveSessions(String userId, String currentDeviceId) {
        List<RefreshTokenSession> sessions = sessionRepository.findByUserId(userId);
        return sessions.stream().map(s -> SessionResponse.builder()
                .sessionId(s.getDeviceId())
                .deviceName(s.getDeviceName())
                .platform(s.getPlatform())
                .ipAddress(s.getIpAddress())
                .currentDevice(s.getDeviceId().equals(currentDeviceId))
                .lastActiveAt(s.getLastActiveAt())
                .build()
        ).toList();
    }

    @Override
    @Transactional
    public void revokeSession(String userId, String deviceId) {
        String key = userId + ":" + deviceId;
        sessionRepository.deleteById(key);
    }

    @Override
    @Transactional
    public void revokeAllOtherSessions(String userId, String currentDeviceId) {
        List<RefreshTokenSession> sessions = sessionRepository.findByUserId(userId);
        sessions.stream()
            .filter(s -> !s.getDeviceId().equals(currentDeviceId))
            .forEach(s -> sessionRepository.deleteById(s.getId()));
    }

    // SEND OTP FOR REGISTRATION
    @Override
    @Transactional
    public void sendOtpRegister(String email) {
        if (userRepository.findByEmail(email).isPresent()) {
            throw new BadRequestException("Email đã tồn tại trong hệ thống");
        }
        sendOtp(email, "otp:register:", "cooldown:otp:");
    }

    // Send OTP Forgot password
    @Override
    public void sendOtpForgotPassword(String email) {
        if (userRepository.findByEmail(email).isEmpty()) {
            throw new BadRequestException("Email không tồn tại trong hệ thống");
        }
        sendOtp(email, "otp:forgot_password:", "cooldown:otp_forgot:");
    }

    @Override
    @Transactional
    public void verifyOtpRegister(String email, String otp) {

        String otpKey = "otp:register:" + email;
        verifyOtp(otpKey, otp);

        String verifiedKey = "otp_verified:register:" + email;
        stringRedisTemplate.opsForValue().set(verifiedKey, "true", Duration.ofMinutes(10));

    }

    @Override
    public void verifyOtpForgotPassword(String otpKey, String otp) {
        verifyOtp(otpKey, otp);
    }

    @Override
    public void saveRefreshTokenToRedis(
            String userId, TokenPayload refreshToken,
            String deviceId, String deviceName,
            String platform, String ipAddress) {
            
        long ttlSeconds = (refreshToken.getExpiryTime().getTime()
                - System.currentTimeMillis()) / 1000;

        String key = userId + ":" + deviceId;

        sessionRepository.save(RefreshTokenSession.builder()
                .id(key)
                .userId(userId)
                .deviceId(deviceId)
                .refreshToken(refreshToken.getToken())
                .deviceName(deviceName)
                .platform(platform)
                .ipAddress(ipAddress)
                .lastActiveAt(System.currentTimeMillis())
                .ttl(ttlSeconds)
                .build());
    }

    @Override
    public ERegistrationStatus determineRegistrationStatus(User user) {
        if (user.getPhone() != null && !user.getPhone().isBlank()
            && user.getFullName() != null && !user.getFullName().isBlank()) {
            return ERegistrationStatus.complete;
        }
        return ERegistrationStatus.incomplete;
    }

    private void sendOtp(String email, String otpKeyPrefix, String cooldownKeyPrefix) {
        String cooldownKey = cooldownKeyPrefix + email;
        if (Boolean.TRUE.equals(stringRedisTemplate.hasKey(cooldownKey))) {
            throw new BadRequestException("Vui lòng đợi 60 giây trước khi gửi lại OTP");
        }

        String otp = OtpGenerator.generateOtp();
        // Save OTP to Redis
        String otpKey = otpKeyPrefix + email;
        Map<String, String> otpData = Map.of(
                "otp", otp,
                "attempts", "0");
        stringRedisTemplate.opsForHash().putAll(otpKey, otpData);
        stringRedisTemplate.expire(otpKey, Duration.ofMinutes(5));
        // Set cooldown 60s
        stringRedisTemplate.opsForValue().set(cooldownKey, "1", Duration.ofSeconds(60));
        // Send OTP email
        mailService.sendOtpEmail(email, otp);
    }

    private void verifyOtp(String otpKey, String otp) {
        // Check OTP is exists
        Boolean exists = stringRedisTemplate.hasKey(otpKey);

        if (!Boolean.TRUE.equals(exists)) {
            throw new BadRequestException(
                    "OTP không tồn tại hoặc đã hết hạn");
        }

        // Get Data OTP Redis
        Map<Object, Object> otpData = stringRedisTemplate.opsForHash().entries(otpKey);

        String savedOtp = (String) otpData.get("otp");
        String savedAttempts = (String) otpData.get("attempts");

        if (savedOtp == null || savedAttempts == null) {
            stringRedisTemplate.delete(otpKey);

            throw new BadRequestException(
                    "Dữ liệu OTP không hợp lệ");
        }

        int attempts = Integer.parseInt(savedAttempts);
        if (attempts >= 5) {
            stringRedisTemplate.delete(otpKey);

            throw new BadRequestException(
                    "Bạn đã nhập sai OTP quá 5 lần. "
                            + "Vui lòng lấy OTP mới");
        }

        // OTP Not Match
        if (!savedOtp.equals(otp)) {

            Long newAttempts = stringRedisTemplate
                    .opsForHash()
                    .increment(
                            otpKey,
                            "attempts",
                            1);

            int attemptsAfter = newAttempts != null
                    ? newAttempts.intValue()
                    : attempts + 1;

            if (attemptsAfter >= 5) {
                stringRedisTemplate.delete(otpKey);

                throw new BadRequestException(
                        "Bạn đã nhập sai OTP quá 5 lần. "
                                + "Vui lòng lấy OTP mới");
            }

            int remaining = 5 - attemptsAfter;

            throw new BadRequestException(
                    "OTP không chính xác. Còn "
                            + remaining
                            + " lần thử");
        }

        // OTP Match
        stringRedisTemplate.delete(otpKey);
    }

}
