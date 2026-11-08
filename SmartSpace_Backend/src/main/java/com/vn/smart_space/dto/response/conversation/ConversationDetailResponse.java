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
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ConversationDetailResponse {
    private String id;
    private EConversationType conversationType;
    private String name;
    private String conversationAvatar;
    private List<ParticipantResponse> participantInfo;

    // Partner info for 1-1 conversations
    private String partnerId;
    private String partnerName;
    private String partnerAvatarUrl;
    private ERole partnerRole;
    private String partnerPosition;
    private Boolean isAnonymous;

    // Report context (if attached)
    private String reportId;
    private String reportTitle;
    private String reportStatus;

    // Messaging permission
    @Builder.Default
    private Boolean canSendMessage = true;

    // Unread count for current user
    @Builder.Default
    private Integer unreadCount = 0;

    // Last message info
    private String lastMessageId;
    private String lastMessageContent;
    private LocalDateTime lastMessageTime;
    private String lastMessageSenderId;

    private LocalDateTime createdAt;
}
