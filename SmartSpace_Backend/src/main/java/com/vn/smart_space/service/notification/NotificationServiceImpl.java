package com.vn.smart_space.service.notification;

import com.vn.smart_space.dto.response.notification.NotificationCountResponse;
import com.vn.smart_space.repository.NotificationRepository;
import com.vn.smart_space.repository.UserNotificationStateRepository;
import com.vn.smart_space.model.Notification;
import com.vn.smart_space.model.User;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements INotificationService {

    private final NotificationRepository notificationRepository;
    private final UserNotificationStateRepository userNotificationStateRepository;

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
        User user = new User();
        user.setId(userId);
        Notification notification = Notification.builder()
                .title(title)
                .message(message)
                .actionData(actionData)
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
}
