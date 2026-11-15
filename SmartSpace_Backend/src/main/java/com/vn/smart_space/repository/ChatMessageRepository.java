package com.vn.smart_space.repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.ChatMessage;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, String> {

    @EntityGraph(attributePaths = { "sender", "report" })
    Page<ChatMessage> findByConversationIdOrderBySentAtDesc(String conversationId, Pageable pageable);

}
