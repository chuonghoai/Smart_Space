package com.vn.smart_space.utils;

import java.util.regex.Pattern;

/** Chuẩn hoá số di động Việt Nam về dạng 84xxxxxxxxx (định dạng nhà cung cấp SMS yêu cầu). */
public final class PhoneNumberUtils {

    /** Chấp nhận 0xxxxxxxxx, 84xxxxxxxxx, +84xxxxxxxxx với đầu số di động 3/5/7/8/9. */
    public static final String VN_MOBILE_REGEX = "^(\\+?84|0)[35789]\\d{8}$";

    private static final Pattern VN_MOBILE = Pattern.compile(VN_MOBILE_REGEX);

    private PhoneNumberUtils() {
    }

    /** Trả về null nếu không phải số di động Việt Nam hợp lệ. */
    public static String normalizeVnMobile(String raw) {
        if (raw == null) {
            return null;
        }
        String compact = raw.replaceAll("[\\s.\\-()]", "");
        if (!VN_MOBILE.matcher(compact).matches()) {
            return null;
        }
        if (compact.startsWith("+")) {
            return compact.substring(1);
        }
        return compact.startsWith("0") ? "84" + compact.substring(1) : compact;
    }

    /** Hiển thị dạng nội địa 0xxxxxxxxx. */
    public static String toLocalFormat(String normalized) {
        if (normalized == null || !normalized.startsWith("84")) {
            return normalized;
        }
        return "0" + normalized.substring(2);
    }
}
