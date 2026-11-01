package com.vn.smart_space.consts;

import java.time.LocalDateTime;

public enum EDensityTimeframe {
    ALL("all", null),
    MONTH_1("1m", 1),
    MONTH_3("3m", 3),
    MONTH_6("6m", 6),
    MONTH_9("9m", 9),
    MONTH_12("12m", 12);

    private final String code;
    private final Integer months;

    EDensityTimeframe(String code, Integer months) {
        this.code = code;
        this.months = months;
    }

    public String getCode() {
        return code;
    }

    public Integer getMonths() {
        return months;
    }

    public LocalDateTime getCutoff(LocalDateTime now) {
        if (months == null) {
            return null;
        }
        return now.minusMonths(months);
    }

    public static EDensityTimeframe fromCode(String code) {
        if (code == null || code.isBlank()) {
            return ALL;
        }
        for (EDensityTimeframe tf : values()) {
            if (tf.code.equalsIgnoreCase(code.trim())) {
                return tf;
            }
        }
        return ALL;
    }
}

