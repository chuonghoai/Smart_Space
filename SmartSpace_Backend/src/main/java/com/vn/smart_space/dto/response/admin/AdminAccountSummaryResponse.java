package com.vn.smart_space.dto.response.admin;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Tổng hợp trên toàn bộ tài khoản admin (không phụ thuộc filter đang áp dụng). */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminAccountSummaryResponse {
    long total;
    long active;
    long blocked;
}
