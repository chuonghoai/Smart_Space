package com.vn.smart_space.consts;

/**
 * Client map filter. Processed reports are only ever shown to their owner,
 * so {@link #processed} means "my processed reports".
 */
public enum EMapReportFilter {
    all,
    mine,
    pending,
    processing,
    processed;

    /** Null/blank → {@link #all}; unknown value → null so the caller can reject it. */
    public static EMapReportFilter from(String value) {
        if (value == null || value.isBlank()) {
            return all;
        }
        for (EMapReportFilter filter : values()) {
            if (filter.name().equalsIgnoreCase(value.trim())) {
                return filter;
            }
        }
        return null;
    }

    /** Status the filter pins, or null when every visible status is allowed. */
    public EReportStatus status() {
        return switch (this) {
            case pending -> EReportStatus.pending;
            case processing -> EReportStatus.processing;
            case processed -> EReportStatus.processed;
            case all, mine -> null;
        };
    }
}
