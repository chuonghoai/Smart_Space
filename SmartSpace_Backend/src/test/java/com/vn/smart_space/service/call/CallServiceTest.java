package com.vn.smart_space.service.call;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import com.vn.smart_space.configuration.websocket.WebSocketSessionRegistry;
import com.vn.smart_space.consts.ECallStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.call.CallSignalRequest;
import com.vn.smart_space.dto.request.call.InitiateCallRequest;
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

@ExtendWith(MockitoExtension.class)
class CallServiceTest {

    @Mock
    private CallSessionRepository callSessionRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private ICommunicationPermissionService communicationPermissionService;
    @Mock
    private TurnCredentialService turnCredentialService;
    @Mock
    private SimpMessagingTemplate messagingTemplate;
    @Mock
    private WebSocketSessionRegistry wsSessionRegistry;
    @Mock
    private MessageSource messageSource;

    @InjectMocks
    private CallService callService;

    private User caller;
    private User receiver;
    private User outsider;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(callService, "connectingTimeoutSeconds", 10);
        ReflectionTestUtils.setField(callService, "ringTimeoutSeconds", 45);
        ReflectionTestUtils.setField(callService, "signalingTimeoutSeconds", 25);
        ReflectionTestUtils.setField(callService, "maxDurationSeconds", 3600);

        caller = User.builder().fullName("Staff A").email("a@test.local").role(ERole.staff).status(EUserStatus.active).build();
        caller.setId("u-caller");

        receiver = User.builder().fullName("Admin B").email("b@test.local").role(ERole.admin).status(EUserStatus.active).build();
        receiver.setId("u-receiver");

