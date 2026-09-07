package com.vn.smart_space.dto.request.auth;

import com.vn.smart_space.consts.ERole;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
public class LoginRequest {

    @NotBlank(message = "{auth.email.required}")
    @Email(message = "{auth.email.invalid}")
    String email;

    @NotBlank(message = "{auth.password.required}")
    @Size(min = 6, max = 50, message = "{auth.password.size}")
    String password;

    Boolean rememberMe;
    ERole role;
    
    @NotBlank(message = "{auth.deviceId.required}")
    String deviceId;
    
    String deviceName;

    @NotNull(message = "{auth.platform.required}")
    String platform;

    String language;
    String ipAddress;

}
