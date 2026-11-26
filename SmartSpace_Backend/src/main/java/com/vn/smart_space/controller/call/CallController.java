package com.vn.smart_space.controller.call;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.call.CallActionRequest;
import com.vn.smart_space.dto.request.call.CallSignalRequest;
import com.vn.smart_space.dto.request.call.InitiateCallRequest;
import com.vn.smart_space.dto.response.call.CallPermissionResponse;
import com.vn.smart_space.dto.response.call.CallSessionResponse;
import com.vn.smart_space.dto.response.call.IceServerConfigResponse;
import com.vn.smart_space.service.call.ICallService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/calls")
public class CallController {

    private final ICallService callService;

    @GetMapping("/permission")
    public ResponseEntity<ApiResponse> checkPermission(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam String targetUserId,
            @RequestParam(required = false) String conversationId,
            @RequestParam(required = false) Boolean isAnonymous) {
        String callerId = jwt.getClaim("userId").toString();
        CallPermissionResponse data = callService.checkCallPermission(
                callerId, targetUserId, conversationId, isAnonymous);
        return ResponseEntity.ok(ApiResponse.success("call.permission.checked", data));
    }

    @GetMapping("/ice-servers")
    public ResponseEntity<ApiResponse> getIceServers(@AuthenticationPrincipal Jwt jwt) {
        String userId = jwt.getClaim("userId").toString();
        IceServerConfigResponse data = callService.getIceServers(userId);
        return ResponseEntity.ok(ApiResponse.success("call.ice_servers.success", data));
    }

    @PostMapping("")
    public ResponseEntity<ApiResponse> initiateCall(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid InitiateCallRequest request) {
        String callerId = jwt.getClaim("userId").toString();
        String deviceId = jwt.getClaimAsString("deviceId");
        CallSessionResponse data = callService.initiateCall(callerId, deviceId, request);
        return ResponseEntity.ok(ApiResponse.success("call.initiated", data));
    }

    @GetMapping("/{callId}")
    public ResponseEntity<ApiResponse> getCallStatus(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId) {
        String userId = jwt.getClaim("userId").toString();
        CallSessionResponse data = callService.getCallStatus(userId, callId);
        return ResponseEntity.ok(ApiResponse.success("system.success", data));
    }

    @PostMapping("/{callId}/ringing")
    public ResponseEntity<ApiResponse> acknowledgeRinging(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId) {
        String userId = jwt.getClaim("userId").toString();
        String deviceId = jwt.getClaimAsString("deviceId");
        CallSessionResponse data = callService.acknowledgeRinging(userId, deviceId, callId);
        return ResponseEntity.ok(ApiResponse.success("call.ringing.ack", data));
    }

    @PostMapping("/{callId}/accept")
    public ResponseEntity<ApiResponse> acceptCall(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId) {
        String userId = jwt.getClaim("userId").toString();
        String deviceId = jwt.getClaimAsString("deviceId");
        CallSessionResponse data = callService.acceptCall(userId, deviceId, callId);
        return ResponseEntity.ok(ApiResponse.success("call.accepted", data));
    }

    @PostMapping("/{callId}/reject")
    public ResponseEntity<ApiResponse> rejectCall(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId,
            @RequestBody(required = false) CallActionRequest request) {
        String userId = jwt.getClaim("userId").toString();
        String reason = request != null ? request.reason() : null;
        CallSessionResponse data = callService.rejectCall(userId, callId, reason);
        return ResponseEntity.ok(ApiResponse.success("call.rejected", data));
    }

    @PostMapping("/{callId}/cancel")
    public ResponseEntity<ApiResponse> cancelCall(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId) {
        String userId = jwt.getClaim("userId").toString();
        CallSessionResponse data = callService.cancelCall(userId, callId);
        return ResponseEntity.ok(ApiResponse.success("call.cancelled", data));
    }

    @PostMapping("/{callId}/connected")
    public ResponseEntity<ApiResponse> markConnected(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId) {
        String userId = jwt.getClaim("userId").toString();
        CallSessionResponse data = callService.markConnected(userId, callId);
        return ResponseEntity.ok(ApiResponse.success("call.connected", data));
    }

    @PostMapping("/{callId}/end")
    public ResponseEntity<ApiResponse> endCall(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId,
            @RequestBody(required = false) CallActionRequest request) {
        String userId = jwt.getClaim("userId").toString();
        String reason = request != null ? request.reason() : null;
        CallSessionResponse data = callService.endCall(userId, callId, reason);
        return ResponseEntity.ok(ApiResponse.success("call.ended", data));
    }

    @PostMapping("/{callId}/fail")
    public ResponseEntity<ApiResponse> markFailed(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId,
            @RequestBody(required = false) CallActionRequest request) {
        String userId = jwt.getClaim("userId").toString();
        String reason = request != null ? request.reason() : null;
        CallSessionResponse data = callService.markFailed(userId, callId, reason);
        return ResponseEntity.ok(ApiResponse.success("call.failed", data));
    }

    @PostMapping("/{callId}/signal")
    public ResponseEntity<ApiResponse> relaySignal(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String callId,
            @RequestBody @Valid CallSignalRequest request) {
        String userId = jwt.getClaim("userId").toString();
        CallSignalRequest normalized = new CallSignalRequest(
                callId,
                request.signalType(),
                request.sdp(),
                request.candidate(),
                request.sdpMid(),
                request.sdpMLineIndex());
        callService.relaySignal(userId, normalized);
        return ResponseEntity.ok(ApiResponse.success("system.success", null));
    }
}
