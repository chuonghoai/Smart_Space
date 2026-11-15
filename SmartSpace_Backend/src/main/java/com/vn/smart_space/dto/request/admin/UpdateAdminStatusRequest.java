package com.vn.smart_space.dto.request.admin;

import jakarta.validation.constraints.NotBlank;

/** Trạng thái mới của tài khoản quản trị viên: {@code active} | {@code blocked}. */
public record UpdateAdminStatusRequest(
        @NotBlank(message = "{admin.account.status_invalid}") String status) {
}
