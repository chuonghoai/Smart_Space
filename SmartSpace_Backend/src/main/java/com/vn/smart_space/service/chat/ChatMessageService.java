package com.vn.smart_space.service.chat;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.context.MessageSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EMessageType;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.chat.ChatMessageRequest;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.chat.ChatMessageResponse;
import com.vn.smart_space.dto.response.chat.MessageMediaResponse;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.mapper.ConversationMapper;
import com.vn.smart_space.model.ChatMessage;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.ConversationParticipant;
import com.vn.smart_space.model.MessageMedia;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ChatMessageRepository;
import com.vn.smart_space.repository.ConversationParticipantRepository;
import com.vn.smart_space.repository.ConversationRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.conversation.IConversationService;
import com.vn.smart_space.service.notification.IFCMService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "CHAT-MESSAGE-SERVICE")
public class ChatMessageService implements IChatMessageService {

    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;
    private final ConversationParticipantRepository conversationParticipantRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final ReportRepository reportRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ChatPresenceService chatPresenceService;
    private final IFCMService fcmService;
    private final MessageSource messageSource;
    private final IConversationService conversationService;

    private static final Map<String, IdempotentRecord> IDEMPOTENT_CACHE = new java.util.concurrent.ConcurrentHashMap<>();

    private record IdempotentRecord(ChatMessageResponse response, LocalDateTime expiresAt) {}

    @Transactional(rollbackFor = Exception.class)
    @Override
    public ChatMessageResponse sendMessage(String senderId, ChatMessageRequest request) {
        // 0. Idempotency Check (prevent duplicate message when network is lagging / retry)
        if (request.tempId() != null && !request.tempId().isBlank()) {
            IdempotentRecord cached = IDEMPOTENT_CACHE.get(request.tempId());
            if (cached != null && cached.expiresAt().isAfter(LocalDateTime.now())) {
                log.info("Idempotent hit for tempId: {}. Returning cached response without duplicate creation.", request.tempId());
                return cached.response();
            }
        }

        // 1. Validate Exists User
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new BadRequestException("user.not_found"));

        // 2. Validate Conversation exists and Sender is member
        Conversation conversation = conversationRepository.findByIdAndMember(request.conversationId(), senderId)
                .orElseThrow(() -> new BadRequestException("conversation.not_found"));

        // 3. Permission & Report status check
        List<Report> linkedReports = reportRepository.findByConversationIdOrderByCreatedAtDesc(conversation.getId());
        if (!linkedReports.isEmpty()) {
            boolean hasActive = linkedReports.stream()
                    .anyMatch(r -> r.getStatus() == EReportStatus.processing
                            || (r.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(r.getIsReviewResolved())));
            if (!hasActive) {
                throw new BadRequestException("chat.report.not_processing");
            }
        } else if (conversation.getReport() != null) {
            Report report = conversation.getReport();
            boolean isAssignedStaff = report.getAssignedStaff() != null && report.getAssignedStaff().getId().equals(senderId);
            boolean isReportCreator = report.getUser() != null && report.getUser().getId().equals(senderId);
            boolean isAdmin = sender.getRole() == ERole.admin;

            if (!isAssignedStaff && !isReportCreator && !isAdmin) {
                throw new BadRequestException("chat.permission_denied");
            }

            boolean isRehandling = report.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(report.getIsReviewResolved());
            if (report.getStatus() != EReportStatus.processing && !isRehandling) {
                throw new BadRequestException("chat.report.not_processing");
            }
        }

        // 4. Report & Effective content
        Report attachedReport = null;
        if (request.messageType() == EMessageType.report && request.reportId() != null && !request.reportId().isBlank()) {
            attachedReport = reportRepository.findById(request.reportId()).orElse(null);
        }

        String effectiveContent = request.content();
        if (effectiveContent == null || effectiveContent.isBlank()) {
            if (request.messageType() == EMessageType.report) {
                effectiveContent = attachedReport != null ? "[Phản ánh: " + attachedReport.getTitle() + "]" : "[Phản ánh]";
            } else if (request.messageType() == EMessageType.audio) {
                effectiveContent = "[Tin nhắn thoại]";
            } else if (request.messageType() == EMessageType.image) {
                effectiveContent = "[Hình ảnh]";
            } else if (request.messageType() == EMessageType.video) {
                effectiveContent = "[Video]";
            } else {
                effectiveContent = "";
            }
        }

