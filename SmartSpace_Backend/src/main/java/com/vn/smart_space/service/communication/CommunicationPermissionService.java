package com.vn.smart_space.service.communication;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.ConversationParticipant;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ConversationRepository;
import com.vn.smart_space.repository.ReportRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class CommunicationPermissionService implements ICommunicationPermissionService {

    private final ReportRepository reportRepository;
    private final ConversationRepository conversationRepository;

    @Override
    @Transactional(readOnly = true)
    public CommunicationEligibility evaluatePairEligibility(
            User actor,
            User target,
            String conversationId,
            Boolean requestedAnonymous) {
        if (actor == null || target == null) {
            return CommunicationEligibility.denied("user.not_found");
        }
        if (Objects.equals(actor.getId(), target.getId())) {
            return CommunicationEligibility.denied("call.permission.self_not_allowed");
        }
        if (actor.getStatus() != EUserStatus.active || target.getStatus() != EUserStatus.active) {
            return CommunicationEligibility.denied("auth.account.blocked");
        }

        ERole r1 = actor.getRole();
        ERole r2 = target.getRole();

        // Client <-> Client: completely forbidden
        if (r1 == ERole.client && r2 == ERole.client) {
            return CommunicationEligibility.denied("conversation.client_client_forbidden");
        }

        // Staff <-> Staff, Staff <-> Admin, Admin <-> Admin: always allowed
        if (r1 != ERole.client && r2 != ERole.client) {
            return CommunicationEligibility.allowed(false, 0);
        }

        // One side is Client, the other is Staff or Admin
        User client = r1 == ERole.client ? actor : target;
        User other = r1 == ERole.client ? target : actor;

        if (other.getRole() == ERole.admin) {
            // If conversationId is provided, respect its anonymity context when requestedAnonymous is null
            Boolean effectiveAnon = requestedAnonymous;
            if (effectiveAnon == null && conversationId != null && !conversationId.isBlank()) {
                Optional<Conversation> convOpt = conversationRepository.findByIdAndMember(conversationId, actor.getId());
                if (convOpt.isPresent()) {
                    effectiveAnon = Boolean.TRUE.equals(convOpt.get().getIsAnonymous());
                }
            }
            return evaluateAdminClientEligibility(client.getId(), effectiveAnon);
        }

        // Client <-> Staff: reuse exact existing conversation unlock logic
        if (conversationId != null && !conversationId.isBlank()) {
            Optional<Conversation> convOpt = conversationRepository.findByIdAndMember(conversationId, actor.getId());
            if (convOpt.isPresent()) {
                return evaluateConversationEligibility(actor.getId(), convOpt.get());
            }
        }

        List<Report> activeReports = requestedAnonymous != null
                ? reportRepository.findActiveReportsByClientAndStaffAndAnonymous(client.getId(), other.getId(), requestedAnonymous)
                : reportRepository.findActiveReportsByClientAndStaff(client.getId(), other.getId());

        if (activeReports.isEmpty()) {
            return CommunicationEligibility.denied("chat.report.not_processing");
        }

        boolean isAnon;
        if (requestedAnonymous != null) {
            isAnon = requestedAnonymous;
        } else {
            boolean hasIdentified = activeReports.stream().anyMatch(r -> !Boolean.TRUE.equals(r.getIsAnonymous()));
            isAnon = !hasIdentified;
        }
        return CommunicationEligibility.allowed(isAnon, activeReports.size());
    }

    @Override
    @Transactional(readOnly = true)
    public CommunicationEligibility evaluateAdminClientEligibility(String clientId, Boolean requestedAnonymous) {
        if (clientId == null || clientId.isBlank()) {
            return CommunicationEligibility.denied("conversation.admin_client_rehandling_required");
        }

        if (requestedAnonymous != null) {
            long count = reportRepository.countAdminRehandlingProcessingReportsByClient(clientId, requestedAnonymous);
            if (count <= 0) {
                return CommunicationEligibility.denied("conversation.admin_client_rehandling_required");
            }
            return CommunicationEligibility.allowed(requestedAnonymous, count);
        }

        long identifiedCount = reportRepository.countAdminRehandlingProcessingReportsByClient(clientId, false);
        long anonymousCount = reportRepository.countAdminRehandlingProcessingReportsByClient(clientId, true);
        long total = identifiedCount + anonymousCount;

        if (total <= 0) {
            return CommunicationEligibility.denied("conversation.admin_client_rehandling_required");
        }

        boolean isAnonOnly = identifiedCount == 0 && anonymousCount > 0;
        return CommunicationEligibility.allowed(isAnonOnly, total);
    }

    @Override
    @Transactional(readOnly = true)
    public CommunicationEligibility evaluateConversationEligibility(String currentUserId, Conversation conversation) {
        if (conversation == null) {
            return CommunicationEligibility.denied("conversation.not_found");
        }

        if (conversation.getConversationType() == EConversationType.GROUP) {
            boolean anyClient = conversation.getParticipants().stream()
                    .map(ConversationParticipant::getUser)
                    .filter(Objects::nonNull)
                    .anyMatch(u -> u.getRole() == ERole.client);
            if (anyClient) {
                return CommunicationEligibility.denied("conversation.client_group_forbidden");
            }
            return CommunicationEligibility.allowed(false, 0);
        }

        List<User> users = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(Objects::nonNull)
                .toList();

        if (users.size() != 2) {
            return CommunicationEligibility.allowed(false, 0);
        }

        User u1 = users.get(0);
        User u2 = users.get(1);

        if (u1.getRole() == ERole.client && u2.getRole() == ERole.client) {
            return CommunicationEligibility.denied("conversation.client_client_forbidden");
        }

        if (u1.getRole() != ERole.client && u2.getRole() != ERole.client) {
            return CommunicationEligibility.allowed(false, 0);
        }

        User client = u1.getRole() == ERole.client ? u1 : u2;
        User other = u1.getRole() == ERole.client ? u2 : u1;

        if (other.getRole() == ERole.admin) {
            boolean isAnon = Boolean.TRUE.equals(conversation.getIsAnonymous());
            return evaluateAdminClientEligibility(client.getId(), isAnon);
        }

        // Client <-> Staff: preserve exact existing unlock logic
        boolean isAnon = isConversationAnonymous(conversation, client);
        List<Report> activeReports = reportRepository.findActiveReportsByConversationId(conversation.getId());
        if (activeReports.isEmpty() && conversation.getReport() != null) {
            Report single = conversation.getReport();
            if (isReportActiveForClientStaff(single)) {
                activeReports = List.of(single);
            }
        }
        if (activeReports.isEmpty()) {
            // Fallback to context-specific client+staff check matching existing ConversationService behavior
            activeReports = reportRepository.findActiveReportsByClientAndStaffAndAnonymous(
                    client.getId(), other.getId(), isAnon);
        }

        if (activeReports.isEmpty()) {
            return new CommunicationEligibility(false, false, isAnon, "chat.report.not_processing", 0);
        }
        return CommunicationEligibility.allowed(isAnon, activeReports.size());
    }

    @Override
    @Transactional(readOnly = true)
    public void assertCanSendMessage(User sender, Conversation conversation) {
        if (sender == null || conversation == null) {
            throw new BadRequestException("chat.permission_denied");
        }
        if (sender.getStatus() != EUserStatus.active) {
            throw new BadRequestException("auth.account.blocked");
        }
        CommunicationEligibility eligibility = evaluateConversationEligibility(sender.getId(), conversation);
        if (!eligibility.canMessage()) {
            throw new BadRequestException(
                    eligibility.reasonCode() != null ? eligibility.reasonCode() : "chat.permission_denied");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Report> validateAndResolveAttachableReports(User sender, Conversation conversation, List<String> reportIds) {
        if (reportIds == null || reportIds.isEmpty()) {
            return List.of();
        }

        Set<String> uniqueIds = reportIds.stream()
                .filter(Objects::nonNull)
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toCollection(LinkedHashSet::new));

        if (uniqueIds.isEmpty()) {
            return List.of();
        }

        if (conversation.getConversationType() != EConversationType.PRIVATE) {
            throw new BadRequestException("chat.report.invalid_attachment");
        }

        List<User> participants = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(Objects::nonNull)
                .toList();
        if (participants.size() != 2) {
            throw new BadRequestException("chat.report.invalid_attachment");
        }

        User client = participants.stream().filter(u -> u.getRole() == ERole.client).findFirst().orElse(null);
        User other = participants.stream().filter(u -> u.getRole() != ERole.client).findFirst().orElse(null);
        if (client == null || other == null) {
            throw new BadRequestException("chat.report.invalid_attachment");
        }

        boolean convAnonymous = isConversationAnonymous(conversation, client);
        List<Report> resolved = new ArrayList<>();

        for (String reportId : uniqueIds) {
            Report report = reportRepository.findById(reportId)
                    .orElseThrow(() -> new BadRequestException("report.not_found"));

            if (report.getUser() == null || !Objects.equals(report.getUser().getId(), client.getId())) {
                throw new BadRequestException("chat.report.invalid_attachment");
            }

            boolean reportAnon = Boolean.TRUE.equals(report.getIsAnonymous());
            if (reportAnon != convAnonymous) {
                throw new BadRequestException("chat.report.invalid_attachment");
            }

            if (other.getRole() == ERole.admin) {
                if (!Boolean.FALSE.equals(report.getIsReviewResolved())
                        || report.getStatus() != EReportStatus.processing) {
                    throw new BadRequestException("chat.report.invalid_attachment");
                }
            } else if (other.getRole() == ERole.staff) {
                if (report.getAssignedStaff() == null
                        || !Objects.equals(report.getAssignedStaff().getId(), other.getId())
                        || !isReportActiveForClientStaff(report)) {
                    throw new BadRequestException("chat.report.invalid_attachment");
                }
            } else {
                throw new BadRequestException("chat.report.invalid_attachment");
            }

            resolved.add(report);
        }

        return resolved;
    }

    @Override
    public boolean isAdminClientConversation(Conversation conversation) {
        if (conversation == null || conversation.getConversationType() != EConversationType.PRIVATE) {
            return false;
        }
        List<ERole> roles = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(Objects::nonNull)
                .map(User::getRole)
                .toList();
        return roles.size() == 2 && roles.contains(ERole.admin) && roles.contains(ERole.client);
    }

    public static String buildAdminClientParticipantHash(String adminId, String clientId, boolean isAnonymous) {
        String sorted = Stream.of(adminId, clientId).sorted().collect(Collectors.joining("_"));
        return (isAnonymous ? "admin_anon_" : "admin_user_") + sorted;
    }

    private boolean isReportActiveForClientStaff(Report report) {
        return report.getStatus() == EReportStatus.processing
                || (report.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(report.getIsReviewResolved()));
    }

    private boolean isConversationAnonymous(Conversation conversation, User client) {
        if (Boolean.TRUE.equals(conversation.getIsAnonymous())) {
            return true;
        }
        if (conversation.getParticipantHash() != null
                && (conversation.getParticipantHash().startsWith("anon_")
                        || conversation.getParticipantHash().startsWith("admin_anon_"))) {
            return true;
        }
        if (conversation.getReport() != null && Boolean.TRUE.equals(conversation.getReport().getIsAnonymous())) {
            return true;
        }
        if (conversation.getReports() != null
                && conversation.getReports().stream().anyMatch(r -> Boolean.TRUE.equals(r.getIsAnonymous()))) {
            return true;
        }
        return false;
    }
}
