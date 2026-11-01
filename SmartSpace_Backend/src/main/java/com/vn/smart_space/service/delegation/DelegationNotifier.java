package com.vn.smart_space.service.delegation;

import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.model.User;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.Locale;
import java.util.Map;

/**
 * Thông báo (FCM + in-app + WebSocket) cho luồng nhờ làm giùm, type {@code STAFF_DELEGATION}.
 *
 * Nội dung được dịch ngay theo ngôn ngữ của người nhận ({@link User#getLanguage()}), còn việc gửi
 * dời tới sau khi transaction commit → không báo cho staff về một thay đổi tiền đã bị rollback.
 */
@Slf4j
@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class DelegationNotifier {

    public static final String TYPE = "STAFF_DELEGATION";

    MessageSource messageSource;
    IFCMService fcmService;
    INotificationService notificationService;
    SimpMessagingTemplate messagingTemplate;

    public void notify(User recipient, String titleKey, String messageKey, Object[] args,
            String delegationId, String reportId, String imageUrl) {
        if (recipient == null) return;

        Locale locale = "en".equalsIgnoreCase(recipient.getLanguage()) ? Locale.ENGLISH : Locale.forLanguageTag("vi");
        String title = messageSource.getMessage(titleKey, null, titleKey, locale);
        String message = messageSource.getMessage(messageKey, args, messageKey, locale);
        String userId = recipient.getId();

        String payload = "{\"delegationId\":\"" + delegationId + "\",\"reportId\":\"" + reportId + "\"}";
        String actionData = "{\"type\": \"" + TYPE + "\", \"payload\": " + payload + "}";

        Runnable send = () -> {
            try {
                fcmService.sendToUser(userId, new NotificationRequest(title, message,
                        Map.of("type", TYPE, "payload", payload)));
                messagingTemplate.convertAndSendToUser(userId, "/queue/notifications",
                        new NotificationEvent(title, message, actionData, imageUrl, Map.of("shouldRefresh", true)));
                notificationService.createNotification(userId, title, message, actionData, imageUrl);
            } catch (Exception ex) {
                log.warn("[Delegation] Failed to notify user {}: {}", userId, ex.getMessage());
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

    /** Số tiền hiển thị trong thông báo, cùng định dạng với thông báo ví hiện có. */
    public static String money(Double amount) {
        return String.format("%,.0f", amount != null ? amount : 0.0);
    }
}
