package com.vn.smart_space.model;

import java.time.LocalDateTime;

import com.vn.smart_space.consts.ECallStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "call_sessions", indexes = {
        @Index(name = "idx_call_sessions_caller_status", columnList = "caller_id, status"),
        @Index(name = "idx_call_sessions_receiver_status", columnList = "receiver_id, status"),
        @Index(name = "idx_call_sessions_status_expires", columnList = "status, expires_at")
})
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
public class CallSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "caller_id", nullable = false)
    private User caller;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false)
    private User receiver;

    @Column(name = "conversation_id")
    private String conversationId;

    @Column(name = "is_anonymous", nullable = false)
    @Builder.Default
    private Boolean isAnonymous = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 24)
    private ECallStatus status;

    @Column(name = "caller_device_id", length = 100)
    private String callerDeviceId;

    @Column(name = "accepted_device_id", length = 100)
    private String acceptedDeviceId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "ringing_at")
    private LocalDateTime ringingAt;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "connected_at")
    private LocalDateTime connectedAt;

    @Column(name = "ended_at")
    private LocalDateTime endedAt;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "end_reason", length = 100)
    private String endReason;
}
