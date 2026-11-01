package com.vn.smart_space.consts;

/**
 * Vòng đời yêu cầu nhờ làm giùm.
 * PENDING → ACCEPTED → COMPLETED là luồng chính; mọi trạng thái kết thúc khác đều hoàn bonus cho người nhờ.
 */
public enum EDelegationStatus {
    /** Đã giữ bonus của người nhờ, chờ người được nhờ trả lời. */
    PENDING,
    /** Người được nhờ đã nhận, task chuyển sang họ (report.assignedStaff). */
    ACCEPTED,
    /** Người được nhờ từ chối → hoàn bonus. */
    DECLINED,
    /** Người nhờ huỷ khi còn PENDING → hoàn bonus. */
    CANCELLED,
    /** Quá hạn chưa trả lời → hoàn bonus. */
    EXPIRED,
    /** Task hoàn tất → bonus chuyển cho người làm giùm. */
    COMPLETED,
    /** Admin từ chối/phân công lại report, hoặc người nhờ tự hoàn tất khi còn PENDING → hoàn bonus. */
    REVOKED;

    /** Đang chiếm task: chặn tạo yêu cầu mới cho cùng report. */
    public boolean isActive() {
        return this == PENDING || this == ACCEPTED;
    }
}
