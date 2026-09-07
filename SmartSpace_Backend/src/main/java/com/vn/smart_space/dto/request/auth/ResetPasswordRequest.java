package com.vn.smart_space.dto.request.auth;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vn.smart_space.validation.StrongPassword;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ResetPasswordRequest {
    @NotBlank(message = "{auth.email.required}")
    @Email(message = "{auth.email.invalid}")
    private String email;

    private com.vn.smart_space.consts.ERole role;

    @NotBlank(message = "{auth.otp.required}")
    @Size(min = 6, max = 6, message = "{auth.otp.size}")
    private String otp;

    @JsonProperty("new_password")
    @NotBlank(message = "{auth.newPassword.required}")
    @Size(min = 6, message = "{auth.password.size}")
    @StrongPassword
    private String newPassword;

    @JsonProperty("confirm_password")
    @NotBlank(message = "{auth.confirmPassword.required}")
    private String confirmPassword;
}
