package com.vn.smart_space.consts;

/** Vòng đời một tín hiệu SOS: ACTIVE → ACKNOWLEDGED (admin tiếp nhận) → RESOLVED. */
public enum ESosStatus {
    ACTIVE,
    ACKNOWLEDGED,
    RESOLVED;

    /** Còn đang cần hỗ trợ: tiếp tục nhận vị trí và hiện ở danh sách đang mở. */
    public boolean isOpen() {
        return this != RESOLVED;
    }
}