        // 5. Create chat message
        ChatMessage message = ChatMessage.builder()
                .conversation(conversation)
                .sender(sender)
                .content(effectiveContent)
                .messageType(request.messageType())
                .report(attachedReport)
                .sentAt(LocalDateTime.now())
                .mediaFiles(new ArrayList<>())
                .build();

        // 6. Attach Media if provided
        if (request.messageMedia() != null && !request.messageMedia().isEmpty()) {
            for (var reqMedia : request.messageMedia()) {
                MessageMedia media = MessageMedia.builder()
                        .fileName(reqMedia.fileName())
                        .fileType(reqMedia.fileType())
                        .thumbnailUrl(reqMedia.thumbnailUrl())
                        .uploadedAt(LocalDateTime.now())
                        .build();
                message.addMedia(media);
            }
        }

        chatMessageRepository.save(message);

        // 6. Update lastMessage of conversation
        conversation.setLastMessageId(message.getId());
        String snippet = message.getContent();
        if (message.getMessageType() == EMessageType.audio) {
            snippet = "[tin nhắn thoại]";
        } else if (message.getMessageType() == EMessageType.image) {
            snippet = "[hình ảnh]";
        } else if (message.getMessageType() == EMessageType.video) {
            snippet = "[video]";
        } else if (message.getMessageType() == EMessageType.report) {
            snippet = "[phản ánh đính kèm]";
        }
        conversation.setLastMessageContent(snippet);
        conversation.setLastMessageTime(message.getSentAt());
        conversationRepository.save(conversation);

        // 7. Map entity to response DTO
        ChatMessageResponse response = toChatMessageResponse(message, request.tempId());

        // 8. Realtime WebSocket Broadcast to Conversation Topic
        try {
            messagingTemplate.convertAndSend("/topic/conversation." + conversation.getId(), response);
        } catch (Exception e) {
            log.warn("Failed to broadcast message to /topic/conversation.{}: {}", conversation.getId(), e.getMessage());
        }

        // 9. Update unreadCount, broadcast personal list update & handle FCM for recipients
        for (ConversationParticipant participant : conversation.getParticipants()) {
            User recipient = participant.getUser();
            boolean isRecipient = !recipient.getId().equals(senderId);

            if (isRecipient) {
                boolean isViewingConv = chatPresenceService.isUserViewingConversation(recipient.getId(), conversation.getId());
                boolean isViewingList = chatPresenceService.isUserViewingConversation(recipient.getId(), "list");

                if (!isViewingConv) {
                    // Increment unread count
                    participant.setUnreadCount((participant.getUnreadCount() != null ? participant.getUnreadCount() : 0) + 1);
                    conversationParticipantRepository.save(participant);

                    // Send FCM notification only if not viewing the conversation AND not in the conversation list
                    if (!isViewingList) {
                        sendFcmNotification(recipient, sender, conversation, message);
                    }
                }
            }

            // Broadcast updated conversation item to recipient's conversation list queue
            try {
                ConversationDetailResponse convResponse;
                User convPartner = conversation.getParticipants().stream()
                        .map(ConversationParticipant::getUser)
                        .filter(u -> !u.getId().equals(recipient.getId()))
                        .findFirst()
                        .orElse(null);
                if (recipient.getRole() == ERole.client && convPartner != null && convPartner.getRole() == ERole.staff) {
                    convResponse = conversationService.getMergedClientConversation(recipient.getId(), convPartner, conversation);
                } else {
                    convResponse = ConversationMapper.toConversationDetailResponse(recipient.getId(), conversation);
                }

                // Compute recipient's total unread count and attach to response & dedicated queue
                Long totalUnread = conversationParticipantRepository.countTotalUnreadByUserId(recipient.getId());
                if (totalUnread != null) {
                    convResponse.setTotalUnreadCount(totalUnread.intValue());
                    messagingTemplate.convertAndSendToUser(recipient.getId(), "/queue/chat.unread",
                            Map.of("totalUnreadCount", totalUnread.intValue()));
                }

                messagingTemplate.convertAndSendToUser(recipient.getId(), "/queue/conversations", convResponse);
            } catch (Exception e) {
                log.warn("Failed to broadcast conversation update to user {}: {}", recipient.getId(), e.getMessage());
            }
        }

