package com.vn.smart_space.service.admin;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collection;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EAccountLockEvidenceType;
import com.vn.smart_space.consts.EAccountLockRequestStatus;
import com.vn.smart_space.consts.EAccountLockVoteDecision;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.AccountLockVoteRequest;
import com.vn.smart_space.dto.request.admin.CreateAccountLockRequest;
import com.vn.smart_space.dto.request.admin.UnlockUserRequest;
import com.vn.smart_space.dto.response.admin.AccountLockPendingCountResponse;
import com.vn.smart_space.dto.response.admin.AccountLockRequestResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.exception.UnauthorizedException;
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

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AccountLockRequestServiceImpl implements IAccountLockRequestService {

        /** Số phiếu bảo lãnh cần có (không tính người đề xuất). */
        static final int REQUIRED_APPROVALS = 2;
        /** Số phiếu từ chối để bác bỏ đề xuất. */
        static final int REQUIRED_REJECTIONS = 2;
        static final Duration VOTING_WINDOW = Duration.ofHours(72);
        static final int MIN_REASON_LENGTH = 20;
        static final int MAX_IMAGE_URL_LENGTH = 1000;
        static final int MAX_PAGE_SIZE = 50;
        /** Giới hạn cột i18n_key của activity_histories. */
        static final int MAX_ACTIVITY_KEY_LENGTH = 255;
        static final int MAX_ACTIVITY_REASON_LENGTH = 100;
        /** Bộ lọc "cần tôi bỏ phiếu" của danh sách. */
        static final String FILTER_AWAITING_MINE = "awaiting_mine";

        AccountLockRequestRepository requestRepository;
        AccountLockVoteRepository voteRepository;
        AccountLockEvidenceRepository evidenceRepository;
        UserRepository userRepository;
        ReportRepository reportRepository;
        ActivityHistoryRepository activityHistoryRepository;
        IAuthenticationService authenticationService;
        AccountLockNotifier notifier;

        // Create

        @Override
        @Transactional
        public AccountLockRequestResponse create(CreateAccountLockRequest req, String adminId) {
                // 0. Kiểm tra input không cần DB trước
                String reason = req.reason() == null ? "" : req.reason().trim();
                if (reason.length() < MIN_REASON_LENGTH) {
                        throw new BadRequestException("lock_request.reason.length");
                }
                List<String> imageUrls = normalize(req.evidenceImageUrls());
                List<String> reportIds = normalize(req.reportIds());
                if (imageUrls.isEmpty() && reportIds.isEmpty()) {
                        throw new BadRequestException("lock_request.evidence.required");
                }
                for (String url : imageUrls) {
                        if (!url.startsWith("https://") || url.length() > MAX_IMAGE_URL_LENGTH) {
                                throw new BadRequestException("lock_request.evidence.image_invalid");
                        }
                }

                // 1. Khóa tài khoản đích ĐẦU TIÊN
                User target = userRepository.findByIdForUpdate(req.targetUserId())
                                .filter(u -> u.getRole() == ERole.client)
                                .orElseThrow(() -> new ResourceNotFoundException("lock_request.target_not_found"));
                if (target.getStatus() != EUserStatus.active) {
                        throw new BadRequestException("lock_request.target_not_active");
                }
                if (requestRepository.existsByTargetIdAndStatus(target.getId(), EAccountLockRequestStatus.pending)) {
                        throw new BadRequestException("lock_request.already_pending");
                }

                // 2. Phải có đủ admin khác đang hoạt động để có thể đạt ngưỡng → không để đề
                // xuất treo vô hạn
                User proposer = requireActiveAdmin(adminId);
                long otherActiveAdmins = userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active) - 1;
                if (otherActiveAdmins < REQUIRED_APPROVALS) {
                        throw new BadRequestException("lock_request.not_enough_admins");
                }

                // 3. Phản ánh bằng chứng: phải của chính người dùng và KHÔNG ẩn danh (giữ quy
                // tắc ẩn danh)
                List<Report> reports = reportIds.isEmpty() ? List.of() : reportRepository.findAllById(reportIds);
                if (reports.size() != reportIds.size()
                                || reports.stream().anyMatch(r -> !isPublicReportOf(r, target))) {
                        throw new BadRequestException("lock_request.evidence.report_invalid");
                }

                // 4. Lưu đề xuất + bằng chứng
                LocalDateTime now = LocalDateTime.now();
                AccountLockRequest request = requestRepository.save(AccountLockRequest.builder()
                                .target(target)
                                .proposer(proposer)
                                .reason(reason)
                                .status(EAccountLockRequestStatus.pending)
                                .expiresAt(now.plus(VOTING_WINDOW))
                                .build());

                List<AccountLockEvidence> evidences = new ArrayList<>();
                imageUrls.forEach(url -> evidences.add(AccountLockEvidence.builder()
                                .request(request).type(EAccountLockEvidenceType.image).imageUrl(url).build()));
                reports.forEach(report -> evidences.add(AccountLockEvidence.builder()
                                .request(request).type(EAccountLockEvidenceType.report).report(report).build()));
                evidenceRepository.saveAll(evidences);

                logActivity(proposer, request, "activity.lock_request.created", displayName(proposer),
                                displayName(target));
                notifier.notifyNewRequest(request, activeAdmins());

                return toDetail(request, adminId);
        }

        // Read

        @Override
        @Transactional(readOnly = true)
        public PageResponse<AccountLockRequestResponse> list(String status, int page, int size, String adminId) {
                int safePage = Math.max(1, page);
                int safeSize = Math.min(Math.max(1, size), MAX_PAGE_SIZE);

                // Hàng chờ: hạn gần nhất lên trước; đã kết thúc: mới kết thúc lên trước
                Page<AccountLockRequest> result;
                if (FILTER_AWAITING_MINE.equalsIgnoreCase(status)) {
                        result = requestRepository.findAwaitingVote(EAccountLockRequestStatus.pending, adminId,
                                        LocalDateTime.now(), PageRequest.of(safePage - 1, safeSize,
                                                        Sort.by(Sort.Direction.ASC, "expiresAt")));
                } else {
                        Sort sort = "pending".equalsIgnoreCase(status)
                                        ? Sort.by(Sort.Direction.ASC, "expiresAt")
                                        : Sort.by(Sort.Direction.DESC, "resolvedAt").and(
                                                        Sort.by(Sort.Direction.DESC, "createdAt"));
                        result = requestRepository.findByStatusIn(resolveStatusFilter(status),
                                        PageRequest.of(safePage - 1, safeSize, sort));
                }

                // Phiếu của cả trang trong một truy vấn → tránh N+1
                List<String> ids = result.getContent().stream().map(AccountLockRequest::getId).toList();
                Map<String, List<AccountLockVote>> votesByRequest = ids.isEmpty()
                                ? Map.of()
                                : voteRepository.findByRequestIdIn(ids).stream()
                                                .collect(Collectors.groupingBy(v -> v.getRequest().getId()));

                List<AccountLockRequestResponse> content = result.getContent().stream()
                                .map(r -> toSummary(r, votesByRequest.getOrDefault(r.getId(), List.of()), adminId)
                                                .build())
                                .toList();

                return PageResponse.<AccountLockRequestResponse>builder()
                                .currentPage(safePage)
                                .pageSize(safeSize)
                                .totalPages(result.getTotalPages())
                                .totalElements(result.getTotalElements())
                                .content(content)
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public AccountLockRequestResponse getDetail(String requestId, String adminId) {
                AccountLockRequest request = requestRepository.findWithPeopleById(requestId)
                                .orElseThrow(() -> new ResourceNotFoundException("lock_request.not_found"));
                return toDetail(request, adminId);
        }

        @Override
        @Transactional(readOnly = true)
        public AccountLockPendingCountResponse getPendingCount(String adminId) {
                LocalDateTime now = LocalDateTime.now();
                return AccountLockPendingCountResponse.builder()
                                .pending(requestRepository.countByStatus(EAccountLockRequestStatus.pending))
                                .awaitingMyVote(requestRepository.countAwaitingVote(
                                                EAccountLockRequestStatus.pending, adminId, now))
                                .resolved(requestRepository.countByStatusIn(
                                                EnumSet.complementOf(EnumSet.of(EAccountLockRequestStatus.pending))))
                                .nextDeadlineAt(requestRepository.findNextAwaitingDeadline(
                                                EAccountLockRequestStatus.pending, adminId, now))
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public String proposalBlockedReason(User target) {
                if (target == null || target.getStatus() != EUserStatus.active) {
                        return "not_active";
                }
                if (requestRepository.existsByTargetIdAndStatus(target.getId(), EAccountLockRequestStatus.pending)) {
                        return "already_pending";
                }
                // Người xem là một admin đang hoạt động → số admin khác = tổng đang hoạt động - 1
                long otherActiveAdmins = userRepository.countByRoleAndStatus(ERole.admin, EUserStatus.active) - 1;
                return otherActiveAdmins < REQUIRED_APPROVALS ? "not_enough_admins" : null;
        }

        // Vote

        @Override
        @Transactional
        public AccountLockRequestResponse vote(String requestId, AccountLockVoteRequest req, String adminId) {
                EAccountLockVoteDecision decision = parseDecision(req.decision());

                // Khóa đề xuất ĐẦU TIÊN → các phiếu đồng thời được đếm tuần tự, không "kẹt" ở
                // 1/2
                AccountLockRequest request = requestRepository.findByIdForUpdate(requestId)
                                .orElseThrow(() -> new ResourceNotFoundException("lock_request.not_found"));
                if (!isOpen(request, LocalDateTime.now())) {
                        throw new BadRequestException("lock_request.closed");
                }
                if (Objects.equals(request.getProposer().getId(), adminId)) {
                        throw new BadRequestException("lock_request.self_vote");
                }
                if (voteRepository.existsByRequestIdAndVoterId(requestId, adminId)) {
                        throw new BadRequestException("lock_request.already_voted");
                }
                User voter = requireActiveAdmin(adminId);

                String comment = req.comment() != null && !req.comment().isBlank() ? req.comment().trim() : null;
                voteRepository.save(AccountLockVote.builder()
                                .request(request)
                                .voter(voter)
                                .decision(decision)
                                .comment(comment)
                                .build());

                logActivity(voter, request, decision == EAccountLockVoteDecision.approve
                                ? "activity.lock_request.voted_approve"
                                : "activity.lock_request.voted_reject",
                                displayName(voter), displayName(request.getTarget()));

                long approvals = voteRepository.countByRequestIdAndDecision(requestId,
                                EAccountLockVoteDecision.approve);
                long rejections = voteRepository.countByRequestIdAndDecision(requestId,
                                EAccountLockVoteDecision.reject);
                if (approvals >= REQUIRED_APPROVALS) {
                        approve(request, voter);
                } else if (rejections >= REQUIRED_REJECTIONS) {
                        resolve(request, EAccountLockRequestStatus.rejected, voter, "activity.lock_request.rejected");
                }

                return toDetail(request, adminId);
        }

        /**
         * Đủ bảo lãnh → khóa tài khoản, thu hồi mọi phiên, báo người dùng (chỉ kèm lý
         * do).
         */
        private void approve(AccountLockRequest request, User actor) {
                User target = request.getTarget();
                if (target.getStatus() == EUserStatus.active) {
                        target.setStatus(EUserStatus.blocked);
                        userRepository.save(target);
                        authenticationService.revokeUserAccess(target.getId());
                        notifier.notifyAccountLocked(target, request.getReason());
                }
                resolve(request, EAccountLockRequestStatus.approved, actor, "activity.lock_request.approved");
        }

        private void resolve(AccountLockRequest request, EAccountLockRequestStatus status, User actor,
                        String activityKey) {
                request.setStatus(status);
                request.setResolvedAt(LocalDateTime.now());
                requestRepository.save(request);
                logActivity(actor, request, activityKey, displayName(request.getTarget()));
                notifier.notifyResolved(request, stakeholders(request));
        }

        // Cancel / Expire

        @Override
        @Transactional
        public AccountLockRequestResponse cancel(String requestId, String adminId) {
                AccountLockRequest request = requestRepository.findByIdForUpdate(requestId)
                                .orElseThrow(() -> new ResourceNotFoundException("lock_request.not_found"));
                if (!Objects.equals(request.getProposer().getId(), adminId)) {
                        throw new BadRequestException("lock_request.not_proposer");
                }
                if (request.getStatus() != EAccountLockRequestStatus.pending) {
                        throw new BadRequestException("lock_request.closed");
                }
                request.setStatus(EAccountLockRequestStatus.cancelled);
                request.setResolvedAt(LocalDateTime.now());
                requestRepository.save(request);
                logActivity(request.getProposer(), request, "activity.lock_request.cancelled",
                                displayName(request.getProposer()), displayName(request.getTarget()));
                return toDetail(request, adminId);
        }

        @Override
        @Transactional
        public void expire(String requestId) {
                requestRepository.findByIdForUpdate(requestId).ifPresent(request -> {
                        // Có thể vừa được duyệt / hủy giữa lúc scheduler lấy danh sách và lúc khóa dòng
                        if (request.getStatus() != EAccountLockRequestStatus.pending
                                        || !request.getExpiresAt().isBefore(LocalDateTime.now())) {
                                return;
                        }
                        resolve(request, EAccountLockRequestStatus.expired, request.getProposer(),
                                        "activity.lock_request.expired");
                });
        }

        // Unlock

        @Override
        @Transactional
        public void unlockUser(String userId, UnlockUserRequest req, String adminId) {
                User target = userRepository.findByIdForUpdate(userId)
                                .filter(u -> u.getRole() == ERole.client)
                                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));
                if (target.getStatus() != EUserStatus.blocked) {
                        throw new BadRequestException("user.unlock.not_blocked");
                }
                User actor = requireActiveAdmin(adminId);

                target.setStatus(EUserStatus.active);
                userRepository.save(target);
                authenticationService.restoreUserAccess(target.getId());

                String reason = req.reason().trim();
                if (reason.length() > MAX_ACTIVITY_REASON_LENGTH) {
                        reason = reason.substring(0, MAX_ACTIVITY_REASON_LENGTH) + "…";
                }
                activityHistoryRepository.save(ActivityHistory.builder()
                                .actor(actor)
                                .i18nKey(activityKey("activity.user.unlocked", displayName(actor),
                                                displayName(target), reason))
                                .targetId(target.getId())
                                .build());
                notifier.notifyAccountUnlocked(target);
        }

        // Mapping

        private AccountLockRequestResponse toDetail(AccountLockRequest request, String adminId) {
                List<AccountLockVote> votes = voteRepository.findByRequestIdOrderByCreatedAtAsc(request.getId());
                List<AccountLockRequestResponse.Evidence> evidences = evidenceRepository
                                .findByRequestIdOrderByCreatedAtAsc(request.getId()).stream()
                                .map(AccountLockRequestServiceImpl::toEvidence)
                                .toList();

                return toSummary(request, votes, adminId)
                                .evidences(evidences)
                                .votes(votes.stream().map(v -> AccountLockRequestResponse.Vote.builder()
                                                .voter(toPerson(v.getVoter()))
                                                .decision(v.getDecision().name())
                                                .comment(v.getComment())
                                                .createdAt(v.getCreatedAt())
                                                .build()).toList())
                                .build();
        }

        private AccountLockRequestResponse.AccountLockRequestResponseBuilder toSummary(
                        AccountLockRequest request, List<AccountLockVote> votes, String adminId) {
                long approvals = votes.stream().filter(v -> v.getDecision() == EAccountLockVoteDecision.approve)
                                .count();
                long rejections = votes.size() - approvals;
                String myVote = votes.stream()
                                .filter(v -> Objects.equals(v.getVoter().getId(), adminId))
                                .map(v -> v.getDecision().name())
                                .findFirst().orElse(null);
                boolean mine = Objects.equals(request.getProposer().getId(), adminId);
                boolean open = isOpen(request, LocalDateTime.now());

                String voteBlockedReason = !open ? "closed"
                                : mine ? "proposer" : myVote != null ? "already_voted" : null;

                return AccountLockRequestResponse.builder()
                                .id(request.getId())
                                .status(request.getStatus().name())
                                .target(toPerson(request.getTarget()))
                                .proposer(toPerson(request.getProposer()))
                                .reason(request.getReason())
                                .approvals(approvals)
                                .rejections(rejections)
                                .requiredApprovals(REQUIRED_APPROVALS)
                                .requiredRejections(REQUIRED_REJECTIONS)
                                .createdAt(request.getCreatedAt())
                                .expiresAt(request.getExpiresAt())
                                .resolvedAt(request.getResolvedAt())
                                .myVote(myVote)
                                .mine(mine)
                                .canVote(voteBlockedReason == null)
                                .voteBlockedReason(voteBlockedReason)
                                .canCancel(mine && request.getStatus() == EAccountLockRequestStatus.pending);
        }

        private static AccountLockRequestResponse.Evidence toEvidence(AccountLockEvidence e) {
                AccountLockRequestResponse.Evidence.EvidenceBuilder builder = AccountLockRequestResponse.Evidence
                                .builder()
                                .id(e.getId())
                                .type(e.getType().name())
                                .imageUrl(e.getImageUrl());
                Report report = e.getReport();
                if (report != null) {
                        builder.reportId(report.getId())
                                        .reportTitle(report.getTitle())
                                        .reportStatus(report.getStatus() != null ? report.getStatus().name() : null)
                                        .reportCreatedAt(report.getCreatedAt());
                }
                return builder.build();
        }

        private static AccountLockRequestResponse.Person toPerson(User user) {
                if (user == null) {
                        return null;
                }
                return AccountLockRequestResponse.Person.builder()
                                .id(user.getId())
                                .fullName(user.getFullName())
                                .email(user.getEmail())
                                .avatarUrl(user.getAvatarUrl())
                                .status(user.getStatus() != null ? user.getStatus().name() : null)
                                .build();
        }

        // Helpers

        /**
         * Còn nhận phiếu: đang chờ và chưa quá hạn (scheduler có thể chưa kịp chuyển
         * sang expired).
         */
        private static boolean isOpen(AccountLockRequest request, LocalDateTime now) {
                return request.getStatus() == EAccountLockRequestStatus.pending && request.getExpiresAt().isAfter(now);
        }

        private User requireActiveAdmin(String adminId) {
                User admin = adminId == null ? null : userRepository.findById(adminId).orElse(null);
                if (admin == null || admin.getRole() != ERole.admin || admin.getStatus() != EUserStatus.active) {
                        throw new UnauthorizedException("auth.account.blocked");
                }
                return admin;
        }

        private List<User> activeAdmins() {
                return userRepository.findByRole(ERole.admin).stream()
                                .filter(u -> u.getStatus() == EUserStatus.active)
                                .toList();
        }

        /** Người đề xuất + những người đã bỏ phiếu (không trùng lặp). */
        private Collection<User> stakeholders(AccountLockRequest request) {
                Map<String, User> byId = new LinkedHashMap<>();
                byId.put(request.getProposer().getId(), request.getProposer());
                voteRepository.findByRequestIdOrderByCreatedAtAsc(request.getId())
                                .forEach(v -> byId.putIfAbsent(v.getVoter().getId(), v.getVoter()));
                return byId.values();
        }

        private static boolean isPublicReportOf(Report report, User target) {
                return report.getUser() != null
                                && Objects.equals(report.getUser().getId(), target.getId())
                                && !Boolean.TRUE.equals(report.getIsAnonymous());
        }

        private static Set<EAccountLockRequestStatus> resolveStatusFilter(String status) {
                if ("pending".equalsIgnoreCase(status)) {
                        return EnumSet.of(EAccountLockRequestStatus.pending);
                }
                if ("resolved".equalsIgnoreCase(status)) {
                        return EnumSet.complementOf(EnumSet.of(EAccountLockRequestStatus.pending));
                }
                return EnumSet.allOf(EAccountLockRequestStatus.class);
        }

        private static EAccountLockVoteDecision parseDecision(String decision) {
                if (decision == null || decision.isBlank()) {
                        throw new BadRequestException("lock_request.vote.decision_invalid");
                }
                try {
                        return EAccountLockVoteDecision.valueOf(decision.trim().toLowerCase());
                } catch (IllegalArgumentException e) {
                        throw new BadRequestException("lock_request.vote.decision_invalid");
                }
        }

        /** Bỏ phần tử rỗng, trim, loại trùng (giữ thứ tự). */
        private static List<String> normalize(List<String> values) {
                if (values == null) {
                        return List.of();
                }
                Set<String> unique = new LinkedHashSet<>();
                for (String v : values) {
                        if (v != null && !v.isBlank()) {
                                unique.add(v.trim());
                        }
                }
                return List.copyOf(unique);
        }

        private void logActivity(User actor, AccountLockRequest request, String key, String... args) {
                activityHistoryRepository.save(ActivityHistory.builder()
                                .actor(actor)
                                .i18nKey(activityKey(key, args))
                                .targetId(request.getId())
                                .build());
        }

        /**
         * "key|arg1|arg2" — bỏ ký tự '|' trong tham số (dấu phân tách) và chặn theo độ
         * dài cột.
         */
        static String activityKey(String key, String... args) {
                StringBuilder sb = new StringBuilder(key);
                for (String arg : args) {
                        sb.append('|').append(arg == null ? "" : arg.replace("|", " "));
                }
                return sb.length() > MAX_ACTIVITY_KEY_LENGTH ? sb.substring(0, MAX_ACTIVITY_KEY_LENGTH) : sb.toString();
        }

        private static String displayName(User user) {
                return AccountLockNotifier.displayName(user);
        }
}
