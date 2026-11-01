package com.vn.smart_space.repository;

import com.vn.smart_space.consts.EDelegationStatus;
import com.vn.smart_space.model.ReportDelegation;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface ReportDelegationRepository extends JpaRepository<ReportDelegation, String> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT d FROM ReportDelegation d WHERE d.id = :id")
    Optional<ReportDelegation> findByIdForUpdate(@Param("id") String id);

    /** Chỉ lấy report id (không nạp entity) để khoá report trước yêu cầu, giữ đúng thứ tự khoá. */
    @Query("SELECT d.report.id FROM ReportDelegation d WHERE d.id = :id")
    Optional<String> findReportIdById(@Param("id") String id);

    /** Yêu cầu đang chiếm task (PENDING/ACCEPTED) — tối đa một bản ghi nhờ khoá report khi tạo. */
    @EntityGraph(attributePaths = { "requester", "helper" })
    Optional<ReportDelegation> findFirstByReportIdAndStatusInOrderByCreatedAtDesc(
            String reportId, Collection<EDelegationStatus> statuses);

    @EntityGraph(attributePaths = { "report", "requester", "helper" })
    Page<ReportDelegation> findByHelperIdOrderByCreatedAtDesc(String helperId, Pageable pageable);

    @EntityGraph(attributePaths = { "report", "requester", "helper" })
    Page<ReportDelegation> findByRequesterIdOrderByCreatedAtDesc(String requesterId, Pageable pageable);

    long countByHelperIdAndStatus(String helperId, EDelegationStatus status);

    /** Id các yêu cầu PENDING đã quá hạn, xử lý từng cái trong transaction riêng. */
    @Query("SELECT d.id FROM ReportDelegation d WHERE d.status = :status AND d.expiresAt < :now")
    List<String> findIdsByStatusAndExpiresAtBefore(
            @Param("status") EDelegationStatus status,
            @Param("now") LocalDateTime now,
            Pageable pageable);
}
