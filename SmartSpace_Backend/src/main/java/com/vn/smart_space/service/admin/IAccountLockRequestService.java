package com.vn.smart_space.service.admin;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.AccountLockVoteRequest;
import com.vn.smart_space.dto.request.admin.CreateAccountLockRequest;
import com.vn.smart_space.dto.request.admin.UnlockUserRequest;
import com.vn.smart_space.dto.response.admin.AccountLockPendingCountResponse;
import com.vn.smart_space.dto.response.admin.AccountLockRequestResponse;

/**
 * Khóa tài khoản người dùng qua biểu quyết của Hội đồng quản trị: một admin đề xuất (kèm lý do +
 * bằng chứng), chỉ khi đủ số admin khác bảo lãnh thì tài khoản mới bị khóa.
 */
public interface IAccountLockRequestService {

    AccountLockRequestResponse create(CreateAccountLockRequest request, String adminId);

    /**
     * Vì sao chưa thể đề xuất khóa [target]: not_active | already_pending | not_enough_admins; null = được phép.
     * Chỉ để hiển thị — {@link #create} vẫn tự kiểm tra lại dưới khóa dòng.
     */
    String proposalBlockedReason(com.vn.smart_space.model.User target);

    /** [status]: awaiting_mine | pending | resolved | all (mặc định all). */
    PageResponse<AccountLockRequestResponse> list(String status, int page, int size, String adminId);

    AccountLockRequestResponse getDetail(String requestId, String adminId);

    AccountLockRequestResponse vote(String requestId, AccountLockVoteRequest request, String adminId);

    AccountLockRequestResponse cancel(String requestId, String adminId);

    /** Chuyển đề xuất quá hạn sang expired (gọi từ scheduler, mỗi đề xuất một transaction). */
    void expire(String requestId);

    AccountLockPendingCountResponse getPendingCount(String adminId);

    /** Mở khóa: một admin là đủ (giảm rủi ro), bắt buộc ghi lý do. */
    void unlockUser(String userId, UnlockUserRequest request, String adminId);
}
