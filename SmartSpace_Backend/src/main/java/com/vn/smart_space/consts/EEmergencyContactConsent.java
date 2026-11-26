package com.vn.smart_space.consts;

/** Cách liên hệ khẩn cấp đồng ý và kênh nhận cảnh báo SOS. */
public enum EEmergencyContactConsent {
    /** Liên hệ có tài khoản: đồng ý qua lời mời trong app, nhận cảnh báo bằng push. */
    APP,
    /** Liên hệ không có tài khoản: owner tự xác nhận đã được đồng ý, nhận cảnh báo bằng SMS khi có SOS. */
    SELF_DECLARED
}
