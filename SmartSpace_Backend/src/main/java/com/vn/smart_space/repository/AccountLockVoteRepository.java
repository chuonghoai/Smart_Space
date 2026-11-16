package com.vn.smart_space.repository;

import java.util.Collection;
import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.EAccountLockVoteDecision;
import com.vn.smart_space.model.AccountLockVote;

@Repository
public interface AccountLockVoteRepository extends JpaRepository<AccountLockVote, String> {

    boolean existsByRequestIdAndVoterId(String requestId, String voterId);

    long countByRequestIdAndDecision(String requestId, EAccountLockVoteDecision decision);

    @EntityGraph(attributePaths = { "voter" })
    List<AccountLockVote> findByRequestIdOrderByCreatedAtAsc(String requestId);

    /** Phiếu của nhiều đề xuất một lần (danh sách) — tránh N+1. */
    List<AccountLockVote> findByRequestIdIn(Collection<String> requestIds);
}