        outsider = User.builder().fullName("Client C").email("c@test.local").role(ERole.client).status(EUserStatus.active).build();
        outsider.setId("u-outsider");
    }

    @Test
    @DisplayName("Denied call does NOT create CallSession or send WS invite")
    void initiateDeniedDoesNotCreateSessionOrPush() {
        when(userRepository.findById("u-caller")).thenReturn(Optional.of(caller));
        when(userRepository.findById("u-outsider")).thenReturn(Optional.of(outsider));
        when(communicationPermissionService.evaluatePairEligibility(caller, outsider, null, null))
                .thenReturn(CommunicationEligibility.denied("chat.report.not_processing"));

        assertThrows(BadRequestException.class, () ->
                callService.initiateCall("u-caller", "dev-1", new InitiateCallRequest("u-outsider", null, null)));

        verify(callSessionRepository, never()).save(any());
        verify(messagingTemplate, never()).convertAndSendToUser(anyString(), eq("/queue/call"), any());
    }

    @Test
    @DisplayName("Receiver offline/terminated (no valid WS): returns call.cannot_connect without saving session")
    void initiateWhenReceiverHasNoValidWebSocketFailsImmediately() {
        when(userRepository.findById("u-caller")).thenReturn(Optional.of(caller));
        when(userRepository.findById("u-receiver")).thenReturn(Optional.of(receiver));
        when(communicationPermissionService.evaluatePairEligibility(eq(caller), eq(receiver), isNull(), any()))
                .thenReturn(CommunicationEligibility.allowed(false, 0));
        when(wsSessionRegistry.hasValidCallConnection("u-caller")).thenReturn(true);
        when(wsSessionRegistry.hasValidCallConnection("u-receiver")).thenReturn(false);

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                callService.initiateCall("u-caller", "dev-1", new InitiateCallRequest("u-receiver", null, null)));

        assertEquals("call.cannot_connect", ex.getMessage());
        verify(callSessionRepository, never()).save(any());
        verify(messagingTemplate, never()).convertAndSendToUser(anyString(), eq("/queue/call"), any());
    }

    @Test
    @DisplayName("Caller offline (no valid WS): returns call.cannot_connect")
    void initiateWhenCallerHasNoValidWebSocketFailsImmediately() {
        when(userRepository.findById("u-caller")).thenReturn(Optional.of(caller));
        when(userRepository.findById("u-receiver")).thenReturn(Optional.of(receiver));
        when(communicationPermissionService.evaluatePairEligibility(eq(caller), eq(receiver), isNull(), any()))
                .thenReturn(CommunicationEligibility.allowed(false, 0));
        when(wsSessionRegistry.hasValidCallConnection("u-caller")).thenReturn(false);

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                callService.initiateCall("u-caller", "dev-1", new InitiateCallRequest("u-receiver", null, null)));

        assertEquals("call.cannot_connect", ex.getMessage());
        verify(callSessionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Full Call Lifecycle: CONNECTING -> RINGING (only on ACK) -> ACCEPTED -> ONGOING -> ENDED")
    void fullCallLifecycleTransitionsCorrectly() {
        when(userRepository.findById("u-caller")).thenReturn(Optional.of(caller));
        when(userRepository.findById("u-receiver")).thenReturn(Optional.of(receiver));
        when(communicationPermissionService.evaluatePairEligibility(eq(caller), eq(receiver), isNull(), any()))
                .thenReturn(CommunicationEligibility.allowed(false, 0));
        when(wsSessionRegistry.hasValidCallConnection("u-caller")).thenReturn(true);
        when(wsSessionRegistry.hasValidCallConnection("u-receiver")).thenReturn(true);
        when(callSessionRepository.findActiveCallsByUserId(anyString())).thenReturn(List.of());
        when(turnCredentialService.buildIceServersForUser(anyString()))
                .thenReturn(IceServerConfigResponse.builder()
                        .iceServers(List.of(IceServerDto.builder().urls(List.of("stun:stun.l.google.com:19302")).build()))
                        .build());
        when(callSessionRepository.save(any(CallSession.class))).thenAnswer(inv -> {
            CallSession s = inv.getArgument(0);
            if (s.getId() == null) s.setId("call-123");
            return s;
        });

        // 1. Initiate -> CONNECTING (WS CALL_INCOMING sent, never RINGING yet)
        CallSessionResponse initiated = callService.initiateCall(
                "u-caller", "dev-caller", new InitiateCallRequest("u-receiver", null, null));
        assertEquals(ECallStatus.CONNECTING, initiated.getStatus());
        verify(messagingTemplate).convertAndSendToUser(eq("u-receiver"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_INCOMING".equals(m.get("eventType"))));

        CallSession stored = CallSession.builder()
                .id("call-123")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.CONNECTING)
                .isAnonymous(false)
                .createdAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusSeconds(10))
                .build();
        when(callSessionRepository.findByIdWithUsers("call-123")).thenReturn(Optional.of(stored));

        // 2. Receiver confirms WS CALL_INCOMING received -> RINGING
        CallSessionResponse ringing = callService.acknowledgeRinging("u-receiver", "dev-rx", "call-123");
        assertEquals(ECallStatus.RINGING, ringing.getStatus());

        // 3. Receiver accepts -> ACCEPTED (NOT ONGOING yet!) & notifies other devices via WS
        CallSessionResponse accepted = callService.acceptCall("u-receiver", "dev-rx", "call-123");
        assertEquals(ECallStatus.ACCEPTED, accepted.getStatus());
        verify(messagingTemplate).convertAndSendToUser(eq("u-receiver"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_HANDLED_ELSEWHERE".equals(m.get("eventType"))));

        // Second device attempting to accept same CallSession must fail
        assertThrows(BadRequestException.class, () ->
                callService.acceptCall("u-receiver", "dev-rx-2", "call-123"));

        // 4. WebRTC PeerConnection connected -> ONGOING
        CallSessionResponse ongoing = callService.markConnected("u-caller", "call-123");
        assertEquals(ECallStatus.ONGOING, ongoing.getStatus());

        // 5. End call -> ENDED
        CallSessionResponse ended = callService.endCall("u-caller", "call-123", "HANGUP");
        assertEquals(ECallStatus.ENDED, ended.getStatus());
        assertNotNull(ended.getDurationSeconds());
    }

    @Test
    @DisplayName("Receiver WS disconnects while ringing -> session transitions to FAILED and notifies caller")
    void disconnectWhileRingingFailsCallAndNotifiesPeer() {
        CallSession ringing = CallSession.builder()
                .id("call-ring-drop")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.RINGING)
                .expiresAt(LocalDateTime.now().plusSeconds(30))
                .build();
        when(wsSessionRegistry.hasValidCallConnection("u-receiver")).thenReturn(false);
        when(callSessionRepository.findActiveCallsByUserId("u-receiver")).thenReturn(List.of(ringing));
        when(callSessionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        callService.handleUserWebSocketDisconnected("u-receiver", "sess-rx", "dev-rx");

        assertEquals(ECallStatus.FAILED, ringing.getStatus());
        assertEquals("PEER_DISCONNECTED", ringing.getEndReason());
        verify(messagingTemplate).convertAndSendToUser(eq("u-caller"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_FAILED".equals(m.get("eventType"))));
    }

    @Test
    @DisplayName("Expired CONNECTING call transitions to FAILED (never MISSED)")
    void expiredConnectingCallTransitionsToFailed() {
        CallSession stuckConnecting = CallSession.builder()
                .id("call-stuck")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.CONNECTING)
                .expiresAt(LocalDateTime.now().minusSeconds(1))
                .build();
        when(wsSessionRegistry.evictStaleSessions()).thenReturn(List.of());
        when(callSessionRepository.findByStatusInAndExpiresAtBefore(anyList(), any()))
                .thenReturn(List.of(stuckConnecting));
        when(callSessionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        callService.expireStaleCalls();

        assertEquals(ECallStatus.FAILED, stuckConnecting.getStatus());
        assertEquals("RECEIVER_UNREACHABLE", stuckConnecting.getEndReason());
        verify(messagingTemplate).convertAndSendToUser(eq("u-caller"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_FAILED".equals(m.get("eventType"))));
    }

    @Test
    @DisplayName("Non-participant cannot relay WebRTC signaling")
    void outsiderCannotRelaySignal() {
        CallSession stored = CallSession.builder()
                .id("call-123")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.ACCEPTED)
                .expiresAt(LocalDateTime.now().plusSeconds(25))
                .build();
        when(callSessionRepository.findByIdWithUsers("call-123")).thenReturn(Optional.of(stored));

        assertThrows(BadRequestException.class, () ->
                callService.relaySignal("u-outsider", new CallSignalRequest("call-123", "OFFER", "v=0...", null, null, null)));
    }

    @Test
    @DisplayName("Accepting an expired call is rejected and transitions to MISSED")
    void acceptingExpiredCallRejected() {
        CallSession expired = CallSession.builder()
                .id("call-exp")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.RINGING)
                .expiresAt(LocalDateTime.now().minusSeconds(5))
                .build();
        when(callSessionRepository.findByIdWithUsers("call-exp")).thenReturn(Optional.of(expired));
        when(callSessionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        assertThrows(BadRequestException.class, () ->
                callService.acceptCall("u-receiver", "dev-rx", "call-exp"));
        assertEquals(ECallStatus.MISSED, expired.getStatus());
    }

    @Test
    @DisplayName("Cancel while ringing notifies receiver; Reject notifies caller")
    void cancelAndRejectNotifyPeer() {
        CallSession ringing = CallSession.builder()
                .id("call-ring")
                .caller(caller)
                .receiver(receiver)
                .status(ECallStatus.RINGING)
                .expiresAt(LocalDateTime.now().plusSeconds(30))
                .build();
        when(callSessionRepository.findByIdWithUsers("call-ring")).thenReturn(Optional.of(ringing));
        when(callSessionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CallSessionResponse cancelled = callService.cancelCall("u-caller", "call-ring");
        assertEquals(ECallStatus.CANCELLED, cancelled.getStatus());
        verify(messagingTemplate).convertAndSendToUser(eq("u-receiver"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_CANCELLED".equals(m.get("eventType"))));

        ringing.setStatus(ECallStatus.RINGING);
        CallSessionResponse rejected = callService.rejectCall("u-receiver", "call-ring", "BUSY");
        assertEquals(ECallStatus.REJECTED, rejected.getStatus());
        verify(messagingTemplate).convertAndSendToUser(eq("u-caller"), eq("/queue/call"), argThat(map ->
                map instanceof java.util.Map<?, ?> m && "CALL_REJECTED".equals(m.get("eventType"))));
    }
}
