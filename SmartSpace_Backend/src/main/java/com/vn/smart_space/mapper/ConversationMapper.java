package com.vn.smart_space.mapper;

import java.util.Optional;

import com.vn.smart_space.consts.EConversationType;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.dto.response.conversation.LinkedReportResponse;
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

        if (conversation.getReports() != null && !conversation.getReports().isEmpty()) {
            Report activeReport = conversation.getReports().stream()
                    .filter(r -> r.getStatus() == EReportStatus.processing
                            || (r.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(r.getIsReviewResolved())))
                    .findFirst()
                    .orElse(conversation.getReports().get(0));
            reportId = activeReport.getId();
            reportTitle = activeReport.getTitle();
            reportStatus = activeReport.getStatus() != null ? activeReport.getStatus().name() : null;
            canSendMessage = conversation.getReports().stream()
                    .anyMatch(r -> r.getStatus() == EReportStatus.processing
                            || (r.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(r.getIsReviewResolved())));
        } else if (report != null) {
            reportId = report.getId();
            reportTitle = report.getTitle();
            reportStatus = report.getStatus() != null ? report.getStatus().name() : null;
            canSendMessage = report.getStatus() == EReportStatus.processing
                    || (report.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(report.getIsReviewResolved()));
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
                .partnerPhone(partnerInfo.phone)
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

        if (conversation.getReports() != null && !conversation.getReports().isEmpty()) {
            Report activeReport = conversation.getReports().stream()
                    .filter(r -> r.getStatus() == EReportStatus.processing
                            || (r.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(r.getIsReviewResolved())))
                    .findFirst()
                    .orElse(conversation.getReports().get(0));
            reportId = activeReport.getId();
            reportTitle = activeReport.getTitle();
            reportStatus = activeReport.getStatus() != null ? activeReport.getStatus().name() : null;
            canSendMessage = conversation.getReports().stream()
                    .anyMatch(r -> r.getStatus() == EReportStatus.processing
                            || (r.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(r.getIsReviewResolved())));
        } else if (report != null) {
            reportId = report.getId();
            reportTitle = report.getTitle();
            reportStatus = report.getStatus() != null ? report.getStatus().name() : null;
            canSendMessage = report.getStatus() == EReportStatus.processing
                    || (report.getStatus() == EReportStatus.processed && Boolean.FALSE.equals(report.getIsReviewResolved()));
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
                .partnerPhone(partnerInfo.phone)
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
        boolean isAnon = Boolean.TRUE.equals(conversation.getIsAnonymous()) && partner.getRole() == ERole.client;
        if (!isAnon) {
            Report report = conversation.getReport();
            isAnon = report != null && Boolean.TRUE.equals(report.getIsAnonymous()) && partner.getRole() == ERole.client;
        }
        if (!isAnon && conversation.getReports() != null && !conversation.getReports().isEmpty() && partner.getRole() == ERole.client) {
            isAnon = conversation.getReports().stream().anyMatch(r -> Boolean.TRUE.equals(r.getIsAnonymous()));
        }
        info.isAnonymous = isAnon;

        if (isAnon) {
            info.name = "Người dùng ẩn danh";
            info.avatarUrl = null;
            info.phone = null;
        } else {
            info.name = partner.getFullName();
            info.avatarUrl = partner.getAvatarUrl();
            info.phone = partner.getPhone();
        }

        if (partner.getRole() == ERole.staff) {
            info.position = partner.getPosition() != null ? partner.getPosition().getName() : "Nhân viên chưa có chức vụ";
        }

        return info;
    }

    public static LinkedReportResponse toLinkedReportResponse(Report r) {
        if (r == null) {
            return null;
        }
        boolean isRehandling = (r.getStatus() == EReportStatus.processing || r.getStatus() == EReportStatus.processed)
                && Boolean.FALSE.equals(r.getIsReviewResolved());
        return LinkedReportResponse.builder()
                .id(r.getId())
                .title(r.getTitle())
                .description(r.getDescription())
                .imageUrl(r.getImageUrl())
                .status(r.getStatus() != null ? r.getStatus().name() : null)
                .severity(r.getSeverity() != null ? r.getSeverity().name() : null)
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .address(r.getAddress())
                .isReviewResolved(r.getIsReviewResolved())
                .needsRehandling(isRehandling)
                .build();
    }

    private static class PartnerInfo {
        String userId;
        String name;
        String avatarUrl;
        ERole role;
        String position;
        String phone;
        boolean isAnonymous = false;
    }
}
