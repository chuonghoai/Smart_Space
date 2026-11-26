package com.vn.smart_space.dto.response.sos;

/**
 * Sự kiện realtime gửi riêng từng người qua /user/queue/sos.
 *
 * @param event STARTED | LOCATION | ACKNOWLEDGED | RESOLVED
 */
public record SosRealtimeEvent(String event, SosAlertResponse sos) {
}
