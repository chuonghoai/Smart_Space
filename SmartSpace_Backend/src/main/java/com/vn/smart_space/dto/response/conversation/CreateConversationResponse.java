package com.vn.smart_space.dto.response.conversation;

import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.ERole;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CreateConversationResponse {
    private String id;
    private String name;
    private String conversationAvatar;
    private EConversationType conversationType;
    private List<ParticipantResponse> participantInfo;

    private String partnerId;
    private String partnerName;
    private String partnerAvatarUrl;
    private ERole partnerRole;
    private String partnerPosition;
    private String partnerPhone;
    private Boolean isAnonymous;

    private String reportId;
    private String reportTitle;
    private String reportStatus;
    private Boolean canSendMessage;

    private LocalDateTime createdAt;
}
