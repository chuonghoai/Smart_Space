package com.vn.smart_space.service.sos;

import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Stream;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.MessageSource;
import org.springframework.core.task.TaskExecutor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.configuration.async.NotificationExecutorConfig;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationEvent;
import com.vn.smart_space.dto.response.sos.SosAlertResponse;
import com.vn.smart_space.dto.response.sos.SosRealtimeEvent;
import com.vn.smart_space.model.User;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import com.vn.smart_space.service.sms.ISmsService;

import lombok.extern.slf4j.Slf4j;

/**
 * Thông báo SOS (type {@code SOS_ALERT}): push + in-app + WebSocket cho người
 * có tài khoản,
 * SMS cho liên hệ không có tài khoản, và sự kiện realtime qua /user/queue/sos.
 * Người nhận được chụp lại trong transaction; việc gửi chạy sau commit trên
 * executor riêng.
 */
@Slf4j
@Component
public class SosNotifier {

    public static final String TYPE = "SOS_ALERT";
    static final String QUEUE = "/queue/sos";

    public static final String EVENT_STARTED = "STARTED";
    public static final String EVENT_LOCATION = "LOCATION";
    public static final String EVENT_ACKNOWLEDGED = "ACKNOWLEDGED";
    public static final String EVENT_RESOLVED = "RESOLVED";

    /** Người nhận đã được chụp lại (không giữ entity sang luồng khác). */
    public record Recipient(String id, Locale locale) {
        public static Recipient of(User user) {
            return new Recipient(user.getId(), localeOf(user));
        }
    }

    private final MessageSource messageSource;
    private final IFCMService fcmService;
    private final INotificationService notificationService;
    private final SimpMessagingTemplate messagingTemplate;
    private final ISmsService smsService;
    private final ObjectMapper objectMapper;
    private final TaskExecutor executor;

    public SosNotifier(MessageSource messageSource, IFCMService fcmService,
            INotificationService notificationService, SimpMessagingTemplate messagingTemplate,
            ISmsService smsService, ObjectMapper objectMapper,
            @Qualifier(NotificationExecutorConfig.SOS_NOTIFICATION_EXECUTOR) TaskExecutor executor) {
        this.messageSource = messageSource;
        this.fcmService = fcmService;
        this.notificationService = notificationService;
        this.messagingTemplate = messagingTemplate;
        this.smsService = smsService;
        this.objectMapper = objectMapper;
        this.executor = executor;
    }

    /** SOS mới: báo toàn bộ admin và các liên hệ đã đồng ý. */
    public void notifyStarted(SosAlertResponse sos, User sender, List<User> admins, List<User> appContacts,
            List<String> smsPhones) {
        String name = displayName(sender);
        List<Recipient> adminRecipients = admins.stream().map(Recipient::of).toList();
        List<Recipient> contactRecipients = appContacts.stream().map(Recipient::of).toList();
        Locale senderLocale = localeOf(sender);
        String smsContent = msg("sms.sos.alert", new Object[] { name, mapsUrl(sos), phoneOrDash(sos) }, senderLocale);

        afterCommit(() -> {
            adminRecipients.forEach(r -> push(r, "notification.sos.new.title", "notification.sos.new.message",
                    new Object[] { name }, sos.getId()));
            contactRecipients.forEach(r -> push(r, "notification.sos.contact.title",
                    "notification.sos.contact.message", new Object[] { name }, sos.getId()));
            smsPhones.forEach(phone -> sendSms(phone, smsContent));
            realtime(ids(adminRecipients, contactRecipients), EVENT_STARTED, sos);
        });
    }

    /** Vị trí mới: chỉ phát realtime, không push để tránh làm phiền mỗi 15 giây. */
    public void notifyLocation(SosAlertResponse sos, Collection<String> watcherIds) {
        List<String> ids = List.copyOf(watcherIds);
        afterCommit(() -> realtime(ids, EVENT_LOCATION, sos));
    }

