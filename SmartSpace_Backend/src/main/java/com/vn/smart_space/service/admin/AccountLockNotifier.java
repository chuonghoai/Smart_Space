package com.vn.smart_space.service.admin;

import java.util.Collection;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.model.AccountLockRequest;
import com.vn.smart_space.model.User;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

/**
 * Thông báo (in-app + WebSocket + FCM, và email cho người bị khóa) của luồng
 * biểu quyết khóa
 */
@Slf4j
@Component
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AccountLockNotifier {

    static final String ACTION_TYPE = "ACCOUNT_LOCK_REQUEST";

    INotificationService notificationService;
    SimpMessagingTemplate messagingTemplate;
    IFCMService fcmService;
    MessageSource messageSource;
    IMailService mailService;

    /** Có đề xuất mới → mời các admin (trừ người đề xuất) biểu quyết. */
    public void notifyNewRequest(AccountLockRequest request, Collection<User> admins) {
        String proposerId = request.getProposer().getId();
        for (User admin : admins) {
            if (Objects.equals(admin.getId(), proposerId)) {
                continue;
            }
            sendAction(admin, request, "notification.lock_request.new.title", "notification.lock_request.new.message",
                    new Object[] { displayName(request.getProposer()), displayName(request.getTarget()) });
        }
    }

    /**
     * Kết quả cuối (approved | rejected | expired) → người đề xuất và những người
     * đã bỏ phiếu.
     */
    public void notifyResolved(AccountLockRequest request, Collection<User> recipients) {
        String status = request.getStatus().name();
        Object[] args = new Object[] { displayName(request.getTarget()) };
        for (User recipient : recipients) {
            sendAction(recipient, request, "notification.lock_request." + status + ".title",
                    "notification.lock_request." + status + ".message", args);
        }
    }

    /**
     * Báo người dùng bị khóa: thông báo trong app + push + email, chỉ kèm lý do.
     */
    public void notifyAccountLocked(User target, String reason) {
        Locale locale = localeOf(target);
        sendPlain(target, msg("notification.account.locked.title", null, locale),
                msg("notification.account.locked.message", new Object[] { reason }, locale));
        try {
            if (target.getEmail() != null && !target.getEmail().isBlank()) {
                mailService.sendAccountLockedEmail(target.getEmail(), target.getFullName(), reason,
                        target.getLanguage());
            }
        } catch (Exception e) {
            log.warn("[AccountLock] Failed to send locked email to user {}: {}", target.getId(), e.getMessage());
        }
    }

    public void notifyAccountUnlocked(User target) {
        Locale locale = localeOf(target);
        sendPlain(target, msg("notification.account.unlocked.title", null, locale),
                msg("notification.account.unlocked.message", null, locale));
    }

    // helpers

    private void sendAction(User recipient, AccountLockRequest request, String titleKey, String messageKey,
            Object[] args) {
        try {
            Locale locale = localeOf(recipient);
            String title = msg(titleKey, null, locale);
            String message = msg(messageKey, args, locale);
            String payload = "{\"requestId\":\"" + request.getId() + "\"}";
            String actionData = "{\"type\":\"" + ACTION_TYPE + "\",\"payload\":" + payload + "}";

            notificationService.createNotification(recipient.getId(), title, message, actionData);
            messagingTemplate.convertAndSendToUser(recipient.getId(), "/queue/notifications",
                    new NotificationEvent(title, message, actionData, null, Map.of("shouldRefresh", true)));
            fcmService.sendToUser(recipient.getId(),
                    new NotificationRequest(title, message, Map.of("type", ACTION_TYPE, "payload", payload)));
        } catch (Exception e) {
            log.warn("[AccountLock] Failed to notify {} about request {}: {}", recipient.getId(), request.getId(),
                    e.getMessage());
        }
    }

    /** Thông báo không điều hướng (người dùng bị khóa / mở khóa). */
    private void sendPlain(User recipient, String title, String message) {
        try {
            notificationService.createNotification(recipient.getId(), title, message, null);
            messagingTemplate.convertAndSendToUser(recipient.getId(), "/queue/notifications",
                    new NotificationEvent(title, message, null, null, Map.of("shouldRefresh", true)));
            fcmService.sendToUser(recipient.getId(), new NotificationRequest(title, message, Map.of()));
        } catch (Exception e) {
            log.warn("[AccountLock] Failed to notify user {}: {}", recipient.getId(), e.getMessage());
        }
    }

    private String msg(String key, Object[] args, Locale locale) {
        return messageSource.getMessage(key, args, key, locale);
    }

    private static Locale localeOf(User user) {
        return (user != null && "en".equalsIgnoreCase(user.getLanguage()))
                ? Locale.ENGLISH
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
