package com.vn.smart_space.dto.response.admin;

import java.time.LocalDateTime;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.FieldDefaults;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@FieldDefaults(level = AccessLevel.PRIVATE)
public class AccountLockPendingCountResponse {
    /** Tổng đề xuất đang chờ biểu quyết. */
    long pending;
    /** Đề xuất đang chờ mà admin đang xem còn phải bỏ phiếu. */
    long awaitingMyVote;
    /** Đề xuất đã kết thúc (approved | rejected | cancelled | expired). */
    long resolved;
    /** Hạn gần nhất trong các đề xuất admin đang xem còn phải bỏ phiếu (null nếu không có). */
    LocalDateTime nextDeadlineAt;
}
