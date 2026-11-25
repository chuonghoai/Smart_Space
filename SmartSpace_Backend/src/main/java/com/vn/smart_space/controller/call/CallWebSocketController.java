package com.vn.smart_space.controller.call;

import java.security.Principal;
import java.util.Map;

import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import com.vn.smart_space.configuration.websocket.WebSocketSessionRegistry;
import com.vn.smart_space.dto.request.call.CallActionRequest;
import com.vn.smart_space.dto.request.call.CallSignalRequest;
import com.vn.smart_space.service.call.ICallService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Controller
@RequiredArgsConstructor
@Slf4j(topic = "CALL-WS")
public class CallWebSocketController {

    private final ICallService callService;
    private final SimpMessagingTemplate messagingTemplate;
    private final WebSocketSessionRegistry wsSessionRegistry;

    @MessageMapping("/call.ping")
    public void onPing(SimpMessageHeaderAccessor accessor, Principal principal) {
        if (principal == null || accessor == null) {
            return;
        }
        String sessionId = accessor.getSessionId();
        if (sessionId != null) {
            wsSessionRegistry.touchSession(sessionId);
            wsSessionRegistry.markCallQueueSubscribed(sessionId, true);
        }
    }

    @MessageMapping("/call.ringing")
    public void onRinging(@Payload CallActionRequest request, Principal principal) {
        if (principal == null || request == null || request.callId() == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.acknowledgeRinging(userId, null, request.callId());
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    @MessageMapping("/call.signal")
    public void onSignal(@Payload @Valid CallSignalRequest request, Principal principal) {
        if (principal == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.relaySignal(userId, request);
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    @MessageMapping("/call.connected")
    public void onConnected(@Payload CallActionRequest request, Principal principal) {
        if (principal == null || request == null || request.callId() == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.markConnected(userId, request.callId());
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    @MessageMapping("/call.reject")
    public void onReject(@Payload CallActionRequest request, Principal principal) {
        if (principal == null || request == null || request.callId() == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.rejectCall(userId, request.callId(), request.reason());
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    @MessageMapping("/call.cancel")
    public void onCancel(@Payload CallActionRequest request, Principal principal) {
        if (principal == null || request == null || request.callId() == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.cancelCall(userId, request.callId());
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    @MessageMapping("/call.end")
    public void onEnd(@Payload CallActionRequest request, Principal principal) {
        if (principal == null || request == null || request.callId() == null) {
            return;
        }
        String userId = principal.getName();
        try {
            callService.endCall(userId, request.callId(), request.reason());
        } catch (Exception e) {
            sendWsError(userId, request.callId(), e.getMessage());
        }
    }

    private void sendWsError(String userId, String callId, String reason) {
        log.warn("Call WS error for user {} on call {}: {}", userId, callId, reason);
        try {
            messagingTemplate.convertAndSendToUser(
                    userId,
                    "/queue/call",
                    Map.of(
                            "eventType", "CALL_ERROR",
                            "callId", callId != null ? callId : "",
                            "error", reason != null ? reason : "call.error"));
        } catch (Exception ignored) {
        }
    }
}