        // Cache response for idempotency check (TTL: 5 minutes)
        if (request.tempId() != null && !request.tempId().isBlank()) {
            if (IDEMPOTENT_CACHE.size() > 500) {
                LocalDateTime now = LocalDateTime.now();
                IDEMPOTENT_CACHE.entrySet().removeIf(entry -> entry.getValue().expiresAt().isBefore(now));
            }
            IDEMPOTENT_CACHE.put(request.tempId(), new IdempotentRecord(response, LocalDateTime.now().plusMinutes(5)));
        }

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ChatMessageResponse> getMessagesByConversation(String userId, String conversationId, int page, int size) {
        // Validate user is a member of the conversation
        conversationRepository.findByIdAndMember(conversationId, userId)
                .orElseThrow(() -> new BadRequestException("conversation.not_found"));

        Pageable pageable = PageRequest.of(Math.max(0, page - 1), size);
        Page<ChatMessage> messagePage = chatMessageRepository.findByConversationIdOrderBySentAtDesc(conversationId, pageable);

        List<ChatMessageResponse> responses = messagePage.getContent().stream()
                .map(m -> toChatMessageResponse(m, null))
                .toList();

        return PageResponse.<ChatMessageResponse>builder()
                .currentPage(page)
                .pageSize(pageable.getPageSize())
                .totalPages(messagePage.getTotalPages())
                .totalElements(messagePage.getTotalElements())
                .content(responses)
                .build();
    }

    private ChatMessageResponse toChatMessageResponse(ChatMessage message, String tempId) {
        return ChatMessageResponse.builder()
                .id(message.getId())
                .tempId(tempId)
                .conversationId(message.getConversation().getId())
                .conversationAvatar(message.getConversation().getConversationAvatar())
                .senderId(message.getSender() != null ? message.getSender().getId() : null)
                .senderName(message.getSender() != null ? message.getSender().getFullName() : null)
                .content(message.getContent())
                .messageType(message.getMessageType())
                .messageMedia(message.getMediaFiles() != null
                        ? message.getMediaFiles().stream()
                                .map(media -> MessageMediaResponse.builder()
                                        .fileName(media.getFileName())
                                        .fileType(media.getFileType())
                                        .thumbnailUrl(media.getThumbnailUrl())
                                        .uploadedAt(media.getUploadedAt())
                                        .build())
                                .toList()
                        : List.of())
                .report(ConversationMapper.toLinkedReportResponse(message.getReport()))
                .createdAt(message.getSentAt())
                .build();
    }

    private void sendFcmNotification(User recipient, User sender, Conversation conversation, ChatMessage message) {
        try {
            String recipientLang = recipient.getLanguage() != null ? recipient.getLanguage() : "vi";
            Locale recipientLocale = Locale.forLanguageTag(recipientLang);

            // Determine sender display name for recipient
            String senderDisplayName = sender.getFullName();
            Report report = conversation.getReport();
            boolean isAnon = Boolean.TRUE.equals(conversation.getIsAnonymous())
                    || (report != null && Boolean.TRUE.equals(report.getIsAnonymous()));
            if (isAnon && sender.getRole() == ERole.client) {
                senderDisplayName = messageSource.getMessage("chat.anonymous_user", null, "Người dùng ẩn danh", recipientLocale);
            }

            String body;
            if (message.getMessageType() == EMessageType.audio) {
                body = messageSource.getMessage("chat.audio_message", null, "[Tin nhắn thoại]", recipientLocale);
            } else if (message.getMessageType() == EMessageType.image) {
                body = messageSource.getMessage("chat.image_message", null, "[Hình ảnh]", recipientLocale);
            } else if (message.getMessageType() == EMessageType.video) {
                body = messageSource.getMessage("chat.video_message", null, "[Video]", recipientLocale);
            } else if (message.getMessageType() == EMessageType.report) {
                String reportTitle = message.getReport() != null ? message.getReport().getTitle() : message.getContent();
                body = messageSource.getMessage("chat.report_message", null, "[Phản ánh]", recipientLocale) + ": " + reportTitle;
            } else {
                body = message.getContent() != null ? message.getContent() : "";
            }

            if (body.length() > 120) {
                body = body.substring(0, 117) + "...";
            }

            Map<String, String> data = Map.of(
                    "type", "CHAT_DETAIL",
                    "payload", "{\"conversationId\":\"" + conversation.getId() + "\"}"
            );

            NotificationRequest fcmRequest = new NotificationRequest(senderDisplayName, body, data);
            final String recipientId = recipient.getId();
            java.util.concurrent.CompletableFuture.runAsync(() -> {
                try {
                    fcmService.sendToUser(recipientId, fcmRequest);
                } catch (Exception ex) {
                    log.warn("Failed to send chat FCM to user {}: {}", recipientId, ex.getMessage());
                }
            });
        } catch (Exception e) {
            log.error("Failed to send chat FCM to user {}: {}", recipient.getId(), e.getMessage());
        }
    }
}
