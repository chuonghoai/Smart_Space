package com.vn.smart_space.repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.EAccountLockRequestStatus;
import com.vn.smart_space.model.AccountLockRequest;

import jakarta.persistence.LockModeType;

@Repository
public interface AccountLockRequestRepository extends JpaRepository<AccountLockRequest, String> {

    /** Khóa ghi đề xuất để tuần tự hóa các phiếu bầu / hủy / hết hạn đồng thời. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM AccountLockRequest r WHERE r.id = :id")
    Optional<AccountLockRequest> findByIdForUpdate(@Param("id") String id);

    @EntityGraph(attributePaths = { "target", "proposer" })
    @Query("SELECT r FROM AccountLockRequest r WHERE r.id = :id")
    Optional<AccountLockRequest> findWithPeopleById(@Param("id") String id);

    Optional<AccountLockRequest> findFirstByTargetIdAndStatus(String targetId, EAccountLockRequestStatus status);

    boolean existsByTargetIdAndStatus(String targetId, EAccountLockRequestStatus status);

    @EntityGraph(attributePaths = { "target", "proposer" })
    Page<AccountLockRequest> findByStatusIn(Collection<EAccountLockRequestStatus> statuses, Pageable pageable);

    long countByStatus(EAccountLockRequestStatus status);

    long countByStatusIn(Collection<EAccountLockRequestStatus> statuses);

    /**
     * Đề xuất admin này còn phải biểu quyết: đang chờ, chưa quá hạn (scheduler có thể chưa chạy),
     * không phải người đề xuất và chưa bỏ phiếu.
     */
    String AWAITING_VOTE_WHERE = " WHERE r.status = :status AND r.expiresAt > :now " +
            "AND r.proposer.id <> :adminId " +
            "AND NOT EXISTS (SELECT 1 FROM AccountLockVote v WHERE v.request = r AND v.voter.id = :adminId)";

    @Query("SELECT COUNT(r) FROM AccountLockRequest r" + AWAITING_VOTE_WHERE)
    long countAwaitingVote(@Param("status") EAccountLockRequestStatus status, @Param("adminId") String adminId,
            @Param("now") LocalDateTime now);

    @EntityGraph(attributePaths = { "target", "proposer" })
    @Query(value = "SELECT r FROM AccountLockRequest r" + AWAITING_VOTE_WHERE,
            countQuery = "SELECT COUNT(r) FROM AccountLockRequest r" + AWAITING_VOTE_WHERE)
    Page<AccountLockRequest> findAwaitingVote(@Param("status") EAccountLockRequestStatus status,
            @Param("adminId") String adminId, @Param("now") LocalDateTime now, Pageable pageable);

    /** Hạn gần nhất trong các đề xuất admin này còn phải biểu quyết (null nếu không có). */
    @Query("SELECT MIN(r.expiresAt) FROM AccountLockRequest r" + AWAITING_VOTE_WHERE)
    LocalDateTime findNextAwaitingDeadline(@Param("status") EAccountLockRequestStatus status,
            @Param("adminId") String adminId, @Param("now") LocalDateTime now);

    @Query("SELECT r.id FROM AccountLockRequest r WHERE r.status = :status AND r.expiresAt < :now ORDER BY r.expiresAt ASC")
    List<String> findIdsByStatusAndExpiresAtBefore(
            @Param("status") EAccountLockRequestStatus status,
            @Param("now") LocalDateTime now,
            Pageable pageable);
}
