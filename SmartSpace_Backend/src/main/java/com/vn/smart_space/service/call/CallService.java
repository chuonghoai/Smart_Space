package com.vn.smart_space.service.call;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.configuration.websocket.WebSocketSessionRegistry;
import com.vn.smart_space.consts.ECallStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.call.CallSignalRequest;
import com.vn.smart_space.dto.request.call.InitiateCallRequest;
import com.vn.smart_space.dto.response.call.CallPeerResponse;
import com.vn.smart_space.dto.response.call.CallPermissionResponse;
import com.vn.smart_space.dto.response.call.CallSessionResponse;
import com.vn.smart_space.dto.response.call.IceServerConfigResponse;
import com.vn.smart_space.dto.response.call.IceServerDto;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.CallSession;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.CallSessionRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.communication.CommunicationEligibility;
import com.vn.smart_space.service.communication.ICommunicationPermissionService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j(topic = "CALL-SERVICE")
public class CallService implements ICallService {

    private final CallSessionRepository callSessionRepository;
    private final UserRepository userRepository;
    private final ICommunicationPermissionService communicationPermissionService;
    private final TurnCredentialService turnCredentialService;
    private final SimpMessagingTemplate messagingTemplate;
    private final WebSocketSessionRegistry wsSessionRegistry;
    private final MessageSource messageSource;

    @Value("${webrtc.call.connecting-timeout-seconds:10}")
    private int connectingTimeoutSeconds = 10;

    @Value("${webrtc.call.ring-timeout-seconds:45}")
    private int ringTimeoutSeconds = 45;

    @Value("${webrtc.call.signaling-timeout-seconds:25}")
    private int signalingTimeoutSeconds = 25;

    @Value("${webrtc.call.max-duration-seconds:3600}")
    private int maxDurationSeconds = 3600;

    @Override
    @Transactional(readOnly = true)
    public CallPermissionResponse checkCallPermission(
            String callerId,
            String receiverId,
            String conversationId,
            Boolean isAnonymous) {
        User caller = userRepository.findById(callerId)
                .orElseThrow(() -> new BadRequestException("user.not_found"));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new BadRequestException("user.not_found"));

        CommunicationEligibility eligibility = communicationPermissionService.evaluatePairEligibility(
                caller, receiver, conversationId, isAnonymous);

        String reasonMessage = null;
        if (!eligibility.canVoiceCall() && eligibility.reasonCode() != null) {
            Locale locale = LocaleContextHolder.getLocale();
            reasonMessage = messageSource.getMessage(
                    eligibility.reasonCode(), null, eligibility.reasonCode(), locale);
        }

