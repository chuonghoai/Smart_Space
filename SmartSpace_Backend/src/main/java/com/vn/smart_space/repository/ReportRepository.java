package com.vn.smart_space.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.model.Report;

public interface ReportRepository extends JpaRepository<Report, String> {

        @Query("SELECT r FROM Report r WHERE r.severity IN :severities ORDER BY r.createdAt DESC")
        List<Report> findTopBySeverityInOrderByCreatedAtDesc(@Param("severities") List<EReportSeverity> severities,
                        Limit limit);

        @Query("SELECT r FROM Report r ORDER BY r.createdAt DESC")
        List<Report> findTopByOrderByCreatedAtDesc(Limit limit);

        @Query(value = "SELECT * FROM reports r ORDER BY (6371000 * acos(cos(radians(:userLat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(:userLong)) + sin(radians(:userLat)) * sin(radians(r.latitude)))) ASC", nativeQuery = true)
        List<Report> findNearestReports(@Param("userLat") Double userLat, @Param("userLong") Double userLong,
                        Limit limit);

        @Query("SELECT r FROM Report r WHERE r.status IN :statuses ORDER BY r.createdAt DESC")
        List<Report> findByStatusInOrderByCreatedAtDesc(
                        @Param("statuses") List<EReportStatus> statuses,
                        org.springframework.data.domain.Pageable pageable);

        long countByStatusIn(List<EReportStatus> statuses);

        long countByStatus(EReportStatus status);

        // Get My Reports For Client
        @Query("SELECT r FROM Report r WHERE r.user.id = :userId AND (:status IS NULL OR r.status = :status) ORDER BY r.createdAt DESC")
        List<Report> findMyReports(@Param("userId") String userId, @Param("status") EReportStatus status, Limit limit);

        // Count Report Processing For Staff
        @Query("SELECT r.assignedStaff.id, COUNT(r) FROM Report r " +
                        "WHERE r.assignedStaff.id IN :staffIds AND r.status = :status " +
                        "GROUP BY r.assignedStaff.id")
        List<Object[]> countByAssignedStaffIdInAndStatus(
                        @Param("staffIds") List<String> staffIds,
                        @Param("status") EReportStatus status);

        // Find Top N Staff with most processing reports

        @Query("SELECT r.assignedStaff.id, r.assignedStaff.fullName, COUNT(r) " +
                        "FROM Report r " +
                        "WHERE r.status = :status AND r.assignedStaff IS NOT NULL " +
                        "GROUP BY r.assignedStaff.id, r.assignedStaff.fullName " +
                        "ORDER BY COUNT(r) DESC")
        List<Object[]> findTopStaffByProcessingCount(@Param("status") EReportStatus status, Limit limit);

        // Dashboard: group by status
        @Query("SELECT r.status, COUNT(r) FROM Report r GROUP BY r.status")
        List<Object[]> countGroupByStatus();

        // Dashboard: group by severity (exclude null)
        @Query("SELECT r.severity, COUNT(r) FROM Report r WHERE r.severity IS NOT NULL GROUP BY r.severity")
        List<Object[]> countGroupBySeverity();

        // Dashboard trend: daily (last 7 days)
        @Query(value = "SELECT DATE_FORMAT(created_at, '%d/%m') AS label, COUNT(*) AS cnt " +
                        "FROM reports " +
                        "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) " +
                        "GROUP BY DATE(created_at), label " +
                        "ORDER BY DATE(created_at) ASC", nativeQuery = true)
        List<Object[]> countDailyTrend();

        // Dashboard trend: weekly (last 8 weeks)
        @Query(value = "SELECT CONCAT('Tuần ', WEEK(created_at)) AS label, COUNT(*) AS cnt " +
                        "FROM reports " +
                        "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 8 WEEK) " +
                        "GROUP BY YEARWEEK(created_at), label " +
                        "ORDER BY YEARWEEK(created_at) ASC", nativeQuery = true)
        List<Object[]> countWeeklyTrend();

        // Dashboard trend: monthly (last 6 months)
        @Query(value = "SELECT DATE_FORMAT(created_at, '%m/%Y') AS label, COUNT(*) AS cnt " +
                        "FROM reports " +
                        "WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
                        "GROUP BY YEAR(created_at), MONTH(created_at), label " +
                        "ORDER BY YEAR(created_at) ASC, MONTH(created_at) ASC", nativeQuery = true)
        List<Object[]> countMonthlyTrend();

        // Report list: multi-filter + pageable
        @Query("SELECT r FROM Report r LEFT JOIN r.user u " +
                        "WHERE (:status IS NULL OR r.status = :status) " +
                        "AND (:severity IS NULL OR r.severity = :severity) " +
                        "AND (:assigneeId IS NULL OR r.assignedStaff.id = :assigneeId) " +
                        "AND (:from IS NULL OR r.createdAt >= :from) " +
                        "AND (:to IS NULL OR r.createdAt <= :to) " +
                        "AND (:search IS NULL OR " +
                        "     LOWER(r.id) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                        "     LOWER(r.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                        "     (r.isAnonymous = false AND u IS NOT NULL AND LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%'))) OR " +
                        "     (r.isAnonymous = false AND u IS NOT NULL AND LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')))) " +
                        "ORDER BY r.createdAt DESC")
        Page<Report> findAllFiltered(
                        @Param("status") EReportStatus status,
                        @Param("severity") EReportSeverity severity,
                        @Param("assigneeId") String assigneeId,
                        @Param("from") LocalDateTime from,
                        @Param("to") LocalDateTime to,
                        @Param("search") String search,
                        Pageable pageable);

}
