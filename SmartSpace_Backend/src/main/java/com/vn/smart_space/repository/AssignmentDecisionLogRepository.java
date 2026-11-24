package com.vn.smart_space.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.model.AssignmentDecisionLog;

public interface AssignmentDecisionLogRepository extends JpaRepository<AssignmentDecisionLog, String> {

    Optional<AssignmentDecisionLog> findTopByReportIdOrderByCreatedAtDesc(String reportId);

    List<AssignmentDecisionLog> findByReportIdOrderByCreatedAtDesc(String reportId);

    @Query(value = """
            SELECT l FROM AssignmentDecisionLog l
            LEFT JOIN FETCH l.report
            LEFT JOIN FETCH l.selectedStaff s
            LEFT JOIN FETCH s.position
            WHERE (:outcome IS NULL OR l.outcome = :outcome)
              AND (:source IS NULL OR l.source = :source)
              AND (:categoryId IS NULL OR l.categoryId = :categoryId)
            ORDER BY l.createdAt DESC
            """,
            countQuery = """
            SELECT COUNT(l) FROM AssignmentDecisionLog l
            WHERE (:outcome IS NULL OR l.outcome = :outcome)
              AND (:source IS NULL OR l.source = :source)
              AND (:categoryId IS NULL OR l.categoryId = :categoryId)
            """)
    Page<AssignmentDecisionLog> findLogsFiltered(
            @Param("outcome") EAssignmentOutcome outcome,
            @Param("source") EAssignmentSource source,
            @Param("categoryId") String categoryId,
            Pageable pageable);

    long countByOutcome(EAssignmentOutcome outcome);

    long countBySourceAndOutcome(EAssignmentSource source, EAssignmentOutcome outcome);
}
