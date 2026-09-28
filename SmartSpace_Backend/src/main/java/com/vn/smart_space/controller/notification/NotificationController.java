package com.vn.smart_space.controller.notification;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.notification.NotificationRequest;
import com.vn.smart_space.dto.response.notification.NotificationCountResponse;
import com.vn.smart_space.dto.response.notification.NotificationResponse;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/notifications")
public class NotificationController {
    private final IFCMService fcmService;
    private final INotificationService notificationService;

    @PostMapping("/test")
    public ResponseEntity<ApiResponse> testPush(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaim("userId").toString();

        fcmService.sendToUser(
                userId,
                new NotificationRequest(
                        "SmartSpace Test",
                        "Notification đã hoạt động!",
                        Map.of("type", "test", "timestamp", String.valueOf(System.currentTimeMillis()))));

        return ResponseEntity.ok(ApiResponse.success("notification.test.success", null));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse> getUnreadCount(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaim("userId").toString();
        NotificationCountResponse response = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(ApiResponse.success("system.success", response));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse> getMyNotifications(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        String userId = jwt.getClaim("userId").toString();
        PageResponse<NotificationResponse> response = notificationService.getMyNotifications(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success("system.success", response));
    }

    @PutMapping("/my/read-all")
    public ResponseEntity<ApiResponse> markAllAsRead(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaim("userId").toString();
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success("system.success", null));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse> markAsRead(@org.springframework.web.bind.annotation.PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaim("userId").toString();
        notificationService.markAsRead(userId, id);
        return ResponseEntity.ok(ApiResponse.success("system.success", null));
    }
}
