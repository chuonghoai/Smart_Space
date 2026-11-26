package com.vn.smart_space.dto.request.call;

import jakarta.validation.constraints.NotBlank;

public record CallSignalRequest(
        @NotBlank(message = "{call.id.required}") String callId,
        @NotBlank(message = "{call.signalType.required}") String signalType, // OFFER | ANSWER | ICE_CANDIDATE
        String sdp,
        String candidate,
        String sdpMid,
        Integer sdpMLineIndex
) {
}
