package com.vn.smart_space.utils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;

/**
 * Chuẩn hoá tham số lọc danh sách từ app (từ khoá, khoảng ngày).
 * Giá trị sai định dạng bị bỏ qua (không lọc chiều đó) thay vì trả lỗi.
 */
public final class ListQueryParams {

    private ListQueryParams() {
    }

    /** Khoảng thời gian [from, toExclusive); mỗi đầu null = không giới hạn. */
    public record DateRange(LocalDateTime from, LocalDateTime toExclusive) {
    }

    /** Trim, cắt còn tối đa [maxLength] ký tự; null / rỗng = null (không lọc). */
    public static String normalizeKeyword(String search, int maxLength) {
        if (search == null) {
            return null;
        }
        String keyword = search.trim();
        if (keyword.length() > maxLength) {
            keyword = keyword.substring(0, maxLength);
        }
        return keyword.isEmpty() ? null : keyword;
    }

    /**
     * Ngày app gửi lên (yyyy-MM-dd, theo giờ server) → [đầu ngày from, đầu ngày sau to), nên trọn ngày cuối
     * được tính. Sai định dạng thì bỏ đầu đó; from sau to thì đảo lại.
     */
    public static DateRange parseDateRange(String from, String to) {
        LocalDate fromDate = parseDate(from);
        LocalDate toDate = parseDate(to);
        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            LocalDate swap = fromDate;
            fromDate = toDate;
            toDate = swap;
        }
        return new DateRange(
                fromDate != null ? fromDate.atStartOfDay() : null,
                toDate != null ? toDate.plusDays(1).atStartOfDay() : null);
    }

    private static LocalDate parseDate(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }
}
