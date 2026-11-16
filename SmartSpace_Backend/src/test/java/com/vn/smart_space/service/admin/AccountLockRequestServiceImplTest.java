package com.vn.smart_space.service.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.anyIterable;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.vn.smart_space.consts.EAccountLockEvidenceType;
import com.vn.smart_space.consts.EAccountLockRequestStatus;
import com.vn.smart_space.consts.EAccountLockVoteDecision;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.admin.AccountLockVoteRequest;
import com.vn.smart_space.dto.request.admin.CreateAccountLockRequest;
import com.vn.smart_space.dto.request.admin.UnlockUserRequest;
import com.vn.smart_space.dto.response.admin.AccountLockRequestResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.AccountLockEvidence;
import com.vn.smart_space.model.AccountLockRequest;
import com.vn.smart_space.model.AccountLockVote;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.AccountLockEvidenceRepository;
import com.vn.smart_space.repository.AccountLockRequestRepository;
import com.vn.smart_space.repository.AccountLockVoteRepository;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;

@ExtendWith(MockitoExtension.class)
class AccountLockRequestServiceImplTest {

    private static final String PROPOSER = "admin-a";
    private static final String VOTER_B = "admin-b";
    private static final String VOTER_C = "admin-c";
    private static final String TARGET = "user-1";
    private static final String REQ = "req-1";
    private static final String VALID_REASON = "Đăng nhiều phản ánh sai sự thật và spam liên tục.";

    @Mock
    AccountLockRequestRepository requestRepository;
    @Mock
    AccountLockVoteRepository voteRepository;
    @Mock
    AccountLockEvidenceRepository evidenceRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    ReportRepository reportRepository;
    @Mock
    ActivityHistoryRepository activityHistoryRepository;
    @Mock
    IAuthenticationService authenticationService;
    @Mock
    AccountLockNotifier notifier;

    @InjectMocks
    AccountLockRequestServiceImpl service;

    private static User user(String id, ERole role, EUserStatus status) {
        User u = User.builder().fullName("Name " + id).email(id + "@example.com").role(role).status(status).build();
        u.setId(id);
        return u;
    }

    private static Report report(String id, User owner, Boolean anonymous) {
        Report r = Report.builder().title("Report " + id).user(owner).isAnonymous(anonymous).build();
        r.setId(id);
        return r;
    }

    private static AccountLockRequest pendingRequest(User proposer, User target) {
        AccountLockRequest r = AccountLockRequest.builder()
                .proposer(proposer)
                .target(target)
                .reason(VALID_REASON)
                .status(EAccountLockRequestStatus.pending)
                .expiresAt(LocalDateTime.now().plusHours(10))
                .build();
        r.setId(REQ);
        return r;
    }

    private static CreateAccountLockRequest createReq(List<String> images, List<String> reports) {
        return new CreateAccountLockRequest(TARGET, VALID_REASON, images, reports);
    }

    // ──────────────────────────── Create ────────────────────────────

    @Nested
    @DisplayName("Tạo đề xuất khóa")
    class Create {

        private final User proposer = user(PROPOSER, ERole.admin, EUserStatus.active);
        private final User target = user(TARGET, ERole.client, EUserStatus.active);

        @Test
        @DisplayName("lý do quá ngắn (sau khi trim) → reason.length, không chạm DB")
        void shortReason_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class, () -> service.create(
                    new CreateAccountLockRequest(TARGET, "   quá ngắn    ", List.of("https://x/a.jpg"), null),
                    PROPOSER));

