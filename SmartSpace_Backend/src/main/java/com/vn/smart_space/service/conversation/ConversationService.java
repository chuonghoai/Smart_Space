package com.vn.smart_space.service.conversation;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.springframework.context.MessageSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.EMessageType;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.conversation.CreateConversationRequest;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.chat.ChatMessageResponse;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.dto.response.conversation.ParticipantResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.mapper.ConversationMapper;
import com.vn.smart_space.model.ChatMessage;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.ConversationParticipant;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ChatMessageRepository;
import com.vn.smart_space.repository.ConversationParticipantRepository;
import com.vn.smart_space.repository.ConversationRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.chat.ChatPresenceService;
import com.vn.smart_space.service.notification.FCMService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConversationService implements IConversationService {

    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository conversationParticipantRepository;
    private final ReportRepository reportRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ChatPresenceService chatPresenceService;
    private final FCMService fcmService;
    private final MessageSource messageSource;

    @Override
    @Transactional
    public CreateConversationResponse createConversation(String creatorId, CreateConversationRequest request) {
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new BadRequestException("user.not_found"));

        // Case 1: Report-based conversation (Staff <-> Client)
        if (request.reportId() != null && !request.reportId().trim().isEmpty()) {
            Report report = reportRepository.findById(request.reportId())
                    .orElseThrow(() -> new BadRequestException("report.not_found"));

            User assignedStaff = report.getAssignedStaff();
            User clientUser = report.getUser();

            if (assignedStaff == null || clientUser == null) {
                throw new BadRequestException("conversation.report.participants_missing");
            }

            // Verify permission: creator must be assigned staff, report client, or admin
            boolean isAssignedStaff = creator.getId().equals(assignedStaff.getId());
            boolean isReportClient = creator.getId().equals(clientUser.getId());
            boolean isAdmin = creator.getRole() == ERole.admin;

            if (!isAssignedStaff && !isReportClient && !isAdmin) {
                throw new BadRequestException("auth.forbidden");
            }

            Conversation conversation = getOrCreateReportConversation(report);
            return ConversationMapper.toConversationResponse(creatorId, conversation);
        }

        // Case 2: General conversation (Staff <-> Staff, Staff <-> Admin, Admin <-> Admin, or Group)
        if (request.participantIds() == null || request.participantIds().isEmpty()) {
            throw new BadRequestException("conversation.participantIds.required");
        }

        List<String> participantIds = new ArrayList<>(request.participantIds());
        if (!participantIds.contains(creatorId)) {
            participantIds.add(creatorId);
        }

        List<User> participantInfos = userRepository.findAllById(participantIds);
        if (participantInfos.size() != participantIds.size()) {
            throw new BadRequestException("conversation.user.not_found");
        }

        EConversationType conversationType = request.conversationType();
        String participantHash = null;

        if (conversationType == EConversationType.PRIVATE) {
            if (participantIds.size() != 2) {
                throw new BadRequestException("conversation.private.participants_count");
            }

            User u1 = participantInfos.get(0);
            User u2 = participantInfos.get(1);

            // Rule: Staff and Client cannot chat privately outside of a report
            boolean hasStaff = u1.getRole() == ERole.staff || u2.getRole() == ERole.staff;
            boolean hasClient = u1.getRole() == ERole.client || u2.getRole() == ERole.client;
            if (hasStaff && hasClient) {
                throw new BadRequestException("conversation.client_staff_must_have_report");
            }

            participantHash = participantInfos.stream()
                    .map(User::getId)
                    .sorted()
                    .collect(Collectors.joining("_"));

            Optional<Conversation> existing = conversationRepository.findByParticipantHash(participantHash);
            if (existing.isPresent()) {
                return ConversationMapper.toConversationResponse(creatorId, existing.get());
            }
        } else if (conversationType == EConversationType.GROUP) {
            if (request.name() == null || request.name().trim().isEmpty()) {
                throw new BadRequestException("conversation.group.name_required");
            }
            if (participantIds.size() < 3) {
                throw new BadRequestException("conversation.group.participants_count");
            }
        }

        Conversation conversation = Conversation.builder()
                .name(request.name())
                .conversationType(conversationType)
                .conversationAvatar(request.conversationAvatar())
                .participantHash(participantHash)
                .createdAt(LocalDateTime.now())
                .build();

        participantInfos.forEach(conversation::addParticipants);
        conversationRepository.save(conversation);

        return ConversationMapper.toConversationResponse(creatorId, conversation);
    }

    @Override
    @Transactional
    public Conversation getOrCreateReportConversation(Report report) {
        if (report == null) return null;
        User assignedStaff = report.getAssignedStaff();
        User clientUser = report.getUser();
        if (assignedStaff == null || clientUser == null) {
            return null;
        }

        String participantHash = "report_" + report.getId() + "_" +
                Stream.of(assignedStaff.getId(), clientUser.getId())
                        .sorted()
                        .collect(Collectors.joining("_"));

        Optional<Conversation> existing = conversationRepository.findByParticipantHash(participantHash);
        if (existing.isPresent()) {
            return existing.get();
        }

        Optional<Conversation> byReport = conversationRepository.findByReportId(report.getId());
        if (byReport.isPresent()) {
            return byReport.get();
        }

        Conversation conversation = Conversation.builder()
                .name(report.getTitle())
                .conversationType(EConversationType.PRIVATE)
                .report(report)
                .participantHash(participantHash)
                .createdAt(LocalDateTime.now())
                .build();

        conversation.addParticipants(assignedStaff);
        conversation.addParticipants(clientUser);
        return conversationRepository.save(conversation);
    }

    @Override
    @Transactional
    public ChatMessage sendSystemMessage(Conversation conversation, String content, User targetUser) {
        if (conversation == null || content == null || content.trim().isEmpty()) {
            return null;
        }

        ChatMessage message = ChatMessage.builder()
                .conversation(conversation)
                .sender(null)
                .content(content.trim())
                .messageType(EMessageType.system)
                .sentAt(LocalDateTime.now())
                .build();
        message = chatMessageRepository.save(message);

        conversation.setLastMessageId(message.getId());
        conversation.setLastMessageContent(message.getContent());
        conversation.setLastMessageTime(message.getSentAt());
        conversationRepository.save(conversation);

        // Update unread count for target participant(s)
        for (ConversationParticipant cp : conversation.getParticipants()) {
            if (targetUser == null || cp.getUser().getId().equals(targetUser.getId())) {
                cp.setUnreadCount((cp.getUnreadCount() != null ? cp.getUnreadCount() : 0) + 1);
                conversationParticipantRepository.save(cp);
            }
        }

        // Broadcast realtime via WebSocket to conversation topic
        ChatMessageResponse response = ChatMessageResponse.builder()
                .id(message.getId())
                .conversationId(conversation.getId())
                .conversationAvatar(conversation.getConversationAvatar())
                .senderId(null)
                .senderName("System")
                .content(message.getContent())
                .messageType(EMessageType.system)
                .createdAt(message.getSentAt())
                .build();

        try {
            messagingTemplate.convertAndSend("/topic/conversation." + conversation.getId(), response);
        } catch (Exception e) {
            log.warn("Failed to broadcast system message to /topic/conversation.{}: {}", conversation.getId(), e.getMessage());
        }

        // Broadcast updated conversation to user queues
        for (ConversationParticipant cp : conversation.getParticipants()) {
            try {
                messagingTemplate.convertAndSendToUser(cp.getUser().getId(), "/queue/conversations",
                        ConversationMapper.toConversationDetailResponse(cp.getUser().getId(), conversation));
            } catch (Exception ignored) {
            }
        }

        // Send FCM to targetUser if provided and not viewing conversation
        if (targetUser != null && !chatPresenceService.isUserViewingConversation(targetUser.getId(), conversation.getId())) {
            try {
                String lang = targetUser.getLanguage() != null ? targetUser.getLanguage() : "vi";
                Locale locale = Locale.forLanguageTag(lang);
                String title = messageSource.getMessage("notification.chat.system.title", null, "SmartSpace", locale);
                Map<String, String> data = Map.of(
                        "type", "CHAT_DETAIL",
                        "payload", "{\"conversationId\":\"" + conversation.getId() + "\"}"
                );
                NotificationRequest fcmRequest = new NotificationRequest(title, message.getContent(), data);
                fcmService.sendToUser(targetUser.getId(), fcmRequest);
            } catch (Exception e) {
                log.error("Failed to send system FCM to user {}: {}", targetUser.getId(), e.getMessage());
            }
        }

        return message;
    }

    @Override
    @Transactional
    public void transferReportConversation(Report report, User oldStaff, User newStaff) {
        if (report == null || oldStaff == null || newStaff == null) return;
        Optional<Conversation> convOpt = conversationRepository.findByReportId(report.getId());
        if (convOpt.isEmpty()) return;

        Conversation conversation = convOpt.get();
        User clientUser = report.getUser();

        // 1. Update participantHash
        String newHash = "report_" + report.getId() + "_" +
                Stream.of(newStaff.getId(), clientUser.getId())
                        .sorted()
                        .collect(Collectors.joining("_"));
        conversation.setParticipantHash(newHash);

        // 2. Transfer participant: find participant record of oldStaff and update to newStaff
        for (ConversationParticipant cp : conversation.getParticipants()) {
            if (cp.getUser().getId().equals(oldStaff.getId())) {
                cp.setUser(newStaff);
                cp.setJoinedAt(LocalDateTime.now());
                cp.setUnreadCount(0);
                conversationParticipantRepository.save(cp);
                break;
            }
        }
        conversationRepository.save(conversation);

        // 3. Send system message about delegation transfer
        Locale clientLocale = Locale.forLanguageTag(clientUser.getLanguage() != null ? clientUser.getLanguage() : "vi");
        String oldName = oldStaff.getFullName() != null ? oldStaff.getFullName() : "Nhân viên";
        String newName = newStaff.getFullName() != null ? newStaff.getFullName() : "Nhân viên";
        String content = messageSource.getMessage("chat.system.delegation_transferred",
                new Object[]{ oldName, report.getTitle(), newName },
                String.format("%s đã chuyển giao phản ánh '%s' cho %s", oldName, report.getTitle(), newName),
                clientLocale);

        sendSystemMessage(conversation, content, clientUser);

        // Notify new staff as well
        try {
            messagingTemplate.convertAndSendToUser(newStaff.getId(), "/queue/conversations",
                    ConversationMapper.toConversationDetailResponse(newStaff.getId(), conversation));
            messagingTemplate.convertAndSendToUser(oldStaff.getId(), "/queue/conversations",
                    ConversationMapper.toConversationDetailResponse(oldStaff.getId(), conversation));
        } catch (Exception ignored) {
        }
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ConversationDetailResponse> getMyConversation(String userId, int page, int size, String role, String query) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);
        boolean hasQuery = query != null && !query.trim().isEmpty();
        String q = hasQuery ? query.trim() : null;

        Page<Conversation> conversationPage;
        if (role == null || role.trim().isEmpty() || "all".equalsIgnoreCase(role)) {
            conversationPage = hasQuery
                    ? conversationRepository.findAllByUserIdAndQuery(userId, q, pageable)
                    : conversationRepository.findAllByUserId(userId, pageable);
        } else {
            try {
                ERole eRole = ERole.valueOf(role.trim().toLowerCase());
                conversationPage = hasQuery
                        ? conversationRepository.findAllByUserIdAndRoleAndQuery(userId, eRole, q, pageable)
                        : conversationRepository.findAllByUserIdAndRole(userId, eRole, pageable);
            } catch (IllegalArgumentException e) {
                conversationPage = hasQuery
                        ? conversationRepository.findAllByUserIdAndQuery(userId, q, pageable)
                        : conversationRepository.findAllByUserId(userId, pageable);
            }
        }

        List<ConversationDetailResponse> responses = conversationPage.getContent().stream()
                .map(c -> ConversationMapper.toConversationDetailResponse(userId, c))
                .toList();

        return PageResponse.<ConversationDetailResponse>builder()
                .currentPage(page)
                .pageSize(pageable.getPageSize())
                .totalPages(conversationPage.getTotalPages())
                .totalElements(conversationPage.getTotalElements())
                .content(responses)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<ParticipantResponse> searchUsersForChat(String userId, String role, String query) {
        if (query == null || query.trim().isEmpty()) {
            return List.of();
        }
        String q = query.trim().toLowerCase();
        Pageable limit = PageRequest.of(0, 20);

        List<User> users;
        if ("staff".equalsIgnoreCase(role)) {
            users = userRepository.searchActiveUsersByRole(ERole.staff, userId, q, limit);
        } else if ("admin".equalsIgnoreCase(role)) {
            users = userRepository.searchActiveUsersByRole(ERole.admin, userId, q, limit);
        } else if ("client".equalsIgnoreCase(role)) {
            // STRICT PRIVACY RULE: Never search all clients in DB!
            return List.of();
        } else {
            // all: search staff and admin only
            users = userRepository.searchActiveStaffAndAdmins(userId, q, limit);
        }

        return users.stream()
                .map(ConversationMapper::toParticipantResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public ConversationDetailResponse getConversationDetail(String userId, String conversationId) {
        Conversation conversation = conversationRepository.findByIdAndMember(conversationId, userId)
                .orElseThrow(() -> new BadRequestException("conversation.not_found"));

        return ConversationMapper.toConversationDetailResponse(userId, conversation);
    }

    @Override
    @Transactional
    public void markAsRead(String userId, String conversationId) {
        Optional<ConversationParticipant> participantOpt = conversationParticipantRepository
                .findByConversationIdAndUserId(conversationId, userId);
        if (participantOpt.isPresent()) {
            ConversationParticipant participant = participantOpt.get();
            participant.setUnreadCount(0);
            participant.setLastReadAt(LocalDateTime.now());
            conversationParticipantRepository.save(participant);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Long getUnreadCount(String userId) {
        return conversationParticipantRepository.countTotalUnreadByUserId(userId);
    }

}
