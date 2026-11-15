package com.vn.smart_space.repository;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.AccountLockEvidence;

@Repository
public interface AccountLockEvidenceRepository extends JpaRepository<AccountLockEvidence, String> {

    @EntityGraph(attributePaths = { "report" })
    List<AccountLockEvidence> findByRequestIdOrderByCreatedAtAsc(String requestId);
}
