package com.vn.smart_space.consts;

/**
 * Vòng đời liên hệ khẩn cấp: chỉ ACCEPTED mới nhận cảnh báo SOS.
 */
public enum EEmergencyContactStatus {
    /** Chờ người được thêm đồng ý (lời mời trong app hoặc OTP qua SMS). */
    PENDING,
    ACCEPTED,
    /** Người được mời từ chối lời mời trong app. */
    REJECTED,
    /** Người đã đồng ý tự rút khỏi danh sách. */
    REVOKED
}