            assertEquals("lock_request.reason.length", ex.getMessage());
            verifyNoInteractions(userRepository, requestRepository);
        }

        @Test
        @DisplayName("không có bằng chứng → evidence.required")
        void noEvidence_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(List.of(" "), List.of()), PROPOSER));

            assertEquals("lock_request.evidence.required", ex.getMessage());
            verifyNoInteractions(userRepository);
        }

        @Test
        @DisplayName("ảnh không phải https → evidence.image_invalid")
        void nonHttpsImage_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(List.of("http://x/a.jpg"), null), PROPOSER));

            assertEquals("lock_request.evidence.image_invalid", ex.getMessage());
        }

        @Test
        @DisplayName("đối tượng không phải client → target_not_found")
        void nonClientTarget_isNotFound() {
            when(userRepository.findByIdForUpdate(TARGET))
                    .thenReturn(Optional.of(user(TARGET, ERole.staff, EUserStatus.active)));

            ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class,
                    () -> service.create(createReq(List.of("https://x/a.jpg"), null), PROPOSER));

            assertEquals("lock_request.target_not_found", ex.getMessage());
        }

        @Test
        @DisplayName("người dùng đã bị khóa → target_not_active")
        void blockedTarget_isRejected() {
            when(userRepository.findByIdForUpdate(TARGET))
                    .thenReturn(Optional.of(user(TARGET, ERole.client, EUserStatus.blocked)));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(List.of("https://x/a.jpg"), null), PROPOSER));

            assertEquals("lock_request.target_not_active", ex.getMessage());
        }

        @Test
        @DisplayName("đã có đề xuất chờ → already_pending; khóa dòng người dùng diễn ra TRƯỚC khi kiểm tra")
        void alreadyPending_isRejected_afterRowLock() {
            when(userRepository.findByIdForUpdate(TARGET)).thenReturn(Optional.of(target));
            when(requestRepository.existsByTargetIdAndStatus(TARGET, EAccountLockRequestStatus.pending))
                    .thenReturn(true);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(List.of("https://x/a.jpg"), null), PROPOSER));

            assertEquals("lock_request.already_pending", ex.getMessage());
            InOrder order = inOrder(userRepository, requestRepository);
            order.verify(userRepository).findByIdForUpdate(TARGET);
            order.verify(requestRepository).existsByTargetIdAndStatus(TARGET, EAccountLockRequestStatus.pending);
        }

        @Test
        @DisplayName("không đủ 2 admin khác đang hoạt động → not_enough_admins")
        void notEnoughAdmins_isRejected() {
            when(userRepository.findByIdForUpdate(TARGET)).thenReturn(Optional.of(target));
            when(userRepository.findById(PROPOSER)).thenReturn(Optional.of(proposer));
            when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(2L);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(List.of("https://x/a.jpg"), null), PROPOSER));

            assertEquals("lock_request.not_enough_admins", ex.getMessage());
            verify(requestRepository, never()).save(any());
        }

        @Test
        @DisplayName("phản ánh ẩn danh hoặc của người khác → evidence.report_invalid")
        void anonymousOrForeignReport_isRejected() {
            when(userRepository.findByIdForUpdate(TARGET)).thenReturn(Optional.of(target));
            when(userRepository.findById(PROPOSER)).thenReturn(Optional.of(proposer));
            when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(3L);
            when(reportRepository.findAllById(anyIterable())).thenReturn(List.of(
                    report("r1", target, true),
                    report("r2", user("someone", ERole.client, EUserStatus.active), false)));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.create(createReq(null, List.of("r1", "r2")), PROPOSER));

            assertEquals("lock_request.evidence.report_invalid", ex.getMessage());
            verify(requestRepository, never()).save(any());
        }

        @Test
        @DisplayName("thành công → pending, hạn 72h, lưu ảnh + phản ánh, ghi log, mời các admin biểu quyết")
        void success_createsPendingRequest() {
            when(userRepository.findByIdForUpdate(TARGET)).thenReturn(Optional.of(target));
            when(userRepository.findById(PROPOSER)).thenReturn(Optional.of(proposer));
            when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(3L);
            when(reportRepository.findAllById(anyIterable())).thenReturn(List.of(report("r1", target, null)));
            when(requestRepository.save(any(AccountLockRequest.class))).thenAnswer(inv -> {
                AccountLockRequest saved = inv.getArgument(0);
                saved.setId(REQ);
                return saved;
            });
            when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(proposer,
                    user(VOTER_B, ERole.admin, EUserStatus.active),
                    user("admin-blocked", ERole.admin, EUserStatus.blocked)));

            AccountLockRequestResponse res = service.create(
                    createReq(List.of("https://x/a.jpg", "https://x/a.jpg"), List.of("r1")), PROPOSER);

            ArgumentCaptor<AccountLockRequest> saved = ArgumentCaptor.forClass(AccountLockRequest.class);
            verify(requestRepository).save(saved.capture());
            assertEquals(EAccountLockRequestStatus.pending, saved.getValue().getStatus());
            Duration window = Duration.between(LocalDateTime.now(), saved.getValue().getExpiresAt());
            assertTrue(window.toHours() >= 71 && window.toHours() <= 72, "hạn biểu quyết ~72h");

            @SuppressWarnings("unchecked")
            ArgumentCaptor<List<AccountLockEvidence>> evidences = ArgumentCaptor.forClass(List.class);
            verify(evidenceRepository).saveAll(evidences.capture());
            assertEquals(2, evidences.getValue().size(), "ảnh trùng được gộp: 1 ảnh + 1 phản ánh");
            assertEquals(EAccountLockEvidenceType.image, evidences.getValue().get(0).getType());
            assertEquals(EAccountLockEvidenceType.report, evidences.getValue().get(1).getType());

            verify(activityHistoryRepository).save(any(ActivityHistory.class));
            @SuppressWarnings("unchecked")
            ArgumentCaptor<List<User>> invited = ArgumentCaptor.forClass(List.class);
            verify(notifier).notifyNewRequest(any(AccountLockRequest.class), invited.capture());
            assertTrue(invited.getValue().stream().allMatch(u -> u.getStatus() == EUserStatus.active),
                    "chỉ mời admin đang hoạt động");

            assertEquals(REQ, res.getId());
            assertTrue(res.isMine());
            assertFalse(res.isCanVote());
            assertEquals("proposer", res.getVoteBlockedReason());
            assertTrue(res.isCanCancel());
        }
    }

    // ──────────────────────────── Vote ────────────────────────────

    @Nested
    @DisplayName("Bỏ phiếu")
    class Vote {

        private final User proposer = user(PROPOSER, ERole.admin, EUserStatus.active);
        private final User voterB = user(VOTER_B, ERole.admin, EUserStatus.active);
        private final User target = user(TARGET, ERole.client, EUserStatus.active);

        @Test
        @DisplayName("phiếu không hợp lệ → decision_invalid, không khóa dòng")
        void invalidDecision_isRejected() {
            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.vote(REQ, new AccountLockVoteRequest("maybe", null), VOTER_B));

            assertEquals("lock_request.vote.decision_invalid", ex.getMessage());
            verifyNoInteractions(requestRepository);
        }

        @Test
        @DisplayName("đề xuất đã kết thúc → closed")
        void resolvedRequest_isClosed() {
            AccountLockRequest req = pendingRequest(proposer, target);
            req.setStatus(EAccountLockRequestStatus.approved);
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.vote(REQ, new AccountLockVoteRequest("approve", null), VOTER_B));

            assertEquals("lock_request.closed", ex.getMessage());
        }

        @Test
        @DisplayName("đã quá hạn nhưng scheduler chưa chạy → closed")
        void overdueRequest_isClosed() {
            AccountLockRequest req = pendingRequest(proposer, target);
            req.setExpiresAt(LocalDateTime.now().minusMinutes(1));
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.vote(REQ, new AccountLockVoteRequest("approve", null), VOTER_B));

            assertEquals("lock_request.closed", ex.getMessage());
        }

        @Test
        @DisplayName("người đề xuất tự bỏ phiếu → self_vote")
        void proposerVote_isRejected() {
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(pendingRequest(proposer, target)));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.vote(REQ, new AccountLockVoteRequest("approve", null), PROPOSER));

            assertEquals("lock_request.self_vote", ex.getMessage());
        }

        @Test
        @DisplayName("bỏ phiếu lần hai → already_voted")
        void secondVote_isRejected() {
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(pendingRequest(proposer, target)));
            when(voteRepository.existsByRequestIdAndVoterId(REQ, VOTER_B)).thenReturn(true);

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.vote(REQ, new AccountLockVoteRequest("approve", null), VOTER_B));

            assertEquals("lock_request.already_voted", ex.getMessage());
            verify(voteRepository, never()).save(any());
        }

        @Test
        @DisplayName("phiếu bảo lãnh đầu tiên → vẫn chờ, chưa khóa")
        void firstApproval_staysPending() {
            AccountLockRequest req = pendingRequest(proposer, target);
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));
            when(userRepository.findById(VOTER_B)).thenReturn(Optional.of(voterB));
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.approve)).thenReturn(1L);
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.reject)).thenReturn(0L);

            service.vote(REQ, new AccountLockVoteRequest("APPROVE", "  Đồng ý  "), VOTER_B);

            ArgumentCaptor<AccountLockVote> vote = ArgumentCaptor.forClass(AccountLockVote.class);
            verify(voteRepository).save(vote.capture());
            assertEquals(EAccountLockVoteDecision.approve, vote.getValue().getDecision());
            assertEquals("Đồng ý", vote.getValue().getComment());
            assertEquals(EAccountLockRequestStatus.pending, req.getStatus());
            assertEquals(EUserStatus.active, target.getStatus());
            verifyNoInteractions(authenticationService);
            verify(notifier, never()).notifyAccountLocked(any(), anyString());
        }

        @Test
        @DisplayName("đủ 2 bảo lãnh → khóa tài khoản, thu hồi phiên, báo người dùng, thông báo kết quả")
        void secondApproval_locksAccount() {
            AccountLockRequest req = pendingRequest(proposer, target);
            User voterC = user(VOTER_C, ERole.admin, EUserStatus.active);
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));
            when(userRepository.findById(VOTER_C)).thenReturn(Optional.of(voterC));
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.approve)).thenReturn(2L);
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.reject)).thenReturn(0L);

            service.vote(REQ, new AccountLockVoteRequest("approve", null), VOTER_C);

            assertEquals(EAccountLockRequestStatus.approved, req.getStatus());
            assertNotNull(req.getResolvedAt());
            assertEquals(EUserStatus.blocked, target.getStatus());
            verify(userRepository).save(target);
            verify(authenticationService).revokeUserAccess(TARGET);
            verify(notifier).notifyAccountLocked(target, VALID_REASON);
            verify(notifier).notifyResolved(eq(req), anyCollection());
        }

        @Test
        @DisplayName("đủ 2 từ chối → bác bỏ, tài khoản giữ nguyên")
        void secondRejection_rejectsRequest() {
            AccountLockRequest req = pendingRequest(proposer, target);
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));
            when(userRepository.findById(VOTER_B)).thenReturn(Optional.of(voterB));
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.approve)).thenReturn(1L);
            when(voteRepository.countByRequestIdAndDecision(REQ, EAccountLockVoteDecision.reject)).thenReturn(2L);

            service.vote(REQ, new AccountLockVoteRequest("reject", null), VOTER_B);

            assertEquals(EAccountLockRequestStatus.rejected, req.getStatus());
            assertEquals(EUserStatus.active, target.getStatus());
            verifyNoInteractions(authenticationService);
            verify(notifier).notifyResolved(eq(req), anyCollection());
        }
    }

    // ──────────────────────────── Cancel / Expire ────────────────────────────

    @Nested
    @DisplayName("Hủy và hết hạn")
    class CancelExpire {

        private final User proposer = user(PROPOSER, ERole.admin, EUserStatus.active);
        private final User target = user(TARGET, ERole.client, EUserStatus.active);

        @Test
        @DisplayName("người khác hủy → not_proposer")
        void cancelByOther_isRejected() {
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(pendingRequest(proposer, target)));

            BadRequestException ex = assertThrows(BadRequestException.class, () -> service.cancel(REQ, VOTER_B));

            assertEquals("lock_request.not_proposer", ex.getMessage());
        }

        @Test
        @DisplayName("người đề xuất hủy khi còn chờ → cancelled")
        void cancelByProposer_cancels() {
            AccountLockRequest req = pendingRequest(proposer, target);
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));

            AccountLockRequestResponse res = service.cancel(REQ, PROPOSER);

            assertEquals(EAccountLockRequestStatus.cancelled, req.getStatus());
            assertEquals("cancelled", res.getStatus());
            assertFalse(res.isCanCancel());
        }

        @Test
        @DisplayName("quá hạn và còn chờ → expired + thông báo kết quả")
        void overdue_expires() {
            AccountLockRequest req = pendingRequest(proposer, target);
            req.setExpiresAt(LocalDateTime.now().minusMinutes(5));
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));

            service.expire(REQ);

            assertEquals(EAccountLockRequestStatus.expired, req.getStatus());
            verify(notifier).notifyResolved(eq(req), anyCollection());
        }

        @Test
        @DisplayName("vừa được duyệt trước khi scheduler khóa dòng → không đổi gì")
        void alreadyResolved_isNoop() {
            AccountLockRequest req = pendingRequest(proposer, target);
            req.setStatus(EAccountLockRequestStatus.approved);
            req.setExpiresAt(LocalDateTime.now().minusMinutes(5));
            when(requestRepository.findByIdForUpdate(REQ)).thenReturn(Optional.of(req));

            service.expire(REQ);

            assertEquals(EAccountLockRequestStatus.approved, req.getStatus());
            verifyNoInteractions(notifier, activityHistoryRepository);
        }
    }

    // ──────────────────────────── Unlock ────────────────────────────

    @Nested
    @DisplayName("Mở khóa")
    class Unlock {

        @Test
        @DisplayName("tài khoản không bị khóa → not_blocked")
        void notBlocked_isRejected() {
            when(userRepository.findByIdForUpdate(TARGET))
                    .thenReturn(Optional.of(user(TARGET, ERole.client, EUserStatus.active)));

            BadRequestException ex = assertThrows(BadRequestException.class,
                    () -> service.unlockUser(TARGET, new UnlockUserRequest("Đã xác minh lại thông tin"), PROPOSER));

            assertEquals("user.unlock.not_blocked", ex.getMessage());
        }

        @Test
        @DisplayName("một admin mở khóa + lý do → active, gỡ chặn, ghi log kèm lý do, báo người dùng")
        void success_unlocks() {
            User target = user(TARGET, ERole.client, EUserStatus.blocked);
            when(userRepository.findByIdForUpdate(TARGET)).thenReturn(Optional.of(target));
            when(userRepository.findById(PROPOSER))
                    .thenReturn(Optional.of(user(PROPOSER, ERole.admin, EUserStatus.active)));

            service.unlockUser(TARGET, new UnlockUserRequest("Người dùng đã khiếu nại | và được chấp nhận"), PROPOSER);

            assertEquals(EUserStatus.active, target.getStatus());
            verify(authenticationService).restoreUserAccess(TARGET);
            ArgumentCaptor<ActivityHistory> activity = ArgumentCaptor.forClass(ActivityHistory.class);
            verify(activityHistoryRepository).save(activity.capture());
            assertEquals("activity.user.unlocked|Name admin-a|Name user-1|Người dùng đã khiếu nại   và được chấp nhận",
                    activity.getValue().getI18nKey(), "ký tự | trong lý do bị thay để không phá tham số");
            verify(notifier).notifyAccountUnlocked(target);
        }
    }

    // ──────────────────────────── Eligibility / list / counts ────────────────────────────

    @Nested
    @DisplayName("Điều kiện đề xuất, bộ lọc và bộ đếm")
    class Eligibility {

        @Test
        @DisplayName("proposalBlockedReason: đã khóa → not_active; đã có đề xuất chờ → already_pending")
        void blockedReasons_inactiveAndPending() {
            assertEquals("not_active",
                    service.proposalBlockedReason(user(TARGET, ERole.client, EUserStatus.blocked)));

            when(requestRepository.existsByTargetIdAndStatus(TARGET, EAccountLockRequestStatus.pending))
                    .thenReturn(true);
            assertEquals("already_pending",
                    service.proposalBlockedReason(user(TARGET, ERole.client, EUserStatus.active)));
        }

        @Test
        @DisplayName("proposalBlockedReason: chỉ 2 admin hoạt động → not_enough_admins; 3 admin → được phép")
        void blockedReasons_adminCount() {
            User target = user(TARGET, ERole.client, EUserStatus.active);
            when(userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active)).thenReturn(2L, 3L);

            assertEquals("not_enough_admins", service.proposalBlockedReason(target));
            assertEquals(null, service.proposalBlockedReason(target));
        }

        @Test
        @DisplayName("list(awaiting_mine) → truy vấn hàng chờ của chính admin, hạn gần nhất lên trước")
        void listAwaitingMine_usesAwaitingQuery() {
            ArgumentCaptor<org.springframework.data.domain.Pageable> pageable =
                    ArgumentCaptor.forClass(org.springframework.data.domain.Pageable.class);
            when(requestRepository.findAwaitingVote(eq(EAccountLockRequestStatus.pending), eq(VOTER_B),
                    any(LocalDateTime.class), pageable.capture()))
                    .thenReturn(org.springframework.data.domain.Page.empty());

            service.list("awaiting_mine", 1, 10, VOTER_B);

            assertEquals(org.springframework.data.domain.Sort.Direction.ASC,
                    pageable.getValue().getSort().getOrderFor("expiresAt").getDirection());
            verify(requestRepository, never()).findByStatusIn(anyCollection(), any());
        }

        @Test
        @DisplayName("getPendingCount → gồm cả số đã kết thúc và hạn gần nhất cần biểu quyết")
        void pendingCount_includesResolvedAndNextDeadline() {
            LocalDateTime deadline = LocalDateTime.now().plusHours(5);
            when(requestRepository.countByStatus(EAccountLockRequestStatus.pending)).thenReturn(3L);
            when(requestRepository.countAwaitingVote(eq(EAccountLockRequestStatus.pending), eq(VOTER_B),
                    any(LocalDateTime.class))).thenReturn(2L);
            when(requestRepository.countByStatusIn(anyCollection())).thenReturn(14L);
            when(requestRepository.findNextAwaitingDeadline(eq(EAccountLockRequestStatus.pending), eq(VOTER_B),
                    any(LocalDateTime.class))).thenReturn(deadline);

            var res = service.getPendingCount(VOTER_B);

            assertEquals(3, res.getPending());
            assertEquals(2, res.getAwaitingMyVote());
            assertEquals(14, res.getResolved());
            assertEquals(deadline, res.getNextDeadlineAt());
        }
    }

    @Test
    @DisplayName("activityKey: thay '|' trong tham số và chặn tối đa 255 ký tự")
    void activityKey_sanitizesAndTruncates() {
        assertEquals("k|a b|c", AccountLockRequestServiceImpl.activityKey("k", "a|b", "c"));
        assertEquals(255, AccountLockRequestServiceImpl.activityKey("k", "x".repeat(400)).length());
    }
}