    /** Admin tiếp nhận: báo người gửi, cập nhật realtime cho mọi người đang theo dõi. */
    public void notifyAcknowledged(SosAlertResponse sos, User sender, User admin, Collection<String> watcherIds) {
        Recipient senderRecipient = Recipient.of(sender);
        String adminName = displayName(admin);
        List<String> ids = List.copyOf(watcherIds);
        afterCommit(() -> {
            push(senderRecipient, "notification.sos.acknowledged.title", "notification.sos.acknowledged.message",
                    new Object[] { adminName }, sos.getId());
            realtime(ids, EVENT_ACKNOWLEDGED, sos);
        });
    }

    /**
     * SOS kết thúc. {@code outcome}: safe | handled | false_alarm.
     * Người gửi chỉ được báo khi do admin kết thúc.
     */
    public void notifyResolved(SosAlertResponse sos, User sender, String outcome, boolean notifySender,
            List<User> admins, List<User> appContacts, List<String> smsPhones, Collection<String> watcherIds) {
        String name = displayName(sender);
        Recipient senderRecipient = Recipient.of(sender);
        List<Recipient> others = Stream.concat(admins.stream(), appContacts.stream())
                .map(Recipient::of).toList();
        String smsContent = msg("sms.sos.resolved", new Object[] { name }, localeOf(sender));
        List<String> ids = List.copyOf(watcherIds);
        String titleKey = "notification.sos.resolved." + outcome + ".title";
        String messageKey = "notification.sos.resolved." + outcome + ".message";

        afterCommit(() -> {
            others.forEach(r -> push(r, titleKey, messageKey, new Object[] { name }, sos.getId()));
            if (notifySender) {
                push(senderRecipient, "notification.sos.closed.title", "notification.sos.closed.message",
                        null, sos.getId());
            }
            smsPhones.forEach(phone -> sendSms(phone, smsContent));
            realtime(ids, EVENT_RESOLVED, sos);
        });
    }

    // Gửi

    private void push(Recipient recipient, String titleKey, String messageKey, Object[] args, String sosId) {
        executor.execute(() -> {
            try {
                String title = msg(titleKey, args, recipient.locale());
                String message = msg(messageKey, args, recipient.locale());
                Map<String, String> payloadMap = Map.of("sosId", sosId);
                String payload = objectMapper.writeValueAsString(payloadMap);
                String actionData = objectMapper.writeValueAsString(Map.of("type", TYPE, "payload", payloadMap));

                notificationService.createNotification(recipient.id(), title, message, actionData);
                messagingTemplate.convertAndSendToUser(recipient.id(), "/queue/notifications",
                        new NotificationEvent(title, message, actionData, null, Map.of("shouldRefresh", true)));
                fcmService.sendToUser(recipient.id(),
                        new NotificationRequest(title, message, Map.of("type", TYPE, "payload", payload)));
            } catch (Exception e) {
                log.warn("[SOS] Failed to notify user {} about {}: {}", recipient.id(), sosId, e.getMessage());
            }
        });
    }

    private void sendSms(String phone, String content) {
        executor.execute(() -> {
            if (!smsService.send(phone, content)) {
                log.warn("[SOS] SMS was not delivered to a contact");
            }
        });
    }

    private void realtime(Collection<String> userIds, String event, SosAlertResponse sos) {
        SosRealtimeEvent payload = new SosRealtimeEvent(event, sos);
        for (String userId : userIds) {
            try {
                messagingTemplate.convertAndSendToUser(userId, QUEUE, payload);
            } catch (Exception e) {
                log.warn("[SOS] Failed realtime {} to {}: {}", event, userId, e.getMessage());
            }
        }
    }

    private static void afterCommit(Runnable task) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    task.run();
                }
            });
        } else {
            task.run();
        }
    }

    // Helpers

    private String msg(String key, Object[] args, Locale locale) {
        return messageSource.getMessage(key, args, key, locale);
    }

    private static List<String> ids(List<Recipient> first, List<Recipient> second) {
        return Stream.concat(first.stream(), second.stream()).map(Recipient::id).distinct().toList();
    }

    static String mapsUrl(SosAlertResponse sos) {
        return String.format(Locale.ROOT, "https://maps.google.com/?q=%.6f,%.6f", sos.getLatitude(),
                sos.getLongitude());
    }

    private static String phoneOrDash(SosAlertResponse sos) {
        String phone = sos.getUser() != null ? sos.getUser().getPhone() : null;
        return phone == null || phone.isBlank() ? "-" : phone;
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
