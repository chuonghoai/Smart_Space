package com.vn.smart_space.mapper;

import java.util.Optional;

import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.dto.response.conversation.ParticipantResponse;
import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.ConversationParticipant;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;

public final class ConversationMapper {
    private ConversationMapper() {
    }

    public static CreateConversationResponse toConversationResponse(String currentUserId, Conversation conversation) {
        EConversationType conversationType = conversation.getConversationType();

        PartnerInfo partnerInfo = extractPartnerInfo(currentUserId, conversation);
        Report report = conversation.getReport();

        boolean canSendMessage = true;
        String reportId = null;
        String reportTitle = null;
        String reportStatus = null;
        if (report != null) {
            reportId = report.getId();
            reportTitle = report.getTitle();
            reportStatus = report.getStatus() != null ? report.getStatus().name() : null;
            canSendMessage = report.getStatus() == EReportStatus.processing;
        }

        return CreateConversationResponse.builder()
                .id(conversation.getId())
                .conversationType(conversationType)
                .name(partnerInfo.name != null ? partnerInfo.name : conversation.getName())
                .conversationAvatar(conversationType == EConversationType.PRIVATE ? partnerInfo.avatarUrl : conversation.getConversationAvatar())
                .participantInfo(conversation.getParticipants().stream()
                        .map(p -> toParticipantResponse(p.getUser()))
                        .toList())
                .partnerId(partnerInfo.userId)
                .partnerName(partnerInfo.name)
                .partnerAvatarUrl(partnerInfo.avatarUrl)
                .partnerRole(partnerInfo.role)
                .partnerPosition(partnerInfo.position)
                .isAnonymous(partnerInfo.isAnonymous)
                .reportId(reportId)
                .reportTitle(reportTitle)
                .reportStatus(reportStatus)
                .canSendMessage(canSendMessage)
                .createdAt(conversation.getCreatedAt())
                .build();
    }

    public static ConversationDetailResponse toConversationDetailResponse(String currentUserId, Conversation conversation) {
        EConversationType conversationType = conversation.getConversationType();

        PartnerInfo partnerInfo = extractPartnerInfo(currentUserId, conversation);
        Report report = conversation.getReport();

        boolean canSendMessage = true;
        String reportId = null;
        String reportTitle = null;
        String reportStatus = null;
        if (report != null) {
            reportId = report.getId();
            reportTitle = report.getTitle();
            reportStatus = report.getStatus() != null ? report.getStatus().name() : null;
            canSendMessage = report.getStatus() == EReportStatus.processing;
        }

        // Get unread count for current user
        int unreadCount = conversation.getParticipants().stream()
                .filter(p -> p.getUser().getId().equals(currentUserId))
                .findFirst()
                .map(p -> p.getUnreadCount() != null ? p.getUnreadCount() : 0)
                .orElse(0);

        return ConversationDetailResponse.builder()
                .id(conversation.getId())
                .conversationType(conversationType)
                .name(partnerInfo.name != null ? partnerInfo.name : conversation.getName())
                .conversationAvatar(conversationType == EConversationType.PRIVATE ? partnerInfo.avatarUrl : conversation.getConversationAvatar())
                .participantInfo(conversation.getParticipants().stream()
                        .map(p -> toParticipantResponse(p.getUser()))
                        .toList())
                .partnerId(partnerInfo.userId)
                .partnerName(partnerInfo.name)
                .partnerAvatarUrl(partnerInfo.avatarUrl)
                .partnerRole(partnerInfo.role)
                .partnerPosition(partnerInfo.position)
                .isAnonymous(partnerInfo.isAnonymous)
                .reportId(reportId)
                .reportTitle(reportTitle)
                .reportStatus(reportStatus)
                .canSendMessage(canSendMessage)
                .unreadCount(unreadCount)
                .lastMessageId(conversation.getLastMessageId())
                .lastMessageContent(conversation.getLastMessageContent())
                .lastMessageTime(conversation.getLastMessageTime())
                .createdAt(conversation.getCreatedAt())
                .build();
    }

    public static ParticipantResponse toParticipantResponse(User user) {
        String positionName = null;
        if (user.getRole() == ERole.staff) {
            positionName = user.getPosition() != null ? user.getPosition().getName() : "Nhân viên chưa có chức vụ";
        }
        return ParticipantResponse.builder()
                .userId(user.getId())
                .username(user.getFullName())
                .name(user.getFullName())
                .role(user.getRole())
                .avatarUrl(user.getAvatarUrl())
                .position(positionName)
                .build();
    }

    private static PartnerInfo extractPartnerInfo(String currentUserId, Conversation conversation) {
        PartnerInfo info = new PartnerInfo();
        if (conversation.getConversationType() != EConversationType.PRIVATE) {
            return info;
        }

        Optional<ConversationParticipant> partnerOpt = conversation.getParticipants().stream()
                .filter(p -> !p.getUser().getId().equals(currentUserId))
                .findFirst();

        if (partnerOpt.isEmpty()) {
            return info;
        }

        User partner = partnerOpt.get().getUser();
        info.userId = partner.getId();
        info.role = partner.getRole();

        // Check anonymous client
        Report report = conversation.getReport();
        boolean isAnon = report != null && Boolean.TRUE.equals(report.getIsAnonymous()) && partner.getRole() == ERole.client;
        info.isAnonymous = isAnon;

        if (isAnon) {
            info.name = "Người dùng ẩn danh";
            info.avatarUrl = null;
        } else {
            info.name = partner.getFullName();
            info.avatarUrl = partner.getAvatarUrl();
        }

        if (partner.getRole() == ERole.staff) {
            info.position = partner.getPosition() != null ? partner.getPosition().getName() : "Nhân viên chưa có chức vụ";
        }

        return info;
    }

    private static class PartnerInfo {
        String userId;
        String name;
        String avatarUrl;
        ERole role;
        String position;
        boolean isAnonymous = false;
    }
}
