package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateAdminRequest(
                @NotBlank(message = "{user.fullName.required}") @Size(max = 100, message = "{admin.account.fullName.too_long}") String fullName,

                @NotBlank(message = "{auth.email.required}") @Email(message = "{auth.email.invalid}") String email,

                @Pattern(regexp = "^$|^\\+?[0-9]{8,15}$", message = "{admin.account.phone.invalid}") String phone) {
}
