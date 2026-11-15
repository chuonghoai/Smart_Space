package com.vn.smart_space.service.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verifyNoInteractions;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.auth.RegisterRequest;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.mapper.UserMapper;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.jwt.IJwtService;

@ExtendWith(MockitoExtension.class)
class UserServiceRegisterRoleTest {

    @Mock
    IAuthenticationService authenticationService;
    @Mock
    IJwtService jwtService;
    @Mock
    UserRepository userRepository;
    @Mock
    ActivityHistoryRepository activityHistoryRepository;
    @Mock
    PasswordEncoder passwordEncoder;
    @Mock
    StringRedisTemplate stringRedisTemplate;
    @Mock
    UserMapper userMapper;

    @InjectMocks
    UserService userService;

    @ParameterizedTest
    @EnumSource(value = ERole.class, names = { "admin", "staff" })
    @DisplayName("createUser với admin/staff → bị chặn trước khi chạm DB/Redis")
    void createUser_privilegedRole_isRejectedBeforeAnySideEffect(ERole role) {
        RegisterRequest request = new RegisterRequest();
        request.setEmail("someone@example.com");
        request.setRole(role);
        request.setPassword("Secret123!");
        request.setConfirmPassword("Secret123!");
        doThrow(new BadRequestException("auth.role.invalid"))
                .when(authenticationService).assertSelfRegistrableRole(role);

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> userService.createUser(request));

        assertEquals("auth.role.invalid", ex.getMessage());
        verifyNoInteractions(userRepository, stringRedisTemplate, passwordEncoder, activityHistoryRepository);
    }
}
