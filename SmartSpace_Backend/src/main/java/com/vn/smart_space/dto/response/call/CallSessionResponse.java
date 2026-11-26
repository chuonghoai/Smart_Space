package com.vn.smart_space.dto.response.call;

import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.vn.smart_space.consts.ECallStatus;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CallSessionResponse {
    private String callId;
    private String callerId;
    private String receiverId;
    private String conversationId;
    private Boolean isAnonymous;
    private ECallStatus status;
    private CallPeerResponse peer;
    private List<IceServerDto> iceServers;
    private LocalDateTime createdAt;
    private LocalDateTime ringingAt;
    private LocalDateTime acceptedAt;
    private LocalDateTime connectedAt;
    private LocalDateTime endedAt;
    private LocalDateTime expiresAt;
    private Integer ringTimeoutSeconds;
    private Integer signalingTimeoutSeconds;
    private Integer durationSeconds;
    private String endReason;
}
