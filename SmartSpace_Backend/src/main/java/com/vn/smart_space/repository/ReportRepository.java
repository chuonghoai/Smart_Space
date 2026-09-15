package com.vn.smart_space.repository;

import java.util.List;

import org.springframework.data.domain.Limit;
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

}
