package com.vn.smart_space.service.notification;

import com.vn.smart_space.dto.response.notification.NotificationCountResponse;

import com.vn.smart_space.model.Notification;

import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.notification.NotificationResponse;

public interface INotificationService {
    NotificationCountResponse getUnreadCount(String userId);
    Notification createNotification(String userId, String title, String message, String actionData);
    PageResponse<NotificationResponse> getMyNotifications(String userId, int page, int size);
    void markAllAsRead(String userId);
}
