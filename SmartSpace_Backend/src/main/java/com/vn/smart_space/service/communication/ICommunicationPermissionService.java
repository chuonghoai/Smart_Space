package com.vn.smart_space.service.communication;

import java.util.List;

import com.vn.smart_space.model.Conversation;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;

public interface ICommunicationPermissionService {

    /**
     * Evaluates messaging & voice-call eligibility between two users.
     * Uses the single canonical business rules across Chat, Conversation, and WebRTC Calls.
     */
    CommunicationEligibility evaluatePairEligibility(
            User actor,
            User target,
            String conversationId,
            Boolean requestedAnonymous);

    /**
     * Evaluates Admin <-> Client eligibility based strictly on whether the client has
     * at least one report marked unsatisfactory (isReviewResolved == false) AND currently processing.
     */
    CommunicationEligibility evaluateAdminClientEligibility(String clientId, Boolean requestedAnonymous);

    /**
     * Evaluates messaging & voice-call eligibility for an existing conversation from currentUser's perspective.
     */
    CommunicationEligibility evaluateConversationEligibility(String currentUserId, Conversation conversation);

    /**
     * Throws BadRequestException if sender is not allowed to send messages in the conversation.
     */
    void assertCanSendMessage(User sender, Conversation conversation);

    /**
     * Validates that all requested report IDs belong to the conversation's client and meet attachment rules.
     */
    List<Report> validateAndResolveAttachableReports(User sender, Conversation conversation, List<String> reportIds);

    /**
     * Returns true if conversation is strictly between 1 Admin and 1 Client.
     */
    boolean isAdminClientConversation(Conversation conversation);
}
