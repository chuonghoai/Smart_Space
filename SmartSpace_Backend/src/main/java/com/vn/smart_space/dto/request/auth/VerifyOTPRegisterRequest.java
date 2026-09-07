package com.vn.smart_space.dto.request.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import lombok.experimental.FieldDefaults;

@Getter
@Setter
@FieldDefaults(level = AccessLevel.PRIVATE)
public class VerifyOTPRegisterRequest {

    @NotBlank(message = "{auth.email.required}")
    @Email(message = "{auth.email.invalid}")
    String email;

    com.vn.smart_space.consts.ERole role;

    @NotBlank(message = "{auth.otp.required}")
    @Size(min = 6, max = 6, message = "{auth.otp.size}")
    String otp;
}
