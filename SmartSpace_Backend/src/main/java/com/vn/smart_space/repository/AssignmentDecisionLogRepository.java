package com.vn.smart_space.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.vn.smart_space.model.AssignmentDecisionLog;

public interface AssignmentDecisionLogRepository extends JpaRepository<AssignmentDecisionLog, String> {

    Optional<AssignmentDecisionLog> findTopByReportIdOrderByCreatedAtDesc(String reportId);

    List<AssignmentDecisionLog> findByReportIdOrderByCreatedAtDesc(String reportId);
}
