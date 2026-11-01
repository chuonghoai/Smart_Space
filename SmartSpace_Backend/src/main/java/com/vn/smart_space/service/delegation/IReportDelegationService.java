package com.vn.smart_space.service.delegation;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.delegation.CreateDelegationRequest;
import com.vn.smart_space.dto.response.delegation.DelegationReportStateResponse;
import com.vn.smart_space.dto.response.delegation.DelegationResponse;
import com.vn.smart_space.dto.response.delegation.StaffColleagueResponse;
import com.vn.smart_space.model.Report;

public interface IReportDelegationService {

    PageResponse<StaffColleagueResponse> searchColleagues(String staffId, String search, int page, int size);

    /** Trạng thái nhờ làm giùm của report cho staff đang xem (có nhờ được không, bonus dự kiến, yêu cầu đang hoạt động). */
    DelegationReportStateResponse getReportState(String staffId, String reportId);

    DelegationResponse create(String requesterId, CreateDelegationRequest request);

    /** box = received (được nhờ) | sent (đã nhờ). */
    PageResponse<DelegationResponse> list(String staffId, String box, int page, int size);

    DelegationResponse accept(String helperId, String delegationId);

    DelegationResponse decline(String helperId, String delegationId);

    DelegationResponse cancel(String requesterId, String delegationId);

    // ===== Hook từ luồng report — chạy trong transaction của luồng gọi =====

    /** Report vừa hoàn tất: ACCEPTED → trả bonus cho người làm giùm; PENDING (người nhờ tự làm) → thu hồi, hoàn bonus. */
    void onReportCompleted(Report report);

    /** Admin từ chối report hoặc phân công cho người khác: thu hồi yêu cầu đang hoạt động, hoàn bonus. */
    void onReportUnassigned(Report report);

    /** Hết hạn một yêu cầu PENDING quá hạn (transaction riêng, gọi từ job định kỳ). */
    void expire(String delegationId);
}
