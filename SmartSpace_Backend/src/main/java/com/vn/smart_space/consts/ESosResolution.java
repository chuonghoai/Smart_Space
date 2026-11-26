package com.vn.smart_space.consts;

/** Cách một SOS được kết thúc. */
public enum ESosResolution {
    /** Người gửi tự bấm "Tôi đã an toàn". */
    SAFE_BY_USER,
    /** Admin xác nhận đã hỗ trợ xong. */
    RESOLVED_BY_ADMIN,
    /** Admin xác định là báo động nhầm. */
    FALSE_ALARM
}
