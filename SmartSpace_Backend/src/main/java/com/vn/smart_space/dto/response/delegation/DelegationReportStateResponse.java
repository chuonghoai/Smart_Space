package com.vn.smart_space.dto.response.delegation;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import lombok.experimental.FieldDefaults;

/**
 * Trạng thái nhờ làm giùm của một report, cho màn chi tiết của staff:
 * có nhờ được không (kèm lý do), bonus dự kiến, số dư ví, và yêu cầu đang hoạt động (nếu có).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class DelegationReportStateResponse {

    @JsonProperty("can_request")
    boolean canRequest;

    /** Mã lý do không nhờ được (vd. delegation.insufficient_balance), null khi nhờ được. */
    @JsonProperty("reason_code")
    String reasonCode;

    /** Lý do đã dịch theo ngôn ngữ của staff. */
    String reason;

    String severity;

    @JsonProperty("commission_amount")
    Double commissionAmount;

    @JsonProperty("rate_percent")
    Double ratePercent;

    @JsonProperty("bonus_amount")
    Double bonusAmount;

    Double balance;

    @JsonProperty("active_delegation")
    DelegationResponse activeDelegation;

    /** Yêu cầu đã hoàn tất của report mà staff tham gia (để hiện bonus đã nhận / đã trả), null nếu không có. */
    @JsonProperty("completed_delegation")
    DelegationResponse completedDelegation;

    /**
     * Vai trò của staff đang xem trong yêu cầu đang hoạt động hoặc đã hoàn tất: REQUESTER / HELPER, null nếu không tham gia.
     * Tính ở backend từ JWT nên app không phải tự so id người dùng.
     */
    @JsonProperty("viewer_role")
    String viewerRole;
}
