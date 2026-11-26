package com.vn.smart_space.service.emergency;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.model.User;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

/**
 * Thông báo (FCM + in-app + WebSocket) cho luồng liên hệ khẩn cấp, type {@code EMERGENCY_CONTACT}.
 * Gửi sau khi transaction commit để không báo về thay đổi đã bị rollback.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class EmergencyContactNotifier {

    public static final String TYPE = "EMERGENCY_CONTACT";
    /** Màn hình client cần mở: danh sách liên hệ của tôi hoặc tab tôi bảo hộ. */
    public static final String VIEW_CONTACTS = "contacts";
    public static final String VIEW_GUARDIAN = "guardian";

    MessageSource messageSource;
    IFCMService fcmService;
    INotificationService notificationService;
    SimpMessagingTemplate messagingTemplate;
    ObjectMapper objectMapper;

    public void notify(User recipient, String titleKey, String messageKey, Object[] args, String contactId,
            String view) {
        if (recipient == null) {
            return;
        }
        Locale locale = localeOf(recipient);
        String title = messageSource.getMessage(titleKey, null, titleKey, locale);
        String message = messageSource.getMessage(messageKey, args, messageKey, locale);
        String userId = recipient.getId();

        Map<String, Object> payloadMap = new LinkedHashMap<>();
        payloadMap.put("contactId", contactId);
        payloadMap.put("view", view);

        Map<String, Object> actionMap = new LinkedHashMap<>();
        actionMap.put("type", TYPE);
        actionMap.put("payload", payloadMap);

        String payload = toJson(payloadMap);
        String actionData = toJson(actionMap);

        Runnable send = () -> {
            try {
                fcmService.sendToUser(userId, new NotificationRequest(title, message,
                        Map.of("type", TYPE, "payload", payload)));
                messagingTemplate.convertAndSendToUser(userId, "/queue/notifications",
                        new NotificationEvent(title, message, actionData, null, Map.of("shouldRefresh", true)));
                notificationService.createNotification(userId, title, message, actionData);
            } catch (Exception ex) {
                log.warn("[EmergencyContact] Failed to notify user {}: {}", userId, ex.getMessage());
            }
        };

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    send.run();
                }
            });
        } else {
            send.run();
        }
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize notification payload", ex);
        }
    }

    static Locale localeOf(User user) {
        return user != null && "en".equalsIgnoreCase(user.getLanguage()) ? Locale.ENGLISH
                : Locale.forLanguageTag("vi");
    }

    static String displayName(User user) {
        if (user == null) {
            return "";
        }
        if (user.getFullName() != null && !user.getFullName().isBlank()) {
            return user.getFullName().trim();
        }
        return user.getEmail() != null ? user.getEmail().trim() : "";
    }
}
