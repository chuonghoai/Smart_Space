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
}