        return CallPermissionResponse.builder()
                .allowed(eligibility.canVoiceCall())
                .canMessage(eligibility.canMessage())
                .isAnonymous(eligibility.isAnonymous())
                .reasonCode(eligibility.reasonCode())
                .reasonMessage(reasonMessage)
                .eligibleRehandlingReportCount(eligibility.eligibleRehandlingReportCount())
                .build();
    }

    @Override
    public IceServerConfigResponse getIceServers(String userId) {
        return turnCredentialService.buildIceServersForUser(userId);
    }

    @Override
    @Transactional
    public CallSessionResponse initiateCall(String callerId, String callerDeviceId, InitiateCallRequest request) {
        User caller = userRepository.findById(callerId)
                .orElseThrow(() -> new BadRequestException("user.not_found"));
        User receiver = userRepository.findById(request.receiverId())
                .orElseThrow(() -> new BadRequestException("user.not_found"));

        CommunicationEligibility eligibility = communicationPermissionService.evaluatePairEligibility(
                caller, receiver, request.conversationId(), request.isAnonymous());
        if (!eligibility.canVoiceCall()) {
            throw new BadRequestException(
                    eligibility.reasonCode() != null ? eligibility.reasonCode() : "call.permission.denied");
        }

        // Strict live-WebSocket requirement: both caller and receiver must have valid active call WS
        if (!wsSessionRegistry.hasValidCallConnection(callerId)) {
            log.info("Call rejected: caller {} has no valid live WebSocket call connection", callerId);
            throw new BadRequestException("call.cannot_connect");
        }
        if (!wsSessionRegistry.hasValidCallConnection(receiver.getId())) {
            log.info("Call rejected: receiver {} has no valid live WebSocket call connection", receiver.getId());
            throw new BadRequestException("call.cannot_connect");
        }

        // Prevent concurrent active calls on either caller or receiver
        if (!callSessionRepository.findActiveCallsByUserId(callerId).isEmpty()) {
            throw new BadRequestException("call.caller.busy");
        }
        if (!callSessionRepository.findActiveCallsByUserId(receiver.getId()).isEmpty()) {
            throw new BadRequestException("call.receiver.busy");
        }

        LocalDateTime now = LocalDateTime.now();
        int effectiveConnectingTimeout = Math.max(5, connectingTimeoutSeconds);
        int effectiveRingTimeout = Math.max(15, ringTimeoutSeconds);
        CallSession session = CallSession.builder()
                .caller(caller)
                .receiver(receiver)
                .conversationId(request.conversationId())
                .isAnonymous(eligibility.isAnonymous())
                .status(ECallStatus.CONNECTING)
                .callerDeviceId(callerDeviceId)
                .createdAt(now)
                .expiresAt(now.plusSeconds(effectiveConnectingTimeout))
                .build();
        session = callSessionRepository.save(session);

        List<IceServerDto> iceServers = turnCredentialService.buildIceServersForUser(callerId).getIceServers();
        CallPeerResponse callerPeerForReceiver = buildPeerInfo(caller, session.getIsAnonymous(), receiver);
        CallPeerResponse receiverPeerForCaller = buildPeerInfo(receiver, session.getIsAnonymous(), caller);

        // Push CALL_INCOMING strictly via WebSocket to receiver
        Map<String, Object> wsEvent = new HashMap<>();
        wsEvent.put("eventType", "CALL_INCOMING");
        wsEvent.put("callId", session.getId());
        wsEvent.put("status", session.getStatus().name());
        wsEvent.put("callerId", caller.getId());
        wsEvent.put("receiverId", receiver.getId());
        wsEvent.put("conversationId", session.getConversationId());
        wsEvent.put("isAnonymous", session.getIsAnonymous());
        wsEvent.put("expiresAt", session.getExpiresAt().toString());
        wsEvent.put("ringTimeoutSeconds", effectiveRingTimeout);
        wsEvent.put("peer", callerPeerForReceiver);
        sendWsToUser(receiver.getId(), wsEvent);

        return toSessionResponse(session, receiverPeerForCaller, iceServers);
    }

    @Override
    @Transactional
    public CallSessionResponse acknowledgeRinging(String receiverId, String deviceId, String callId) {
        CallSession session = loadAndVerifyParticipant(callId, receiverId);
        if (!Objects.equals(session.getReceiver().getId(), receiverId)) {
            throw new BadRequestException("call.permission.not_receiver");
        }

        if (isExpired(session)) {
            if (session.getStatus() == ECallStatus.CONNECTING) {
                failSessionOnDisconnect(session, receiverId, LocalDateTime.now(), "RECEIVER_UNREACHABLE");
            } else {
                markMissedInternal(session, "RING_TIMEOUT");
            }
            throw new BadRequestException("call.session.expired");
        }

        if (session.getStatus() == ECallStatus.CONNECTING) {
            LocalDateTime now = LocalDateTime.now();
            session.setStatus(ECallStatus.RINGING);
            session.setRingingAt(now);
            session.setExpiresAt(now.plusSeconds(Math.max(15, ringTimeoutSeconds)));
            session = callSessionRepository.save(session);

            Map<String, Object> wsEvent = new HashMap<>();
            wsEvent.put("eventType", "CALL_RINGING");
            wsEvent.put("callId", session.getId());
            wsEvent.put("status", session.getStatus().name());
            wsEvent.put("ringingAt", session.getRingingAt().toString());
            sendWsToUser(session.getCaller().getId(), wsEvent);
        } else if (session.getStatus() != ECallStatus.RINGING) {
            throw new BadRequestException("call.session.invalid_state");
        }

        return toSessionResponse(session,
                buildPeerInfo(session.getCaller(), session.getIsAnonymous(), session.getReceiver()), null);
    }

    @Override
    @Transactional
    public CallSessionResponse acceptCall(String receiverId, String deviceId, String callId) {
        CallSession session = loadAndVerifyParticipant(callId, receiverId);
        if (!Objects.equals(session.getReceiver().getId(), receiverId)) {
            throw new BadRequestException("call.permission.not_receiver");
        }

        if (session.getStatus() != ECallStatus.CONNECTING && session.getStatus() != ECallStatus.RINGING) {
            throw new BadRequestException("call.session.invalid_state");
        }
        if (session.getAcceptedDeviceId() != null) {
            throw new BadRequestException("call.session.invalid_state");
        }

        if (isExpired(session)) {
            markMissedInternal(session, "RING_TIMEOUT");
            throw new BadRequestException("call.session.expired");
        }

        if (!wsSessionRegistry.hasValidCallConnection(session.getCaller().getId())) {
            failSessionOnDisconnect(session, session.getCaller().getId(), LocalDateTime.now(), "CALLER_DISCONNECTED");
            throw new BadRequestException("call.cannot_connect");
        }

        // Re-verify permission at accept time (in case report status changed while ringing)
        CommunicationEligibility eligibility = communicationPermissionService.evaluatePairEligibility(
                session.getCaller(), session.getReceiver(), session.getConversationId(), session.getIsAnonymous());
        if (!eligibility.canVoiceCall()) {
            session.setStatus(ECallStatus.FAILED);
            session.setEndedAt(LocalDateTime.now());
            session.setEndReason("PERMISSION_REVOKED");
            callSessionRepository.save(session);
            notifyPeerTerminalEvent(session, session.getCaller().getId(), "CALL_FAILED", "PERMISSION_REVOKED");
            throw new BadRequestException(
                    eligibility.reasonCode() != null ? eligibility.reasonCode() : "call.permission.denied");
        }

        LocalDateTime now = LocalDateTime.now();
        int effectiveSignalingTimeout = Math.max(10, signalingTimeoutSeconds);
        session.setStatus(ECallStatus.ACCEPTED);
        session.setAcceptedAt(now);
        session.setAcceptedDeviceId(deviceId != null ? deviceId : "device");
        session.setExpiresAt(now.plusSeconds(effectiveSignalingTimeout));
        session = callSessionRepository.save(session);

        // Notify caller via WebSocket that receiver accepted so caller sends SDP Offer
        Map<String, Object> callerEvent = new HashMap<>();
        callerEvent.put("eventType", "CALL_ACCEPTED");
        callerEvent.put("callId", session.getId());
        callerEvent.put("status", session.getStatus().name());
        callerEvent.put("acceptedAt", now.toString());
        sendWsToUser(session.getCaller().getId(), callerEvent);

        // Stop ringing on other logged-in WebSocket sessions of the same receiver
        Map<String, Object> elsewhereEvent = new HashMap<>();
        elsewhereEvent.put("eventType", "CALL_HANDLED_ELSEWHERE");
        elsewhereEvent.put("callId", session.getId());
        elsewhereEvent.put("acceptedDeviceId", session.getAcceptedDeviceId());
        sendWsToUser(receiverId, elsewhereEvent);

        List<IceServerDto> iceServers = turnCredentialService.buildIceServersForUser(receiverId).getIceServers();
        return toSessionResponse(session,
                buildPeerInfo(session.getCaller(), session.getIsAnonymous(), session.getReceiver()), iceServers);
    }

    @Override
    @Transactional
    public CallSessionResponse rejectCall(String receiverId, String callId, String reason) {
        CallSession session = loadAndVerifyParticipant(callId, receiverId);
        if (!Objects.equals(session.getReceiver().getId(), receiverId)) {
            throw new BadRequestException("call.permission.not_receiver");
        }

        if (isTerminal(session.getStatus())) {
            return toSessionResponse(session, null, null);
        }

        session.setStatus(ECallStatus.REJECTED);
        session.setEndedAt(LocalDateTime.now());
        session.setEndReason(reason != null && !reason.isBlank() ? reason : "REJECTED");
        session = callSessionRepository.save(session);

        notifyPeerTerminalEvent(session, session.getCaller().getId(), "CALL_REJECTED", session.getEndReason());
        // Dismiss ringing UI on receiver's other connected devices via WebSocket
        sendWsToUser(receiverId, Map.of("eventType", "CALL_HANDLED_ELSEWHERE", "callId", session.getId()));

        return toSessionResponse(session, null, null);
    }

    @Override
    @Transactional
    public CallSessionResponse cancelCall(String callerId, String callId) {
        CallSession session = loadAndVerifyParticipant(callId, callerId);
        if (!Objects.equals(session.getCaller().getId(), callerId)) {
            throw new BadRequestException("call.permission.not_caller");
        }

        if (isTerminal(session.getStatus())) {
            return toSessionResponse(session, null, null);
        }
        if (session.getStatus() == ECallStatus.ONGOING) {
            return endCall(callerId, callId, "ENDED");
        }

        session.setStatus(ECallStatus.CANCELLED);
        session.setEndedAt(LocalDateTime.now());
        session.setEndReason("CANCELLED_BY_CALLER");
        session = callSessionRepository.save(session);

        notifyPeerTerminalEvent(session, session.getReceiver().getId(), "CALL_CANCELLED", session.getEndReason());

        return toSessionResponse(session, null, null);
    }

    @Override
    @Transactional
    public CallSessionResponse markConnected(String userId, String callId) {
        CallSession session = loadAndVerifyParticipant(callId, userId);

        if (session.getStatus() == ECallStatus.ONGOING) {
            return toSessionResponse(session, null, null);
        }
        if (session.getStatus() != ECallStatus.ACCEPTED) {
            throw new BadRequestException("call.session.invalid_state");
        }

        LocalDateTime now = LocalDateTime.now();
        session.setStatus(ECallStatus.ONGOING);
        session.setConnectedAt(now);
        session.setExpiresAt(now.plusSeconds(Math.max(60, maxDurationSeconds)));
        session = callSessionRepository.save(session);

        Map<String, Object> ongoingEvent = new HashMap<>();
        ongoingEvent.put("eventType", "CALL_ONGOING");
        ongoingEvent.put("callId", session.getId());
        ongoingEvent.put("status", session.getStatus().name());
        ongoingEvent.put("connectedAt", now.toString());

        sendWsToUser(session.getCaller().getId(), ongoingEvent);
        sendWsToUser(session.getReceiver().getId(), ongoingEvent);

        return toSessionResponse(session, null, null);
    }

    @Override
    @Transactional
    public CallSessionResponse endCall(String userId, String callId, String reason) {
        CallSession session = loadAndVerifyParticipant(callId, userId);

        if (isTerminal(session.getStatus())) {
            return toSessionResponse(session, null, null);
        }

        LocalDateTime now = LocalDateTime.now();
        if (session.getStatus() == ECallStatus.CONNECTING || session.getStatus() == ECallStatus.RINGING) {
            if (Objects.equals(session.getCaller().getId(), userId)) {
                return cancelCall(userId, callId);
            } else {
                return rejectCall(userId, callId, reason);
            }
        }

        session.setStatus(ECallStatus.ENDED);
        session.setEndedAt(now);
        session.setEndReason(reason != null && !reason.isBlank() ? reason : "ENDED");
        if (session.getConnectedAt() != null) {
            long secs = Math.max(0, ChronoUnit.SECONDS.between(session.getConnectedAt(), now));
            session.setDurationSeconds((int) secs);
        }
        session = callSessionRepository.save(session);

        String peerId = Objects.equals(session.getCaller().getId(), userId)
                ? session.getReceiver().getId()
                : session.getCaller().getId();
        notifyPeerTerminalEvent(session, peerId, "CALL_ENDED", session.getEndReason());

        return toSessionResponse(session, null, null);
    }

    @Override
    @Transactional
    public CallSessionResponse markFailed(String userId, String callId, String reason) {
        CallSession session = loadAndVerifyParticipant(callId, userId);

        if (isTerminal(session.getStatus())) {
            return toSessionResponse(session, null, null);
        }

        LocalDateTime now = LocalDateTime.now();
        session.setStatus(ECallStatus.FAILED);
        session.setEndedAt(now);
        session.setEndReason(reason != null && !reason.isBlank() ? reason : "WEBRTC_FAILED");
        if (session.getConnectedAt() != null) {
            long secs = Math.max(0, ChronoUnit.SECONDS.between(session.getConnectedAt(), now));
            session.setDurationSeconds((int) secs);
        }
        session = callSessionRepository.save(session);

        String peerId = Objects.equals(session.getCaller().getId(), userId)
                ? session.getReceiver().getId()
                : session.getCaller().getId();
        notifyPeerTerminalEvent(session, peerId, "CALL_FAILED", session.getEndReason());

        return toSessionResponse(session, null, null);
    }

    @Override
    @Transactional(readOnly = true)
    public CallSessionResponse getCallStatus(String userId, String callId) {
        CallSession session = loadAndVerifyParticipant(callId, userId);
        User other = Objects.equals(session.getCaller().getId(), userId)
                ? session.getReceiver()
                : session.getCaller();
        User viewer = Objects.equals(session.getCaller().getId(), userId)
                ? session.getCaller()
                : session.getReceiver();
        return toSessionResponse(session, buildPeerInfo(other, session.getIsAnonymous(), viewer), null);
    }

    @Override
    @Transactional(readOnly = true)
    public void relaySignal(String senderId, CallSignalRequest request) {
        CallSession session = loadAndVerifyParticipant(request.callId(), senderId);

        if (session.getStatus() != ECallStatus.ACCEPTED
                && session.getStatus() != ECallStatus.ONGOING
                && session.getStatus() != ECallStatus.RINGING) {
            throw new BadRequestException("call.session.invalid_state");
        }

        String peerId = Objects.equals(session.getCaller().getId(), senderId)
                ? session.getReceiver().getId()
                : session.getCaller().getId();

        Map<String, Object> signalEvent = new HashMap<>();
        signalEvent.put("eventType", "CALL_SIGNAL");
        signalEvent.put("callId", session.getId());
        signalEvent.put("senderId", senderId);
        signalEvent.put("signalType", request.signalType());
        if (request.sdp() != null) signalEvent.put("sdp", request.sdp());
        if (request.candidate() != null) signalEvent.put("candidate", request.candidate());
        if (request.sdpMid() != null) signalEvent.put("sdpMid", request.sdpMid());
        if (request.sdpMLineIndex() != null) signalEvent.put("sdpMLineIndex", request.sdpMLineIndex());

        sendWsToUser(peerId, signalEvent);
    }

    @Override
    @Transactional
    public void handleUserWebSocketDisconnected(String userId, String sessionId, String deviceId) {
        if (userId == null || userId.isBlank()) {
            return;
        }
        boolean stillHasValidWs = wsSessionRegistry.hasValidCallConnection(userId);
        List<CallSession> activeCalls = callSessionRepository.findActiveCallsByUserId(userId);
        if (activeCalls == null || activeCalls.isEmpty()) {
            return;
        }

        LocalDateTime now = LocalDateTime.now();
        for (CallSession session : activeCalls) {
            if (isTerminal(session.getStatus())) {
                continue;
            }
            if (stillHasValidWs) {
                if (session.getStatus() == ECallStatus.ACCEPTED
                        && session.getAcceptedDeviceId() != null
                        && Objects.equals(session.getAcceptedDeviceId(), deviceId)) {
                    failSessionOnDisconnect(session, userId, now, "PEER_DISCONNECTED");
                }
                continue;
            }

            if (session.getStatus() == ECallStatus.CONNECTING
                    || session.getStatus() == ECallStatus.RINGING
                    || session.getStatus() == ECallStatus.ACCEPTED) {
                failSessionOnDisconnect(session, userId, now, "PEER_DISCONNECTED");
            } else if (session.getStatus() == ECallStatus.ONGOING) {
                LocalDateTime graceExpiry = now.plusSeconds(10);
                if (session.getExpiresAt() == null || session.getExpiresAt().isAfter(graceExpiry)) {
                    session.setExpiresAt(graceExpiry);
                    callSessionRepository.save(session);
                }
            }
        }
    }

    @Override
    @Scheduled(fixedDelay = 5000)
    @Transactional
    public void expireStaleCalls() {
        for (WebSocketSessionRegistry.ActiveWsSession evicted : wsSessionRegistry.evictStaleSessions()) {
            try {
                handleUserWebSocketDisconnected(evicted.userId(), evicted.sessionId(), evicted.deviceId());
            } catch (Exception e) {
                log.warn("Failed to process stale WS eviction for user {}: {}", evicted.userId(), e.getMessage());
            }
        }

        LocalDateTime now = LocalDateTime.now();
        List<CallSession> expired = callSessionRepository.findByStatusInAndExpiresAtBefore(
                List.of(ECallStatus.CONNECTING, ECallStatus.RINGING, ECallStatus.ACCEPTED, ECallStatus.ONGOING),
                now);

        for (CallSession session : expired) {
            try {
                if (session.getStatus() == ECallStatus.CONNECTING) {
                    session.setStatus(ECallStatus.FAILED);
                    session.setEndedAt(now);
                    session.setEndReason("RECEIVER_UNREACHABLE");
                    callSessionRepository.save(session);
                    notifyPeerTerminalEvent(session, session.getCaller().getId(), "CALL_FAILED", "RECEIVER_UNREACHABLE");
                    notifyPeerTerminalEvent(session, session.getReceiver().getId(), "CALL_FAILED", "RECEIVER_UNREACHABLE");
                } else if (session.getStatus() == ECallStatus.RINGING) {
                    markMissedInternal(session, "RING_TIMEOUT");
                } else if (session.getStatus() == ECallStatus.ACCEPTED) {
                    session.setStatus(ECallStatus.FAILED);
                    session.setEndedAt(now);
                    session.setEndReason("SIGNALING_TIMEOUT");
                    callSessionRepository.save(session);
                    notifyPeerTerminalEvent(session, session.getCaller().getId(), "CALL_FAILED", "SIGNALING_TIMEOUT");
                    notifyPeerTerminalEvent(session, session.getReceiver().getId(), "CALL_FAILED", "SIGNALING_TIMEOUT");
                } else if (session.getStatus() == ECallStatus.ONGOING) {
                    boolean bothConnected = wsSessionRegistry.hasValidCallConnection(session.getCaller().getId())
                            && wsSessionRegistry.hasValidCallConnection(session.getReceiver().getId());
                    String reason = bothConnected ? "MAX_DURATION_REACHED" : "WS_DISCONNECTED";
                    String eventType = bothConnected ? "CALL_ENDED" : "CALL_FAILED";
                    session.setStatus(bothConnected ? ECallStatus.ENDED : ECallStatus.FAILED);
                    session.setEndedAt(now);
                    session.setEndReason(reason);
                    if (session.getConnectedAt() != null) {
                        session.setDurationSeconds((int) Math.max(0,
                                ChronoUnit.SECONDS.between(session.getConnectedAt(), now)));
                    }
                    callSessionRepository.save(session);
                    notifyPeerTerminalEvent(session, session.getCaller().getId(), eventType, reason);
                    notifyPeerTerminalEvent(session, session.getReceiver().getId(), eventType, reason);
                }
            } catch (Exception e) {
                log.warn("Failed to expire call session {}: {}", session.getId(), e.getMessage());
            }
        }
    }

    private void failSessionOnDisconnect(
            CallSession session, String disconnectedUserId, LocalDateTime now, String reason) {
        session.setStatus(ECallStatus.FAILED);
        session.setEndedAt(now);
        session.setEndReason(reason);
        callSessionRepository.save(session);

        String peerId = Objects.equals(session.getCaller().getId(), disconnectedUserId)
                ? session.getReceiver().getId()
                : session.getCaller().getId();
        notifyPeerTerminalEvent(session, peerId, "CALL_FAILED", reason);
    }

    private void markMissedInternal(CallSession session, String reason) {
        session.setStatus(ECallStatus.MISSED);
        session.setEndedAt(LocalDateTime.now());
        session.setEndReason(reason);
        callSessionRepository.save(session);
        notifyPeerTerminalEvent(session, session.getCaller().getId(), "CALL_MISSED", reason);
        notifyPeerTerminalEvent(session, session.getReceiver().getId(), "CALL_MISSED", reason);
    }

    private CallSession loadAndVerifyParticipant(String callId, String userId) {
        CallSession session = callSessionRepository.findByIdWithUsers(callId)
                .orElseThrow(() -> new BadRequestException("call.session.not_found"));
        boolean isCaller = session.getCaller() != null && Objects.equals(session.getCaller().getId(), userId);
        boolean isReceiver = session.getReceiver() != null && Objects.equals(session.getReceiver().getId(), userId);
        if (!isCaller && !isReceiver) {
            throw new BadRequestException("call.permission.not_participant");
        }
        return session;
    }

    private boolean isExpired(CallSession session) {
        return session.getExpiresAt() != null && LocalDateTime.now().isAfter(session.getExpiresAt());
    }

    private boolean isTerminal(ECallStatus status) {
        return status == ECallStatus.REJECTED
                || status == ECallStatus.ENDED
                || status == ECallStatus.FAILED
                || status == ECallStatus.CANCELLED
                || status == ECallStatus.MISSED;
    }

    private CallPeerResponse buildPeerInfo(User peer, Boolean sessionAnonymous, User viewer) {
        boolean maskPeer = Boolean.TRUE.equals(sessionAnonymous) && peer.getRole() == ERole.client;
        if (maskPeer) {
            Locale locale = Locale.forLanguageTag(viewer != null && viewer.getLanguage() != null ? viewer.getLanguage() : "vi");
            String anonName = messageSource.getMessage("chat.anonymous_user", null, "Người dùng ẩn danh", locale);
            return CallPeerResponse.builder()
                    .id(peer.getId())
                    .fullName(anonName)
                    .avatarUrl(null)
                    .role(peer.getRole())
                    .isAnonymous(true)
                    .build();
        }

        String pos = null;
        if (peer.getRole() == ERole.staff) {
            pos = peer.getPosition() != null ? peer.getPosition().getName() : null;
        }
        String displayName = (peer.getFullName() != null && !peer.getFullName().isBlank())
                ? peer.getFullName().trim()
                : peer.getEmail();

        return CallPeerResponse.builder()
                .id(peer.getId())
                .fullName(displayName)
                .avatarUrl(peer.getAvatarUrl())
                .role(peer.getRole())
                .position(pos)
                .isAnonymous(false)
                .build();
    }

    private CallSessionResponse toSessionResponse(CallSession s, CallPeerResponse peer, List<IceServerDto> iceServers) {
        return CallSessionResponse.builder()
                .callId(s.getId())
                .callerId(s.getCaller().getId())
                .receiverId(s.getReceiver().getId())
                .conversationId(s.getConversationId())
                .isAnonymous(s.getIsAnonymous())
                .status(s.getStatus())
                .peer(peer)
                .iceServers(iceServers)
                .createdAt(s.getCreatedAt())
                .ringingAt(s.getRingingAt())
                .acceptedAt(s.getAcceptedAt())
                .connectedAt(s.getConnectedAt())
                .endedAt(s.getEndedAt())
                .expiresAt(s.getExpiresAt())
                .ringTimeoutSeconds(ringTimeoutSeconds)
                .signalingTimeoutSeconds(signalingTimeoutSeconds)
                .durationSeconds(s.getDurationSeconds())
                .endReason(s.getEndReason())
                .build();
    }

    private void sendWsToUser(String userId, Map<String, Object> payload) {
        try {
            messagingTemplate.convertAndSendToUser(userId, "/queue/call", payload);
        } catch (Exception e) {
            log.warn("Failed to push call WS event to user {}: {}", userId, e.getMessage());
        }
    }

    private void notifyPeerTerminalEvent(CallSession session, String targetUserId, String eventType, String reason) {
        Map<String, Object> event = new HashMap<>();
        event.put("eventType", eventType);
        event.put("callId", session.getId());
        event.put("status", session.getStatus().name());
        event.put("endReason", reason);
        if (session.getDurationSeconds() != null) {
            event.put("durationSeconds", session.getDurationSeconds());
        }
        sendWsToUser(targetUserId, event);
    }
}
