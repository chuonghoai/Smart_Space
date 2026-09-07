package com.vn.smart_space.dto.request.auth;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vn.smart_space.validation.StrongPassword;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RegisterRequest {
    @NotBlank(message = "{auth.email.required}")
    @Email(message = "{auth.email.invalid}")
    String email;

    com.vn.smart_space.consts.ERole role;

    @NotBlank(message = "{auth.password.required}")
    @StrongPassword
    String password;

    @NotBlank(message = "{auth.confirmPassword.required}")
    @JsonProperty("confirm_password")
    String confirmPassword;

    Boolean rememberMe;

    String language;

    @NotBlank(message = "{auth.deviceId.required}")
    String deviceId;
    
    String deviceName;
    String platform;
    String ipAddress;

}
