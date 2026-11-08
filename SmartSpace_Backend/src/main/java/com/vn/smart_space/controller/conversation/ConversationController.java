package com.vn.smart_space.controller.conversation;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.vn.smart_space.dto.ApiResponse;
import com.vn.smart_space.dto.request.conversation.CreateConversationRequest;
import com.vn.smart_space.dto.response.conversation.ConversationDetailResponse;
import com.vn.smart_space.dto.response.conversation.ConversationInfoResponse;
import com.vn.smart_space.dto.response.conversation.CreateConversationResponse;
import com.vn.smart_space.service.chat.ChatPresenceService;
import com.vn.smart_space.service.conversation.IConversationService;
import com.vn.smart_space.service.position.IPositionService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/conversations")
public class ConversationController {

    private final IConversationService conversationService;
    private final ChatPresenceService chatPresenceService;
    private final IPositionService positionService;

    // 1. Create or Get Conversation
    @PostMapping("")
    public ResponseEntity<ApiResponse> createConversation(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody @Valid CreateConversationRequest request) {

        var userId = jwt.getClaim("userId").toString();
        CreateConversationResponse response = conversationService.createConversation(userId, request);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(response)
                .message("conversation.create.success")
                .build());
    }

    // 2. Get My Conversation list with optional role filter, position filter, and search query
    @GetMapping("/my-conversation")
    public ResponseEntity<ApiResponse> getMyConversation(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false, defaultValue = "1") int page,
            @RequestParam(required = false, defaultValue = "10") int size,
            @RequestParam(required = false, defaultValue = "all") String role,
            @RequestParam(required = false) List<String> positionIds,
            @RequestParam(required = false) String query) {

        var userId = jwt.getClaim("userId").toString();
        var data = conversationService.getMyConversation(userId, page, size, role, positionIds, query);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(data)
                .message("conversation.get.success")
                .build());
    }

    // 3. Get Conversation Detail
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse> getConversationDetail(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        ConversationDetailResponse data = conversationService.getConversationDetail(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(data)
                .message("conversation.get.success")
                .build());
    }

    // 3.1 Get Conversation Info & Active Linked Reports
    @GetMapping("/{id}/info")
    public ResponseEntity<ApiResponse> getConversationInfo(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        ConversationInfoResponse data = conversationService.getConversationInfo(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(data)
                .message("conversation.info.success")
                .build());
    }

    // 3.2 Get Linked Reports of Conversation with Pagination
    @GetMapping("/{id}/reports")
    public ResponseEntity<ApiResponse> getConversationReports(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id,
            @RequestParam(required = false) Boolean isAnonymous,
            @RequestParam(required = false, defaultValue = "1") int page,
            @RequestParam(required = false, defaultValue = "10") int size) {

        var userId = jwt.getClaim("userId").toString();
        com.vn.smart_space.dto.PageResponse<com.vn.smart_space.dto.response.conversation.LinkedReportResponse> data =
                conversationService.getConversationReports(userId, id, isAnonymous, page, size);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(data)
                .message("conversation.reports.success")
                .build());
    }

    // 4. Mark Conversation as Read
    @PostMapping("/{id}/read")
    public ResponseEntity<ApiResponse> markAsRead(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        conversationService.markAsRead(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .message("conversation.read.success")
                .build());
    }

    // 5. Get Total Unread Count for User
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse> getUnreadCount(@AuthenticationPrincipal Jwt jwt) {
        var userId = jwt.getClaim("userId").toString();
        Long count = conversationService.getUnreadCount(userId);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(count)
                .message("conversation.unread_count.success")
                .build());
    }

    // 6. Presence: Enter
    @PostMapping("/{id}/presence/enter")
    public ResponseEntity<ApiResponse> presenceEnter(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        chatPresenceService.enterConversation(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .message("presence.enter.success")
                .build());
    }

    // 7. Presence: Heartbeat
    @PostMapping("/{id}/presence/heartbeat")
    public ResponseEntity<ApiResponse> presenceHeartbeat(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        chatPresenceService.heartbeat(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .message("presence.heartbeat.success")
                .build());
    }

    // 8. Presence: Leave
    @PostMapping("/{id}/presence/leave")
    public ResponseEntity<ApiResponse> presenceLeave(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable String id) {

        var userId = jwt.getClaim("userId").toString();
        chatPresenceService.leaveConversation(userId, id);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .message("presence.leave.success")
                .build());
    }

    // 9. Search users for chat (Staff & Admin only, Client is blocked)
    @GetMapping("/search-users")
    public ResponseEntity<ApiResponse> searchUsersForChat(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false, defaultValue = "all") String role,
            @RequestParam(required = false) List<String> positionIds,
            @RequestParam(required = false) String query) {

        var userId = jwt.getClaim("userId").toString();
        var data = conversationService.searchUsersForChat(userId, role, positionIds, query);

        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(data)
                .message("conversation.search_users.success")
                .build());
    }

    // 10. Get Active Positions for Staff Filter
    @GetMapping("/positions")
    public ResponseEntity<ApiResponse> getPositions() {
        return ResponseEntity.ok(ApiResponse.builder()
                .success(true)
                .data(positionService.getPositions(true))
                .message("position.list.success")
                .build());
    }
}
