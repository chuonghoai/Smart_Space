package com.vn.smart_space.service.notification;

import com.vn.smart_space.dto.response.notification.NotificationCountResponse;
import com.vn.smart_space.repository.NotificationRepository;
import com.vn.smart_space.repository.UserNotificationStateRepository;
import com.vn.smart_space.model.Notification;
import com.vn.smart_space.model.User;

import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import lombok.extern.slf4j.Slf4j;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.ArrayList;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationServiceImpl implements INotificationService {

    private final NotificationRepository notificationRepository;
    private final UserNotificationStateRepository userNotificationStateRepository;
    private final UserRepository userRepository;
    private final MessageSource messageSource;
    private final SimpMessagingTemplate messagingTemplate;
    private final IFCMService fcmService;

    @Override
    @Transactional(readOnly = true)
    public NotificationCountResponse getUnreadCount(String userId) {
        long unreadPersonal = notificationRepository.countUnreadPersonalNotifications(userId);
        long unreadBroadcast = userNotificationStateRepository.countUnreadBroadcastNotificationsByUser(userId);
        
        long totalUnread = unreadPersonal + unreadBroadcast;

        return NotificationCountResponse.builder()
                .notifNumber(totalUnread)
                .build();
    }

    @Override
    @Transactional
    public Notification createNotification(String userId, String title, String message, String actionData) {
        return createNotification(userId, title, message, actionData, null);
    }

    @Override
    @Transactional
    public Notification createNotification(String userId, String title, String message, String actionData, String imageUrl) {
        User user = new User();
        user.setId(userId);
        Notification notification = Notification.builder()
                .title(title)
                .message(message)
                .actionData(actionData)
                .imageUrl(imageUrl)
                .user(user)
                .isRead(false)
                .build();
        return notificationRepository.save(notification);
    }

    @Override
    @Transactional(readOnly = true)
    public com.vn.smart_space.dto.PageResponse<com.vn.smart_space.dto.response.notification.NotificationResponse> getMyNotifications(String userId, int page, int size) {
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
        org.springframework.data.domain.Page<Notification> notifs = notificationRepository.findByUserIdOrUserIsNullOrderByCreatedAtDesc(userId, pageable);
        
        java.util.List<com.vn.smart_space.dto.response.notification.NotificationResponse> content = notifs.getContent().stream()
                .map(n -> {
                    long createdAtEpoch = n.getCreatedAt() != null ? n.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli() : 0L;
                    return com.vn.smart_space.dto.response.notification.NotificationResponse.builder()
                        .id(n.getId())
                        .title(n.getTitle())
                        .message(n.getMessage())
                        .imageUrl(n.getImageUrl())
                        .isRead(n.getIsRead())
                        .createdAt(createdAtEpoch)
                        .actionData(n.getActionData())
                        .build();
                })
                .collect(java.util.stream.Collectors.toList());

        return com.vn.smart_space.dto.PageResponse.<com.vn.smart_space.dto.response.notification.NotificationResponse>builder()
                .currentPage(notifs.getNumber())
                .pageSize(notifs.getSize())
                .totalPages(notifs.getTotalPages())
                .totalElements(notifs.getTotalElements())
                .content(content)
                .build();
    }

    @Override
    @Transactional
    public void markAllAsRead(String userId) {
        java.util.List<Notification> unreads = notificationRepository.findByUserIdAndIsReadFalse(userId);
        unreads.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unreads);
        // Note: Broadcast notification read tracking can be added here if needed
    }

    @Override
    @Transactional
    public void markAsRead(String userId, String notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new com.vn.smart_space.exception.ResourceNotFoundException("Notification not found"));
        
        if (!notification.getUser().getId().equals(userId)) {
            throw new com.vn.smart_space.exception.ResourceNotFoundException("Notification not found");
        }

        if (!Boolean.TRUE.equals(notification.getIsRead())) {
            notification.setIsRead(true);
            notificationRepository.save(notification);
        }
    }

    @Override
    @Transactional
    public Map<String, Object> broadcastTestNotification() {
        List<User> allUsers = userRepository.findAll();
        int count = 0;
        List<Map<String, Object>> sentDetails = new ArrayList<>();
        int viCount = 0;
        int enCount = 0;

        for (User user : allUsers) {
            if (user == null || user.getId() == null) continue;
            try {
                Locale userLocale = "en".equalsIgnoreCase(user.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
                if (userLocale == Locale.ENGLISH) {
                    enCount++;
                } else {
                    viCount++;
                }
                String langDisplayName = userLocale == Locale.ENGLISH ? "English (en)" : "Tiếng Việt (vi)";
                String roleName = user.getRole() != null ? user.getRole().name().toUpperCase() : "CLIENT";
                String recipientName = user.getFullName() != null && !user.getFullName().trim().isEmpty()
                        ? user.getFullName().trim()
                        : (user.getEmail() != null ? user.getEmail() : user.getId());

                String title = messageSource.getMessage("notification.test_broadcast.title", null, "Thông báo thử nghiệm", userLocale);
                String message = messageSource.getMessage("notification.test_broadcast.message",
                        new Object[]{ roleName, recipientName, langDisplayName },
                        String.format("[%s] Chào %s! Đây là thông báo thử nghiệm ngôn ngữ (%s) gửi từ hệ thống SmartSpace.", roleName, recipientName, langDisplayName),
                        userLocale);

                String actionData = String.format("{\"type\": \"TEST_BROADCAST\", \"payload\": {\"language\": \"%s\", \"userId\": \"%s\", \"role\": \"%s\"}}",
                        userLocale.getLanguage(), user.getId(), roleName);

                // 1. Lưu DB Notification
                createNotification(user.getId(), title, message, actionData, null);

                // 2. Bắn WebSocket qua /queue/notifications
                NotificationEvent event = new NotificationEvent(title, message, actionData, null, Map.of(
                        "type", "TEST_BROADCAST",
                        "language", userLocale.getLanguage(),
                        "shouldRefresh", true
                ));
                messagingTemplate.convertAndSendToUser(user.getId(), "/queue/notifications", event);

                // 3. Bắn Firebase Cloud Messaging (FCM)
                NotificationRequest fcmRequest = new NotificationRequest(
                        title,
                        message,
                        Map.of(
                                "type", "TEST_BROADCAST",
                                "language", userLocale.getLanguage(),
                                "role", roleName
                        )
                );
                fcmService.sendToUser(user.getId(), fcmRequest);

                count++;
                sentDetails.add(Map.of(
                        "userId", user.getId(),
                        "email", user.getEmail() != null ? user.getEmail() : "",
                        "role", roleName,
                        "language", userLocale.getLanguage(),
                        "title", title,
                        "message", message
                ));
            } catch (Exception ex) {
                log.warn("[Test Notification] Failed to send to user {}: {}", user.getId(), ex.getMessage());
            }
        }

        return Map.of(
                "totalUsers", allUsers.size(),
                "totalSent", count,
                "viCount", viCount,
                "enCount", enCount,
                "details", sentDetails
        );
    }
}
