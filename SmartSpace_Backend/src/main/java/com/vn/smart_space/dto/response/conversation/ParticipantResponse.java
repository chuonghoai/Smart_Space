package com.vn.smart_space.dto.response.conversation;

import com.vn.smart_space.consts.ERole;
import lombok.Builder;

@Builder
public record ParticipantResponse(
        String userId,
        String username,
        String name,
        ERole role,
        String avatarUrl,
        String position
) {
}
