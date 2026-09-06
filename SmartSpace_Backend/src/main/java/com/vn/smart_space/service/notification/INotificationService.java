package com.vn.smart_space.service.notification;

import com.vn.smart_space.dto.response.notification.NotificationCountResponse;

import com.vn.smart_space.model.Notification;

public interface INotificationService {
    NotificationCountResponse getUnreadCount(String userId);
    Notification createNotification(String userId, String title, String message, String actionData);
}
