package com.vn.smart_space.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.ConversationParticipant;

@Repository
public interface ConversationParticipantRepository extends JpaRepository<ConversationParticipant, String> {

    Optional<ConversationParticipant> findByConversationIdAndUserId(String conversationId, String userId);

    @Query("SELECT COALESCE(SUM(cp.unreadCount), 0) FROM ConversationParticipant cp WHERE cp.user.id = :userId")
    Long countTotalUnreadByUserId(@Param("userId") String userId);

}

