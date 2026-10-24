package com.vn.smart_space.dto.response.admin;

import java.time.LocalDate;
import java.util.List;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

/** Luồng xử lý báo cáo theo thời gian: số được phân công (vào) và số đã xử lý (ra). */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class StaffTrendResponse {

    String period; // "daily" | "weekly" | "monthly"
    List<TrendItem> items;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    @FieldDefaults(level = AccessLevel.PRIVATE)
    public static class TrendItem {
        LocalDate date; // daily: ngày; weekly: thứ Hai đầu tuần; monthly: ngày 1 của tháng
        long assigned;
        long resolved;
    }
}
