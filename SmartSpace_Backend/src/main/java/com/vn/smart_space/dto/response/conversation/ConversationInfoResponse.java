package com.vn.smart_space.dto.response.conversation;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
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
public class ConversationInfoResponse {
    private String id;

    // Partner profile
    private String partnerId;
    private String partnerName;
    private String partnerAvatarUrl;
    private ERole partnerRole;
    private String partnerPosition;
    private String partnerPhone;
    private String partnerEmail;
    private Boolean isAnonymous;

    // Messaging permission
    @Builder.Default
    private Boolean canSendMessage = true;

    // Context-based messaging for Client
    private String identifiedConversationId;
    private String anonymousConversationId;
    private Boolean hasIdentifiedContext;
    private Boolean hasAnonymousContext;
    private String activeContext; // "IDENTIFIED" or "ANONYMOUS"
    private Integer identifiedUnreadCount;
    private Integer anonymousUnreadCount;
    private Boolean canSendIdentifiedMessage;
    private Boolean canSendAnonymousMessage;

    // Active reports currently in 'processing' status
    @Builder.Default
    private List<LinkedReportResponse> activeReports = new ArrayList<>();

    private LocalDateTime createdAt;
}

