package com.vn.smart_space.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.model.Conversation;

@Repository
public interface ConversationRepository extends JpaRepository<Conversation, String> {

    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    Optional<Conversation> findByParticipantHash(String participantHash);

    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    Optional<Conversation> findByReportId(String reportId);

    // Get Page Conversation - All
    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    @Query("SELECT DISTINCT c FROM Conversation c JOIN c.participants p WHERE p.user.id = :userId ORDER BY c.lastMessageTime DESC NULLS LAST")
    Page<Conversation> findAllByUserId(@Param("userId") String userId, Pageable pageable);

    // Get Page Conversation - All with search query
    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    @Query("SELECT DISTINCT c FROM Conversation c JOIN c.participants p " +
            "WHERE p.user.id = :userId " +
            "AND (LOWER(c.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "     OR LOWER(c.lastMessageContent) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "     OR EXISTS (SELECT p2 FROM c.participants p2 WHERE p2.user.id <> :userId AND LOWER(p2.user.fullName) LIKE LOWER(CONCAT('%', :query, '%')))) " +
            "ORDER BY c.lastMessageTime DESC NULLS LAST")
    Page<Conversation> findAllByUserIdAndQuery(@Param("userId") String userId, @Param("query") String query, Pageable pageable);

    // Get Page Conversation - Filtered by partner role
    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    @Query("SELECT DISTINCT c FROM Conversation c " +
            "JOIN c.participants p " +
            "WHERE p.user.id = :userId " +
            "AND EXISTS (SELECT p2 FROM c.participants p2 WHERE p2.user.id <> :userId AND p2.user.role = :role) " +
            "ORDER BY c.lastMessageTime DESC NULLS LAST")
    Page<Conversation> findAllByUserIdAndRole(@Param("userId") String userId, @Param("role") ERole role, Pageable pageable);

    // Get Page Conversation - Filtered by partner role and search query
    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    @Query("SELECT DISTINCT c FROM Conversation c " +
            "JOIN c.participants p " +
            "WHERE p.user.id = :userId " +
            "AND EXISTS (SELECT p2 FROM c.participants p2 WHERE p2.user.id <> :userId AND p2.user.role = :role " +
            "            AND (LOWER(p2.user.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(c.lastMessageContent) LIKE LOWER(CONCAT('%', :query, '%')))) " +
            "ORDER BY c.lastMessageTime DESC NULLS LAST")
    Page<Conversation> findAllByUserIdAndRoleAndQuery(@Param("userId") String userId, @Param("role") ERole role, @Param("query") String query, Pageable pageable);

    // Check conversation exists and sender is member
    @EntityGraph(attributePaths = { "participants", "participants.user", "participants.user.position", "report" })
    @Query("SELECT c FROM Conversation c " +
            "WHERE c.id = :conversationId " +
            "AND EXISTS(SELECT p FROM c.participants p WHERE p.user.id = :userId)")
    Optional<Conversation> findByIdAndMember(@Param("conversationId") String conversationId,
            @Param("userId") String userId);

}
