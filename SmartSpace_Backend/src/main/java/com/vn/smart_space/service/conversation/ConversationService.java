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
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.conversation.CreateConversationRequest;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.chat.ChatMessageResponse;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.ConversationInfoResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.dto.response.conversation.LinkedReportResponse;
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

            // Rule 1: Two clients cannot chat privately with each other
            if (u1.getRole() == ERole.client && u2.getRole() == ERole.client) {
                throw new BadRequestException("conversation.client_client_forbidden");
            }

            // Rule 2: Staff and Client cannot chat privately outside of a report
            boolean hasStaff = u1.getRole() == ERole.staff || u2.getRole() == ERole.staff;
            boolean hasClient = u1.getRole() == ERole.client || u2.getRole() == ERole.client;
            if (hasStaff && hasClient) {
                throw new BadRequestException("conversation.client_staff_must_have_report");
            }

            // Rule 3: Admin and Client cannot chat privately outside of a report
            boolean hasAdmin = u1.getRole() == ERole.admin || u2.getRole() == ERole.admin;
            if (hasAdmin && hasClient) {
                throw new BadRequestException("conversation.admin_client_direct_forbidden");
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
            boolean anyClient = participantInfos.stream().anyMatch(u -> u.getRole() == ERole.client);
            if (anyClient) {
                throw new BadRequestException("conversation.client_group_forbidden");
            }
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

        boolean isReportAnon = Boolean.TRUE.equals(report.getIsAnonymous());
        String prefix = isReportAnon ? "anon_" : "user_";
        String sortedUsers = Stream.of(assignedStaff.getId(), clientUser.getId())
                .sorted()
                .collect(Collectors.joining("_"));
        String participantHash = prefix + sortedUsers;

        // Check if an existing conversation exists with this hash
        Optional<Conversation> existing = conversationRepository.findByParticipantHash(participantHash);
        Conversation conversation;
        if (existing.isPresent()) {
            conversation = existing.get();
        } else {
            conversation = Conversation.builder()
                    .name(isReportAnon ? "Người dùng ẩn danh" : (clientUser.getFullName() != null ? clientUser.getFullName() : "Trò chuyện"))
                    .conversationType(EConversationType.PRIVATE)
                    .participantHash(participantHash)
                    .isAnonymous(isReportAnon)
                    .createdAt(LocalDateTime.now())
                    .build();

            conversation.addParticipants(assignedStaff);
            conversation.addParticipants(clientUser);
        }

        // Associate report with this conversation (both sides)
        conversation.setReport(report);
        if (conversation.getReports() == null) {
            conversation.setReports(new ArrayList<>());
        }
        if (!conversation.getReports().contains(report)) {
            conversation.getReports().add(report);
        }
        conversation = conversationRepository.save(conversation);

        report.setConversation(conversation);
        reportRepository.save(report);

        return conversation;
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

        // Send FCM to targetUser if provided and not viewing conversation or viewing conversation list
        if (targetUser != null
                && !chatPresenceService.isUserViewingConversation(targetUser.getId(), conversation.getId())
                && !chatPresenceService.isUserViewingConversation(targetUser.getId(), "list")) {
            try {
                String lang = targetUser.getLanguage() != null ? targetUser.getLanguage() : "vi";
                Locale locale = Locale.forLanguageTag(lang);
                String title = messageSource.getMessage("notification.chat.system.title", null, "SmartSpace", locale);
                Map<String, String> data = Map.of(
                        "type", "CHAT_DETAIL",
                        "payload", "{\"conversationId\":\"" + conversation.getId() + "\"}"
                );
                NotificationRequest fcmRequest = new NotificationRequest(title, message.getContent(), data);
                final String targetUserId = targetUser.getId();
                java.util.concurrent.CompletableFuture.runAsync(() -> {
                    try {
                        fcmService.sendToUser(targetUserId, fcmRequest);
                    } catch (Exception e) {
                        log.error("Failed to send system FCM to user {}: {}", targetUserId, e.getMessage());
                    }
                });
            } catch (Exception e) {
                log.error("Failed to prepare system FCM to user {}: {}", targetUser.getId(), e.getMessage());
            }
        }

        return message;
    }

    @Override
    @Transactional
    public void transferReportConversation(Report report, User oldStaff, User newStaff) {
        if (report == null || oldStaff == null || newStaff == null) return;
        Conversation oldConv = report.getConversation();
        User clientUser = report.getUser();

        // 1. Create or get conversation for newStaff and clientUser
        Conversation newConv = getOrCreateReportConversation(report);

        // 2. Send system message about delegation transfer to old conversation (if exists)
        Locale clientLocale = Locale.forLanguageTag(clientUser.getLanguage() != null ? clientUser.getLanguage() : "vi");
        String oldName = oldStaff.getFullName() != null ? oldStaff.getFullName() : "Nhân viên";
        String newName = newStaff.getFullName() != null ? newStaff.getFullName() : "Nhân viên";
        String content = messageSource.getMessage("chat.system.delegation_transferred",
                new Object[]{ oldName, report.getTitle(), newName },
                String.format("%s đã chuyển giao phản ánh '%s' cho %s", oldName, report.getTitle(), newName),
                clientLocale);

        if (oldConv != null) {
            sendSystemMessage(oldConv, content, clientUser);
        }

        // 3. Send system message in new conversation
        if (newConv != null) {
            String newAssignMsg = messageSource.getMessage("chat.system.report_assigned",
                    new Object[]{ newName, report.getTitle() },
                    String.format("%s đã tiếp nhận phản ánh '%s'", newName, report.getTitle()),
                    clientLocale);
            sendSystemMessage(newConv, newAssignMsg, clientUser);
        }

        // Notify both staff
        try {
            if (newConv != null) {
                messagingTemplate.convertAndSendToUser(newStaff.getId(), "/queue/conversations",
                        ConversationMapper.toConversationDetailResponse(newStaff.getId(), newConv));
            }
            if (oldConv != null) {
                messagingTemplate.convertAndSendToUser(oldStaff.getId(), "/queue/conversations",
                        ConversationMapper.toConversationDetailResponse(oldStaff.getId(), oldConv));
            }
        } catch (Exception ignored) {
        }
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ConversationDetailResponse> getMyConversation(String userId, int page, int size, String role, List<String> positionIds, String query) {
        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);
        boolean hasQuery = query != null && !query.trim().isEmpty();
        String q = hasQuery ? query.trim() : null;
        boolean hasPositions = positionIds != null && !positionIds.isEmpty();

        Page<Conversation> conversationPage;
        if (role == null || role.trim().isEmpty() || "all".equalsIgnoreCase(role)) {
            conversationPage = hasQuery
                    ? conversationRepository.findAllByUserIdAndQuery(userId, q, pageable)
                    : conversationRepository.findAllByUserId(userId, pageable);
        } else {
            try {
                ERole eRole = ERole.valueOf(role.trim().toLowerCase());
                if (eRole == ERole.staff && hasPositions) {
                    conversationPage = conversationRepository.findAllByUserIdAndRoleAndPositionsAndQuery(
                            userId, eRole, true, positionIds, hasQuery, q, pageable);
                } else {
                    conversationPage = hasQuery
                            ? conversationRepository.findAllByUserIdAndRoleAndQuery(userId, eRole, q, pageable)
                            : conversationRepository.findAllByUserIdAndRole(userId, eRole, pageable);
                }
            } catch (IllegalArgumentException e) {
                conversationPage = hasQuery
                        ? conversationRepository.findAllByUserIdAndQuery(userId, q, pageable)
                        : conversationRepository.findAllByUserId(userId, pageable);
            }
        }

        User currentUser = userRepository.findById(userId).orElse(null);
        boolean isClient = currentUser != null && currentUser.getRole() == ERole.client;

        List<ConversationDetailResponse> responses;
        if (isClient) {
            java.util.Set<String> processedStaffIds = new java.util.HashSet<>();
            List<ConversationDetailResponse> mergedList = new java.util.ArrayList<>();

            for (Conversation c : conversationPage.getContent()) {
                User partner = c.getParticipants().stream()
                        .map(ConversationParticipant::getUser)
                        .filter(u -> !u.getId().equals(userId))
                        .findFirst()
                        .orElse(null);

                if (partner != null && partner.getRole() == ERole.staff) {
                    if (processedStaffIds.add(partner.getId())) {
                        mergedList.add(getMergedClientConversation(userId, partner, c));
                    }
                } else {
                    mergedList.add(ConversationMapper.toConversationDetailResponse(userId, c));
                }
            }
            responses = mergedList;
        } else {
            responses = conversationPage.getContent().stream()
                    .map(c -> ConversationMapper.toConversationDetailResponse(userId, c))
                    .toList();
        }

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
    public ConversationDetailResponse getMergedClientConversation(String clientId, User partner, Conversation baseConv) {
        String sortedUsers = Stream.of(partner.getId(), clientId).sorted().collect(Collectors.joining("_"));
        Optional<Conversation> identOpt = conversationRepository.findByParticipantHash("user_" + sortedUsers);
        Optional<Conversation> anonOpt = conversationRepository.findByParticipantHash("anon_" + sortedUsers);

        Conversation identConv = identOpt.orElse(null);
        Conversation anonConv = anonOpt.orElse(null);

        boolean hasIdentReports = identConv != null || reportRepository.existsByUserIdAndAssignedStaffIdAndIsAnonymous(clientId, partner.getId(), false);
        boolean hasAnonReports = anonConv != null || reportRepository.existsByUserIdAndAssignedStaffIdAndIsAnonymous(clientId, partner.getId(), true);

        int identUnread = 0;
        if (identConv != null) {
            identUnread = identConv.getParticipants().stream()
                    .filter(p -> p.getUser().getId().equals(clientId))
                    .findFirst()
                    .map(p -> p.getUnreadCount() != null ? p.getUnreadCount() : 0)
                    .orElse(0);
        }

        int anonUnread = 0;
        if (anonConv != null) {
            anonUnread = anonConv.getParticipants().stream()
                    .filter(p -> p.getUser().getId().equals(clientId))
                    .findFirst()
                    .map(p -> p.getUnreadCount() != null ? p.getUnreadCount() : 0)
                    .orElse(0);
        }

        // Determine which conversation has the latest message
        Conversation latestConv = null;
        String lastMessageContext = null;

        if (identConv != null && anonConv != null) {
            LocalDateTime tIdent = identConv.getLastMessageTime();
            LocalDateTime tAnon = anonConv.getLastMessageTime();

            if (tIdent != null && tAnon != null) {
                if (tAnon.isAfter(tIdent)) {
                    latestConv = anonConv;
                    lastMessageContext = "ANONYMOUS";
                } else {
                    latestConv = identConv;
                    lastMessageContext = "IDENTIFIED";
                }
            } else if (tAnon != null) {
                latestConv = anonConv;
                lastMessageContext = "ANONYMOUS";
            } else if (tIdent != null) {
                latestConv = identConv;
                lastMessageContext = "IDENTIFIED";
            } else {
                latestConv = identConv;
            }
        } else if (anonConv != null) {
            latestConv = anonConv;
            if (anonConv.getLastMessageTime() != null) {
                lastMessageContext = "ANONYMOUS";
            }
        } else if (identConv != null) {
            latestConv = identConv;
            if (identConv.getLastMessageTime() != null) {
                lastMessageContext = "IDENTIFIED";
            }
        } else {
            latestConv = baseConv;
        }

        ConversationDetailResponse res = ConversationMapper.toConversationDetailResponse(clientId, latestConv);
        res.setIdentifiedConversationId(identConv != null ? identConv.getId() : null);
        res.setAnonymousConversationId(anonConv != null ? anonConv.getId() : null);
        res.setHasIdentifiedContext(hasIdentReports);
        res.setHasAnonymousContext(hasAnonReports);
        res.setLastMessageContext(lastMessageContext);
        res.setIdentifiedUnreadCount(identUnread);
        res.setAnonymousUnreadCount(anonUnread);
        res.setUnreadCount(identUnread + anonUnread);

        // Get the latest read timestamp of the partner across contexts
        java.time.LocalDateTime pReadIdent = identConv != null ? identConv.getParticipants().stream()
                .filter(p -> p.getUser() != null && !p.getUser().getId().equals(clientId))
                .findFirst().map(ConversationParticipant::getLastReadAt).orElse(null) : null;
        java.time.LocalDateTime pReadAnon = anonConv != null ? anonConv.getParticipants().stream()
                .filter(p -> p.getUser() != null && !p.getUser().getId().equals(clientId))
                .findFirst().map(ConversationParticipant::getLastReadAt).orElse(null) : null;
        java.time.LocalDateTime maxPartnerRead = java.util.stream.Stream.of(pReadIdent, pReadAnon)
                .filter(java.util.Objects::nonNull).max(java.util.Comparator.naturalOrder()).orElse(res.getPartnerLastReadAt());
        if (maxPartnerRead != null) {
            res.setPartnerLastReadAt(maxPartnerRead);
        }

        return res;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ParticipantResponse> searchUsersForChat(String userId, String role, List<String> positionIds, String query) {
        if (query == null || query.trim().isEmpty()) {
            return List.of();
        }
        String q = query.trim().toLowerCase();
        Pageable limit = PageRequest.of(0, 20);
        boolean hasPositions = positionIds != null && !positionIds.isEmpty();

        List<User> users;
        if ("staff".equalsIgnoreCase(role)) {
            users = hasPositions
                    ? userRepository.searchActiveUsersByRoleAndPositions(ERole.staff, userId, true, positionIds, q, limit)
                    : userRepository.searchActiveUsersByRole(ERole.staff, userId, q, limit);
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

        User currentUser = userRepository.findById(userId).orElse(null);
        User partner = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(u -> !u.getId().equals(userId))
                .findFirst()
                .orElse(null);

        if (currentUser != null && currentUser.getRole() == ERole.client && partner != null && partner.getRole() == ERole.staff) {
            return getMergedClientConversation(userId, partner, conversation);
        }

        return ConversationMapper.toConversationDetailResponse(userId, conversation);
    }

    @Override
    @Transactional
    public void markAsRead(String userId, String conversationId) {
        Optional<ConversationParticipant> participantOpt = conversationParticipantRepository
                .findByConversationIdAndUserId(conversationId, userId);
        if (participantOpt.isPresent()) {
            ConversationParticipant participant = participantOpt.get();
            int currentUnread = participant.getUnreadCount() != null ? participant.getUnreadCount() : 0;
            Conversation conversation = participant.getConversation();
            java.time.LocalDateTime lastMsgTime = conversation != null ? conversation.getLastMessageTime() : null;
            boolean hasNewerMessage = lastMsgTime != null &&
                    (participant.getLastReadAt() == null || participant.getLastReadAt().isBefore(lastMsgTime));

            if (currentUnread == 0 && !hasNewerMessage) {
                // Already read all messages up to date, skip redundant update and broadcast to prevent cyclic loops
                return;
            }
            participant.setUnreadCount(0);
            participant.setLastReadAt(java.time.LocalDateTime.now());
            conversationParticipantRepository.save(participant);

            // Broadcast updated conversation to user's conversation list queue
            try {
                Conversation conversation = participant.getConversation();
                User user = participant.getUser();
                User partner = conversation.getParticipants().stream()
                        .map(ConversationParticipant::getUser)
                        .filter(u -> !u.getId().equals(userId))
                        .findFirst()
                        .orElse(null);
                ConversationDetailResponse convRes;
                if (user != null && user.getRole() == ERole.client && partner != null && partner.getRole() == ERole.staff) {
                    convRes = getMergedClientConversation(userId, partner, conversation);
                } else {
                    convRes = ConversationMapper.toConversationDetailResponse(userId, conversation);
                }

                // Compute total unread count and attach to response & dedicated queue
                Long totalUnread = conversationParticipantRepository.countTotalUnreadByUserId(userId);
                if (totalUnread != null) {
                    convRes.setTotalUnreadCount(totalUnread.intValue());
                    messagingTemplate.convertAndSendToUser(userId, "/queue/chat.unread",
                            Map.of("totalUnreadCount", totalUnread.intValue()));
                }

                messagingTemplate.convertAndSendToUser(userId, "/queue/conversations", convRes);
            } catch (Exception ignored) {
            }

            // Broadcast read receipt event to conversation topic so active participants see "Seen" / read status in realtime
            try {
                Map<String, Object> readEvent = Map.of(
                        "type", "READ_RECEIPT",
                        "conversationId", conversationId,
                        "readerId", userId,
                        "readAt", participant.getLastReadAt() != null ? participant.getLastReadAt().toString() : LocalDateTime.now().toString()
                );
                messagingTemplate.convertAndSend((String) ("/topic/conversation." + conversationId), (Object) readEvent);
            } catch (Exception ignored) {
            }
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Long getUnreadCount(String userId) {
        return conversationParticipantRepository.countTotalUnreadByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public ConversationInfoResponse getConversationInfo(String userId, String conversationId) {
        Conversation conversation = conversationRepository.findByIdAndMember(conversationId, userId)
                .orElseThrow(() -> new BadRequestException("conversation.not_found"));

        User partner = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(u -> !u.getId().equals(userId))
                .findFirst()
                .orElse(null);

        User currentUser = userRepository.findById(userId).orElse(null);
        List<Report> activeProcessingReports;
        if (currentUser != null && currentUser.getRole() == ERole.client && partner != null && partner.getRole() == ERole.staff) {
            activeProcessingReports = reportRepository.findActiveReportsByClientAndStaff(userId, partner.getId());
        } else {
            activeProcessingReports = reportRepository.findActiveReportsByConversationId(conversationId);
        }

        List<Report> allLinkedReports = reportRepository
                .findByConversationIdOrderByCreatedAtDesc(conversationId);

        boolean hasAnonymousReport = allLinkedReports.stream()
                .anyMatch(r -> Boolean.TRUE.equals(r.getIsAnonymous()));
        if (!hasAnonymousReport && conversation.getReport() != null) {
            hasAnonymousReport = Boolean.TRUE.equals(conversation.getReport().getIsAnonymous());
        }

        boolean isAnonymous = (Boolean.TRUE.equals(conversation.getIsAnonymous()) || hasAnonymousReport)
                && partner != null && partner.getRole() == ERole.client;

        boolean hasAnyLinkedReport = !allLinkedReports.isEmpty() || conversation.getReport() != null;
        boolean canSendMessage;
        if (hasAnyLinkedReport || (partner != null && partner.getRole() == ERole.client)) {
            canSendMessage = !activeProcessingReports.isEmpty();
        } else {
            canSendMessage = true;
        }

        String partnerName = null;
        String partnerAvatar = null;
        String partnerPhone = null;
        String partnerEmail = null;
        ERole partnerRole = null;
        String partnerPosition = null;

        String identifiedConversationId = null;
        String anonymousConversationId = null;
        Boolean hasIdentifiedContext = null;
        Boolean hasAnonymousContext = null;
        String activeContext = null;
        Integer identifiedUnreadCount = null;
        Integer anonymousUnreadCount = null;
        Boolean canSendIdentifiedMessage = null;
        Boolean canSendAnonymousMessage = null;

        if (currentUser != null && currentUser.getRole() == ERole.client && partner != null && partner.getRole() == ERole.staff) {
            String sortedUsers = Stream.of(partner.getId(), userId).sorted().collect(Collectors.joining("_"));
            Optional<Conversation> identOpt = conversationRepository.findByParticipantHash("user_" + sortedUsers);
            Optional<Conversation> anonOpt = conversationRepository.findByParticipantHash("anon_" + sortedUsers);

            Conversation identConv = identOpt.orElse(null);
            Conversation anonConv = anonOpt.orElse(null);

            boolean hasIdentReports = identConv != null || reportRepository.existsByUserIdAndAssignedStaffIdAndIsAnonymous(userId, partner.getId(), false);
            boolean hasAnonReports = anonConv != null || reportRepository.existsByUserIdAndAssignedStaffIdAndIsAnonymous(userId, partner.getId(), true);

            hasIdentifiedContext = hasIdentReports;
            hasAnonymousContext = hasAnonReports;
            identifiedConversationId = identConv != null ? identConv.getId() : null;
            anonymousConversationId = anonConv != null ? anonConv.getId() : null;

            activeContext = (anonConv != null && anonConv.getId().equals(conversation.getId())) ? "ANONYMOUS" : "IDENTIFIED";

            int identUnread = 0;
            if (identConv != null) {
                identUnread = identConv.getParticipants().stream()
                        .filter(p -> p.getUser().getId().equals(userId))
                        .findFirst()
                        .map(p -> p.getUnreadCount() != null ? p.getUnreadCount() : 0)
                        .orElse(0);
            }

            int anonUnread = 0;
            if (anonConv != null) {
                anonUnread = anonConv.getParticipants().stream()
                        .filter(p -> p.getUser().getId().equals(userId))
                        .findFirst()
                        .map(p -> p.getUnreadCount() != null ? p.getUnreadCount() : 0)
                        .orElse(0);
            }
            identifiedUnreadCount = identUnread;
            anonymousUnreadCount = anonUnread;

            List<Report> activeIdentReports = reportRepository.findActiveReportsByClientAndStaffAndAnonymous(userId, partner.getId(), false);
            List<Report> activeAnonReports = reportRepository.findActiveReportsByClientAndStaffAndAnonymous(userId, partner.getId(), true);

            canSendIdentifiedMessage = !activeIdentReports.isEmpty();
            canSendAnonymousMessage = !activeAnonReports.isEmpty();
        }

        if (partner != null) {
            partnerRole = partner.getRole();
            if (partner.getPosition() != null) {
                partnerPosition = partner.getPosition().getName();
            }

            if (isAnonymous) {
                partnerName = "Người dùng ẩn danh";
                partnerAvatar = null;
                partnerPhone = null;
                partnerEmail = null;
            } else {
                partnerName = partner.getFullName() != null && !partner.getFullName().trim().isEmpty()
                        ? partner.getFullName().trim()
                        : partner.getEmail();
                partnerAvatar = partner.getAvatarUrl();
                partnerPhone = partner.getPhone();
                partnerEmail = partner.getEmail();
            }
        }

        List<LinkedReportResponse> reportResponses = activeProcessingReports.stream()
                .map(r -> {
                    boolean isRehandling = (r.getStatus() == EReportStatus.processing || r.getStatus() == EReportStatus.processed)
                            && Boolean.FALSE.equals(r.getIsReviewResolved());
                    return LinkedReportResponse.builder()
                            .id(r.getId())
                            .title(r.getTitle())
                            .description(r.getDescription())
                            .imageUrl(r.getImageUrl())
                            .status(r.getStatus() != null ? r.getStatus().name() : null)
                            .severity(r.getSeverity() != null ? r.getSeverity().name() : null)
                            .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                            .address(r.getAddress())
                            .isReviewResolved(r.getIsReviewResolved())
                            .needsRehandling(isRehandling)
                            .build();
                })
                .collect(Collectors.toList());

        return ConversationInfoResponse.builder()
                .id(conversation.getId())
                .partnerId(partner != null ? partner.getId() : null)
                .partnerName(partnerName)
                .partnerAvatarUrl(partnerAvatar)
                .partnerRole(partnerRole)
                .partnerPosition(partnerPosition)
                .partnerPhone(partnerPhone)
                .partnerEmail(partnerEmail)
                .isAnonymous(isAnonymous)
                .canSendMessage(canSendMessage)
                .activeReports(reportResponses)
                .createdAt(conversation.getCreatedAt())
                .identifiedConversationId(identifiedConversationId)
                .anonymousConversationId(anonymousConversationId)
                .hasIdentifiedContext(hasIdentifiedContext)
                .hasAnonymousContext(hasAnonymousContext)
                .activeContext(activeContext)
                .identifiedUnreadCount(identifiedUnreadCount)
                .anonymousUnreadCount(anonymousUnreadCount)
                .canSendIdentifiedMessage(canSendIdentifiedMessage)
                .canSendAnonymousMessage(canSendAnonymousMessage)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<LinkedReportResponse> getConversationReports(String userId, String conversationId, Boolean isAnonymous, int page, int size) {
        Conversation conversation = conversationRepository.findByIdAndMember(conversationId, userId)
                .orElseThrow(() -> new BadRequestException("conversation.not_found"));

        int safePage = Math.max(0, page - 1);
        int safeSize = Math.max(1, Math.min(size, 50));
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(safePage, safeSize);

        User currentUser = userRepository.findById(userId).orElse(null);
        User partner = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .filter(u -> !u.getId().equals(userId))
                .findFirst()
                .orElse(null);

        org.springframework.data.domain.Page<Report> reportPage;
        if (currentUser != null && currentUser.getRole() == ERole.client && partner != null && partner.getRole() == ERole.staff) {
            if (isAnonymous != null) {
                reportPage = reportRepository.findActiveReportsByClientAndStaffAndAnonymous(userId, partner.getId(), isAnonymous, pageable);
            } else {
                reportPage = reportRepository.findActiveReportsByClientAndStaff(userId, partner.getId(), pageable);
            }
        } else {
            reportPage = reportRepository.findActiveReportsByConversationId(conversationId, pageable);
        }

        List<LinkedReportResponse> content = reportPage.getContent().stream()
                .map(r -> {
                    boolean isRehandling = (r.getStatus() == EReportStatus.processing || r.getStatus() == EReportStatus.processed)
                            && Boolean.FALSE.equals(r.getIsReviewResolved());
                    return LinkedReportResponse.builder()
                            .id(r.getId())
                            .title(r.getTitle())
                            .description(r.getDescription())
                            .imageUrl(r.getImageUrl())
                            .status(r.getStatus() != null ? r.getStatus().name() : null)
                            .severity(r.getSeverity() != null ? r.getSeverity().name() : null)
                            .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                            .address(r.getAddress())
                            .isReviewResolved(r.getIsReviewResolved())
                            .needsRehandling(isRehandling)
                            .build();
                })
                .collect(Collectors.toList());

        return PageResponse.<LinkedReportResponse>builder()
                .currentPage(page)
                .pageSize(safeSize)
                .totalElements(reportPage.getTotalElements())
                .totalPages(reportPage.getTotalPages())
                .content(content)
                .build();
    }

}
