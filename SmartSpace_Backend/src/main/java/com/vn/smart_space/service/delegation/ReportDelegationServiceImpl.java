package com.vn.smart_space.service.delegation;

import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.consts.EDelegationStatus;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.delegation.CreateDelegationRequest;
import com.vn.smart_space.dto.response.delegation.DelegationReportStateResponse;
import com.vn.smart_space.dto.response.delegation.DelegationResponse;
import com.vn.smart_space.dto.response.delegation.StaffColleagueResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.ReportDelegation;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ReportDelegationRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.i18n.MessageService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Nhờ làm giùm: chuyển giao task từ người được phân công (requester) sang đồng nghiệp (helper).
 */
@Slf4j
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ReportDelegationServiceImpl implements IReportDelegationService {

        static final int EXPIRY_HOURS = 24;
        static final int MAX_PAGE_SIZE = 50;
        static final List<EDelegationStatus> ACTIVE = List.of(EDelegationStatus.PENDING, EDelegationStatus.ACCEPTED);

        ReportDelegationRepository delegationRepository;
        ReportRepository reportRepository;
        UserRepository userRepository;
        MessageService messageService;
        DelegationNotifier notifier;
        com.vn.smart_space.service.conversation.IConversationService conversationService;

        // Đọc

        @Override
        @Transactional(readOnly = true)
        public PageResponse<StaffColleagueResponse> searchColleagues(String staffId, String search, int page,
                        int size) {
                String keyword = search != null && !search.isBlank() ? search.trim() : null;
                Page<User> result = userRepository.searchColleagues(ERole.staff, EUserStatus.active, staffId, keyword,
                                PageRequest.of(Math.max(0, page), clampSize(size)));
                return PageResponse.<StaffColleagueResponse>builder()
                                .currentPage(result.getNumber())
                                .pageSize(result.getSize())
                                .totalPages(result.getTotalPages())
                                .totalElements(result.getTotalElements())
                                .content(result.getContent().stream().map(this::toColleague).toList())
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public DelegationReportStateResponse getReportState(String staffId, String reportId) {
                Report report = reportRepository.findById(reportId)
                                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

                // Chỉ người nhờ / người được nhờ mới thấy yêu cầu của report
                ReportDelegation active = findActive(report.getId())
                                .filter(d -> isParticipant(d, staffId))
                                .orElse(null);
                // Đã hoàn tất thì không còn yêu cầu đang hoạt động (task đã nhận hoa hồng không nhờ lại được)
                ReportDelegation completed = active != null ? null
                                : delegationRepository.findFirstByReportIdAndStatusInOrderByCreatedAtDesc(
                                                report.getId(), List.of(EDelegationStatus.COMPLETED))
                                                .filter(d -> isParticipant(d, staffId))
                                                .orElse(null);
                ReportDelegation shown = active != null ? active : completed;
                String viewerRole = shown == null ? null
                                : staffId.equals(shown.getRequester().getId()) ? "REQUESTER" : "HELPER";

                String reasonCode = active != null ? "delegation.already_active" : eligibilityError(report, staffId);

                return DelegationReportStateResponse.builder()
                                .canRequest(reasonCode == null)
                                .reasonCode(reasonCode)
                                .reason(reasonCode != null ? messageService.get(reasonCode) : null)
                                .severity(report.getSeverity() != null ? report.getSeverity().name() : null)
                                .activeDelegation(active != null ? toResponse(active) : null)
                                .completedDelegation(completed != null ? toResponse(completed) : null)
                                .viewerRole(viewerRole)
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public PageResponse<DelegationResponse> list(String staffId, String box, int page, int size) {
                PageRequest pageable = PageRequest.of(Math.max(0, page), clampSize(size));
                Page<ReportDelegation> result = switch (box == null ? "" : box.trim().toLowerCase()) {
                        case "received" -> delegationRepository.findByHelperIdOrderByCreatedAtDesc(staffId, pageable);
                        case "sent" -> delegationRepository.findByRequesterIdOrderByCreatedAtDesc(staffId, pageable);
                        default -> throw new BadRequestException("delegation.invalid_box");
                };
                return PageResponse.<DelegationResponse>builder()
                                .currentPage(result.getNumber())
                                .pageSize(result.getSize())
                                .totalPages(result.getTotalPages())
                                .totalElements(result.getTotalElements())
                                .content(result.getContent().stream().map(this::toResponse).toList())
                                .build();
        }

        // Ghi (thao tác của staff)

        @Override
        @Transactional
        public DelegationResponse create(String requesterId, CreateDelegationRequest request) {
                // Khoá report: hai yêu cầu song song cho cùng task không thể cùng qua kiểm tra
                // "chưa có yêu cầu"
                Report report = reportRepository.findByIdForUpdate(request.getReportId())
                                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

                if (report.getAssignedStaff() == null || !requesterId.equals(report.getAssignedStaff().getId())) {
                        throw new AccessDeniedException("delegation.not_assignee");
                }
                String error = eligibilityError(report, requesterId);
                if (error != null)
                        throw new BadRequestException(error);
                if (findActive(report.getId()).isPresent())
                        throw new BadRequestException("delegation.already_active");

                if (requesterId.equals(request.getHelperId()))
                        throw new BadRequestException("delegation.self_not_allowed");
                User helper = userRepository.findByIdAndRole(request.getHelperId(), ERole.staff)
                                .orElseThrow(() -> new ResourceNotFoundException("delegation.helper_not_found"));
                if (helper.getStatus() != EUserStatus.active)
                        throw new BadRequestException("delegation.helper_inactive");

                User requester = report.getAssignedStaff();

                String note = request.getNote() != null && !request.getNote().isBlank() ? request.getNote().trim()
                                : null;
                ReportDelegation delegation = delegationRepository.save(ReportDelegation.builder()
                                .report(report)
                                .requester(requester)
                                .helper(helper)
                                .status(EDelegationStatus.PENDING)
                                .severity(report.getSeverity())
                                .note(note)
                                .expiresAt(LocalDateTime.now().plusHours(EXPIRY_HOURS))
                                .build());

                notifier.notify(helper, "notification.delegation.requested.title",
                                "notification.delegation.requested.message",
                                new Object[] { nameOf(requester), report.getTitle() },
                                delegation.getId(), report.getId(), report.getImageUrl());

                return toResponse(delegation);
        }

        @Override
        @Transactional
        public DelegationResponse accept(String helperId, String delegationId) {
                // Khoá report trước rồi mới tới yêu cầu, cùng thứ tự với hoàn tất / phân công report → không deadlock.
                // Chỉ đọc report id (không nạp entity) để lần khoá yêu cầu bên dưới đọc trạng thái mới nhất.
                String reportId = delegationRepository.findReportIdById(delegationId)
                                .orElseThrow(() -> new ResourceNotFoundException("delegation.not_found"));
                Report report = reportRepository.findByIdForUpdate(reportId)
                                .orElseThrow(() -> new ResourceNotFoundException("report.not_found"));

                ReportDelegation delegation = lockOwnPending(delegationId, helperId, true);
                if (delegation.getExpiresAt().isBefore(LocalDateTime.now())) {
                        throw new BadRequestException("delegation.expired");
                }

                // Phòng hờ: admin đã đổi người/trạng thái mà hook chưa kịp thu hồi
                boolean stillRequesterTask = report.getStatus() == EReportStatus.processing
                                && report.getAssignedStaff() != null
                                && report.getAssignedStaff().getId().equals(delegation.getRequester().getId());
                if (!stillRequesterTask)
                        throw new BadRequestException("delegation.report_changed");

                report.setAssignedStaff(delegation.getHelper());
                report.setAssignedAt(new java.util.Date());
                report.setAssignmentSource(EAssignmentSource.DELEGATION);
                reportRepository.save(report);

                // Transfer conversation to helper
                try {
                        conversationService.transferReportConversation(report, delegation.getRequester(), delegation.getHelper());
                } catch (Exception e) {
                        log.error("Failed to transfer report conversation on delegation accept: {}", e.getMessage());
                }

                delegation.setStatus(EDelegationStatus.ACCEPTED);
                delegation.setRespondedAt(LocalDateTime.now());
                delegationRepository.save(delegation);

                notifier.notify(delegation.getRequester(), "notification.delegation.accepted.title",
                                "notification.delegation.accepted.message",
                                new Object[] { nameOf(delegation.getHelper()), report.getTitle() },
                                delegation.getId(), report.getId(), report.getImageUrl());

                return toResponse(delegation);
        }

        @Override
        @Transactional
        public DelegationResponse decline(String helperId, String delegationId) {
                ReportDelegation delegation = lockOwnPending(delegationId, helperId, true);
                closeDelegation(delegation, EDelegationStatus.DECLINED);

                notifier.notify(delegation.getRequester(), "notification.delegation.declined.title",
                                "notification.delegation.declined.message",
                                new Object[] { nameOf(delegation.getHelper()), delegation.getReport().getTitle() },
                                delegation.getId(), delegation.getReport().getId(),
                                delegation.getReport().getImageUrl());

                return toResponse(delegation);
        }

        @Override
        @Transactional
        public DelegationResponse cancel(String requesterId, String delegationId) {
                ReportDelegation delegation = lockOwnPending(delegationId, requesterId, false);
                closeDelegation(delegation, EDelegationStatus.CANCELLED);

                notifier.notify(delegation.getHelper(), "notification.delegation.cancelled.title",
                                "notification.delegation.cancelled.message",
                                new Object[] { nameOf(delegation.getRequester()), delegation.getReport().getTitle() },
                                delegation.getId(), delegation.getReport().getId(),
                                delegation.getReport().getImageUrl());

                return toResponse(delegation);
        }

        // Hook từ luồng report

        @Override
        @Transactional
        public void onReportCompleted(Report report) {
                Optional<ReportDelegation> found = findActive(report.getId());
                if (found.isEmpty())
                        return;
                ReportDelegation delegation = delegationRepository.findByIdForUpdate(found.get().getId()).orElseThrow();

                if (delegation.getStatus() == EDelegationStatus.PENDING) {
                        // Người nhờ tự hoàn tất trước khi có ai nhận → không còn gì để nhờ
                        closeDelegation(delegation, EDelegationStatus.REVOKED);
                        notifyRevoked(delegation);
                        return;
                }
                if (delegation.getStatus() != EDelegationStatus.ACCEPTED)
                        return;

                delegation.setStatus(EDelegationStatus.COMPLETED);
                delegation.setCompletedAt(LocalDateTime.now());
                delegationRepository.save(delegation);

                String title = report.getTitle();
                notifier.notify(delegation.getRequester(), "notification.delegation.completed.title",
                                "notification.delegation.completed.message",
                                new Object[] { nameOf(delegation.getHelper()), title },
                                delegation.getId(), report.getId(), report.getImageUrl());
        }

        @Override
        @Transactional
        public void onReportUnassigned(Report report) {
                Optional<ReportDelegation> found = findActive(report.getId());
                if (found.isEmpty())
                        return;
                ReportDelegation delegation = delegationRepository.findByIdForUpdate(found.get().getId()).orElseThrow();
                if (!delegation.getStatus().isActive())
                        return;

                closeDelegation(delegation, EDelegationStatus.REVOKED);
                notifyRevoked(delegation);
        }

        @Override
        @Transactional
        public void expire(String delegationId) {
                ReportDelegation delegation = delegationRepository.findByIdForUpdate(delegationId).orElse(null);
                // Có thể đã được trả lời ngay trước khi job chạy tới
                if (delegation == null || delegation.getStatus() != EDelegationStatus.PENDING
                                || delegation.getExpiresAt().isAfter(LocalDateTime.now())) {
                        return;
                }
                closeDelegation(delegation, EDelegationStatus.EXPIRED);

                Object[] args = { delegation.getReport().getTitle() };
                notifier.notify(delegation.getRequester(), "notification.delegation.expired.title",
                                "notification.delegation.expired.requester.message", args,
                                delegation.getId(), delegation.getReport().getId(),
                                delegation.getReport().getImageUrl());
                notifier.notify(delegation.getHelper(), "notification.delegation.expired.title",
                                "notification.delegation.expired.helper.message",
                                new Object[] { delegation.getReport().getTitle() },
                                delegation.getId(), delegation.getReport().getId(),
                                delegation.getReport().getImageUrl());
        }

        // Helpers

        /**
         * Lý do report không nhờ được (null = nhờ được), chưa xét yêu cầu đang hoạt động.
         */
        private String eligibilityError(Report report, String staffId) {
                if (report.getAssignedStaff() == null || !staffId.equals(report.getAssignedStaff().getId())) {
                        return "delegation.not_assignee";
                }
                if (report.getStatus() != EReportStatus.processing)
                        return "delegation.report_not_processing";
                // Đã từng hoàn tất ít nhất một lần (đang xử lý lại) → không nhờ được
                if (report.getResolvedAt() != null || Boolean.FALSE.equals(report.getIsReviewResolved()))
                        return "delegation.report_rehandling";
                if (report.getSeverity() == null)
                        return "delegation.severity_missing";
                return null;
        }

        private static boolean isParticipant(ReportDelegation delegation, String staffId) {
                return staffId.equals(delegation.getRequester().getId()) || staffId.equals(delegation.getHelper().getId());
        }

        private Optional<ReportDelegation> findActive(String reportId) {
                return delegationRepository.findFirstByReportIdAndStatusInOrderByCreatedAtDesc(reportId, ACTIVE);
        }

        /**
         * Khoá yêu cầu PENDING mà staff là người được nhờ ([asHelper]) hoặc người nhờ.
         */
        private ReportDelegation lockOwnPending(String delegationId, String staffId, boolean asHelper) {
                ReportDelegation delegation = delegationRepository.findByIdForUpdate(delegationId)
                                .orElseThrow(() -> new ResourceNotFoundException("delegation.not_found"));
                User owner = asHelper ? delegation.getHelper() : delegation.getRequester();
                if (!staffId.equals(owner.getId()))
                        throw new AccessDeniedException("delegation.forbidden");
                if (delegation.getStatus() != EDelegationStatus.PENDING)
                        throw new BadRequestException("delegation.not_pending");
                return delegation;
        }

        /** Đóng yêu cầu chưa thành. */
        private void closeDelegation(ReportDelegation delegation, EDelegationStatus status) {
                delegation.setStatus(status);
                if (delegation.getRespondedAt() == null)
                        delegation.setRespondedAt(LocalDateTime.now());
                delegationRepository.save(delegation);
        }

        private void notifyRevoked(ReportDelegation delegation) {
                Report report = delegation.getReport();
                notifier.notify(delegation.getRequester(), "notification.delegation.revoked.title",
                                "notification.delegation.revoked.requester.message",
                                new Object[] { report.getTitle() },
                                delegation.getId(), report.getId(), report.getImageUrl());
                notifier.notify(delegation.getHelper(), "notification.delegation.revoked.title",
                                "notification.delegation.revoked.helper.message", new Object[] { report.getTitle() },
                                delegation.getId(), report.getId(), report.getImageUrl());
        }

        private static int clampSize(int size) {
                return Math.max(1, Math.min(size, MAX_PAGE_SIZE));
        }

        private String nameOf(User user) {
                return user.getFullName() != null && !user.getFullName().isBlank()
                                ? user.getFullName()
                                : messageService.get("common.staff");
        }

        private StaffColleagueResponse toColleague(User user) {
                return StaffColleagueResponse.builder()
                                .id(user.getId())
                                .fullName(user.getFullName())
                                .avatarUrl(user.getAvatarUrl())
                                .positionName(user.getPosition() != null ? user.getPosition().getName() : null)
                                .build();
        }

        private DelegationResponse toResponse(ReportDelegation d) {
                Report report = d.getReport();
                String address = report.getAddress() != null && !report.getAddress().isBlank()
                                ? report.getAddress()
                                : report.getLocationDescription();
                return DelegationResponse.builder()
                                .id(d.getId())
                                .status(d.getStatus().name())
                                .reportId(report.getId())
                                .reportTitle(report.getTitle())
                                .reportImageUrl(report.getImageUrl())
                                .reportAddress(address)
                                .reportStatus(report.getStatus() != null ? report.getStatus().name() : null)
                                .severity(d.getSeverity() != null ? d.getSeverity().name() : null)
                                .requester(toColleague(d.getRequester()))
                                .helper(toColleague(d.getHelper()))
                                .note(d.getNote())
                                .expiresAt(d.getExpiresAt())
                                .respondedAt(d.getRespondedAt())
                                .completedAt(d.getCompletedAt())
                                .createdAt(d.getCreatedAt())
                                .build();
        }
}
