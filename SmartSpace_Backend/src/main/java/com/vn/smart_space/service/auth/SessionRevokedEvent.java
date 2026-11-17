package com.vn.smart_space.service.auth;

import java.util.List;

/**
 * Phát ra khi một hoặc nhiều phiên đăng nhập của user bị thu hồi từ thiết bị khác
 * ("Đăng xuất thiết bị" / "Đăng xuất tất cả thiết bị khác").
 *
 * Dùng event thay vì gọi SimpMessagingTemplate trực tiếp trong AuthenticationService
 * để tránh vòng phụ thuộc bean: WebSocket config → JwtChannelInterceptor → JwtDecoder
 * → AuthenticationService.
 */
public record SessionRevokedEvent(String userId, List<String> deviceIds) {
}
