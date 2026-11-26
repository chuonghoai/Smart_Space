package com.vn.smart_space.dto.response.admin;

import java.time.LocalDate;
import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/**
 * Xu hướng đăng ký người dùng mới. Mỗi bucket được định danh bằng ngày bắt đầu
 * (ISO yyyy-MM-dd) để client tự format label theo locale.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AdminUserTrendResponse {

    String period; // "daily" | "weekly" | "monthly"
    List<TrendItem> items;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class TrendItem {
        LocalDate date; // daily: ngày; weekly: thứ Hai đầu tuần; monthly: ngày 1 của tháng
        long count;
    }
}
