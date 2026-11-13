package com.vn.smart_space.repository;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.model.Report;

import jakarta.persistence.LockModeType;

public interface ReportRepository extends JpaRepository<Report, String> {

       // Khoá dòng report khi đổi người được giao (nhờ làm giùm) để 2 yêu cầu song
       // song không cùng lọt qua kiểm tra
       @Lock(LockModeType.PESSIMISTIC_WRITE)
       @Query("SELECT r FROM Report r WHERE r.id = :id")
       Optional<Report> findByIdForUpdate(@Param("id") String id);

       @Query("SELECT r FROM Report r WHERE r.severity IN :severities ORDER BY r.createdAt DESC")
       List<Report> findTopBySeverityInOrderByCreatedAtDesc(@Param("severities") List<EReportSeverity> severities,
                     Limit limit);

       @Query("SELECT r FROM Report r ORDER BY r.createdAt DESC")
       List<Report> findTopByOrderByCreatedAtDesc(Limit limit);

       @Query(value = "SELECT * FROM reports r ORDER BY (6371000 * acos(cos(radians(:userLat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(:userLong)) + sin(radians(:userLat)) * sin(radians(r.latitude)))) ASC", nativeQuery = true)
       List<Report> findNearestReports(@Param("userLat") Double userLat, @Param("userLong") Double userLong,
                     Limit limit);

       @Query(value = "SELECT * FROM reports r WHERE r.status NOT IN ('REJECTED', 'PROCESSED') " +
                     "AND (6371000 * acos(least(1.0, greatest(-1.0, cos(radians(:userLat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(:userLong)) + sin(radians(:userLat)) * sin(radians(r.latitude)))))) <= :radius "
                     +
                     "ORDER BY (6371000 * acos(least(1.0, greatest(-1.0, cos(radians(:userLat)) * cos(radians(r.latitude)) * cos(radians(r.longitude) - radians(:userLong)) + sin(radians(:userLat)) * sin(radians(r.latitude)))))) ASC", nativeQuery = true)
       List<Report> findNearbyActiveReportsWithinRadius(@Param("userLat") Double userLat,
                     @Param("userLong") Double userLong,
                     @Param("radius") Double radius, Limit limit);

       @Query("SELECT r FROM Report r WHERE r.status IN :statuses ORDER BY r.createdAt DESC")
       List<Report> findByStatusInOrderByCreatedAtDesc(
                     @Param("statuses") List<EReportStatus> statuses,
                     org.springframework.data.domain.Pageable pageable);

       long countByStatusIn(List<EReportStatus> statuses);

       long countByStatus(EReportStatus status);

       String CLIENT_KEYWORD_FILTER = "AND (:search IS NULL OR " +
                     "     LOWER(r.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                     "     LOWER(r.description) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                     "     LOWER(r.address) LIKE LOWER(CONCAT('%', :search, '%'))) ";

       // Khoảng ngày tạo Client: [createdFrom, createdTo) — createdTo là đầu ngày sau ngày cuối
       // người dùng chọn, nên trọn ngày cuối được tính. null = không giới hạn đầu/cuối đó.
       String CLIENT_DATE_FILTER = "AND (:createdFrom IS NULL OR r.createdAt >= :createdFrom) " +
                     "AND (:createdTo IS NULL OR r.createdAt < :createdTo) ";

       String MY_REPORTS_FILTER = "WHERE r.user.id = :userId " +
                     "AND (:status IS NULL OR r.status = :status) " +
                     "AND (:severity IS NULL OR r.severity = :severity) " +
                     "AND (:rehandling = false OR r.isReviewResolved = false) " +
                     CLIENT_DATE_FILTER +
                     CLIENT_KEYWORD_FILTER;

       // Client "My reports": newest first, optional status / severity / re-handling /
       // keyword.
       @Query(value = "SELECT r FROM Report r " + MY_REPORTS_FILTER
                     + "ORDER BY r.createdAt DESC, r.id DESC", countQuery = "SELECT COUNT(r) FROM Report r "
                                   + MY_REPORTS_FILTER)
       Page<Report> findMyReports(
                     @Param("userId") String userId,
                     @Param("status") EReportStatus status,
                     @Param("severity") EReportSeverity severity,
                     @Param("rehandling") boolean rehandling,
                     @Param("search") String search,
                     @Param("createdFrom") LocalDateTime createdFrom,
                     @Param("createdTo") LocalDateTime createdTo,
                     Pageable pageable);

       // Client "My reports" summary card: [status, count] over all of the owner's
       // reports
       @Query("SELECT r.status, COUNT(r) FROM Report r WHERE r.user.id = :userId GROUP BY r.status")
       List<Object[]> countMyReportsGroupByStatus(@Param("userId") String userId);

       long countByUserIdAndIsReviewResolvedFalse(String userId);

       // Count Report Processing For Staff
       @Query("SELECT r.assignedStaff.id, COUNT(r) FROM Report r " +
                     "WHERE r.assignedStaff.id IN :staffIds AND r.status = :status " +
                     "GROUP BY r.assignedStaff.id")
       List<Object[]> countByAssignedStaffIdInAndStatus(
                     @Param("staffIds") List<String> staffIds,
                     @Param("status") EReportStatus status);

       // Dashboard: group by status
       @Query("SELECT r.status, COUNT(r) FROM Report r GROUP BY r.status")
       List<Object[]> countGroupByStatus();

       // Staff Dashboard: find assigned reports
       List<Report> findByAssignedStaffIdOrderByCreatedAtDesc(String staffId, Limit limit);

       List<Report> findByAssignedStaffIdAndStatusOrderByCreatedAtDesc(String staffId, EReportStatus status,
                     Limit limit);

       // Fetch user + assignedStaff (to-one) cùng lúc để tránh N+1 khi map sang
       // RecentReportResponse
       @EntityGraph(attributePaths = { "user", "assignedStaff" })
       List<Report> findByAssignedStaffIdAndStatusInOrderByCreatedAtDesc(String staffId, List<EReportStatus> statuses,
                     Pageable pageable);

       // Staff Dashboard: group by status for staff
       @Query("SELECT r.status, COUNT(r) FROM Report r WHERE r.assignedStaff.id = :staffId GROUP BY r.status")
       List<Object[]> countStaffReportsGroupByStatus(@Param("staffId") String staffId);

       long countByStatusAndIsReviewResolved(EReportStatus status, Boolean isReviewResolved);

       @Query("SELECT COUNT(r) FROM Report r WHERE r.assignedStaff.id = :staffId AND r.status = :status AND r.isReviewResolved = :isReviewResolved")
       long countStaffReportsByStatusAndIsReviewResolved(@Param("staffId") String staffId,
                     @Param("status") EReportStatus status, @Param("isReviewResolved") Boolean isReviewResolved);

       @Query("SELECT r FROM Report r WHERE r.status = :status AND r.isReviewResolved = :isReviewResolved ORDER BY r.updatedAt DESC")
       List<Report> findReportsByStatusAndIsReviewResolved(@Param("status") EReportStatus status,
                     @Param("isReviewResolved") Boolean isReviewResolved);

       @EntityGraph(attributePaths = { "user", "assignedStaff" })
       @Query("SELECT r FROM Report r WHERE r.assignedStaff.id = :staffId AND r.status = :status AND r.isReviewResolved = :isReviewResolved ORDER BY r.updatedAt DESC")
       List<Report> findStaffReportsByStatusAndIsReviewResolved(@Param("staffId") String staffId,
                     @Param("status") EReportStatus status, @Param("isReviewResolved") Boolean isReviewResolved,
                     Pageable pageable);

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
                     "AND (:isRehandling IS NULL OR (:isRehandling = true AND r.isReviewResolved = false)) " +
                     "AND (:severity IS NULL OR r.severity = :severity) " +
                     "AND (:assigneeId IS NULL OR r.assignedStaff.id = :assigneeId) " +
                     "AND (:from IS NULL OR r.createdAt >= :from) " +
                     "AND (:to IS NULL OR r.createdAt <= :to) " +
                     "AND (:search IS NULL OR " +
                     "     LOWER(r.id) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                     "     LOWER(r.title) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
                     "     (r.isAnonymous = false AND u IS NOT NULL AND LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%'))) OR "
                     +
                     "     (r.isAnonymous = false AND u IS NOT NULL AND LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')))) "
                     +
                     "ORDER BY r.createdAt DESC")
       Page<Report> findAllFiltered(
                     @Param("status") EReportStatus status,
                     @Param("isRehandling") Boolean isRehandling,
                     @Param("severity") EReportSeverity severity,
                     @Param("assigneeId") String assigneeId,
                     @Param("from") LocalDateTime from,
                     @Param("to") LocalDateTime to,
                     @Param("search") String search,
                     Pageable pageable);

       // Admin - User management
       // Thống kê tổng hợp (aggregate) tính cả báo cáo ẩn danh; số liệu gắn với từng
       // người dùng thì loại báo cáo ẩn danh để không lộ danh tính người báo cáo.

       @Query("SELECT COUNT(DISTINCT r.user.id) FROM Report r " +
                     "WHERE r.user.role = :role AND r.createdAt >= :from")
       long countDistinctReportersSince(
                     @Param("role") ERole role,
                     @Param("from") LocalDateTime from);

       @Query("SELECT COUNT(r) FROM Report r " +
                     "WHERE r.user.role = :role AND r.createdAt >= :from AND r.createdAt < :to")
       long countByReporterRoleBetween(
                     @Param("role") ERole role,
                     @Param("from") LocalDateTime from,
                     @Param("to") LocalDateTime to);

       @Query("SELECT r.user.id, COUNT(r) FROM Report r " +
                     "WHERE r.user.id IN :userIds AND (r.isAnonymous IS NULL OR r.isAnonymous = false) " +
                     "GROUP BY r.user.id")
       List<Object[]> countPublicReportsByUserIdIn(@Param("userIds") List<String> userIds);

       @Query("SELECT u.id, u.fullName, u.avatarUrl, COUNT(r) FROM Report r JOIN r.user u " +
                     "WHERE u.role = :role AND (r.isAnonymous IS NULL OR r.isAnonymous = false) " +
                     "GROUP BY u.id, u.fullName, u.avatarUrl " +
                     "ORDER BY COUNT(r) DESC")
       List<Object[]> findTopPublicReporters(@Param("role") ERole role, Limit limit);

       @Query("SELECT r.status, COUNT(r) FROM Report r " +
                     "WHERE r.user.id = :userId AND (r.isAnonymous IS NULL OR r.isAnonymous = false) " +
                     "GROUP BY r.status")
       List<Object[]> countPublicReportsByUserGroupByStatus(@Param("userId") String userId);

       @Query("SELECT r FROM Report r " +
                     "WHERE r.user.id = :userId AND (r.isAnonymous IS NULL OR r.isAnonymous = false) " +
                     "ORDER BY r.createdAt DESC")
       List<Report> findRecentPublicReportsByUser(@Param("userId") String userId, Limit limit);

       // Admin - Staff dashboard
       // "Đã xử lý" = status processed + có nhân viên phụ trách. Thời điểm xử lý lấy
       // theo
       // updatedAt: processed là trạng thái cuối (updateReportStatus không cho chuyển
       // tiếp)
       // nên updatedAt không đổi sau khi xử lý xong.

       @Query("SELECT COUNT(r) FROM Report r " +
                     "WHERE r.status = :status AND r.assignedStaff IS NOT NULL " +
                     "AND r.updatedAt >= :from AND r.updatedAt < :to")
       long countAssignedByStatusUpdatedBetween(
                     @Param("status") EReportStatus status,
                     @Param("from") LocalDateTime from,
                     @Param("to") LocalDateTime to);

       // [assignedAt, updatedAt] để tính thời gian xử lý trung bình
       @Query("SELECT r.assignedAt, r.updatedAt FROM Report r " +
                     "WHERE r.status = :status AND r.assignedStaff IS NOT NULL AND r.assignedAt IS NOT NULL " +
                     "AND r.updatedAt >= :from AND r.updatedAt < :to")
       List<Object[]> findAssignedAndUpdatedAtByStatusBetween(
                     @Param("status") EReportStatus status,
                     @Param("from") LocalDateTime from,
                     @Param("to") LocalDateTime to);

       @Query("SELECT r.assignedAt FROM Report r WHERE r.assignedAt >= :from")
       List<Date> findAssignedAtSince(@Param("from") Date from);

       @Query("SELECT r.updatedAt FROM Report r " +
                     "WHERE r.status = :status AND r.assignedStaff IS NOT NULL AND r.updatedAt >= :from")
       List<LocalDateTime> findAssignedUpdatedAtByStatusSince(
                     @Param("status") EReportStatus status,
                     @Param("from") LocalDateTime from);

       // [staffId, count] — nhân viên có nhiều báo cáo ở :status nhất
       @Query("SELECT r.assignedStaff.id, COUNT(r) FROM Report r " +
                     "WHERE r.status = :status AND r.assignedStaff IS NOT NULL " +
                     "GROUP BY r.assignedStaff.id ORDER BY COUNT(r) DESC")
       List<Object[]> findTopAssigneesByStatus(@Param("status") EReportStatus status, Limit limit);

       // [staffId, count] — số báo cáo ở :status của từng nhân viên, cập nhật từ :from
       @Query("SELECT r.assignedStaff.id, COUNT(r) FROM Report r " +
                     "WHERE r.assignedStaff.id IN :staffIds AND r.status = :status AND r.updatedAt >= :from " +
                     "GROUP BY r.assignedStaff.id")
       List<Object[]> countByAssignedStaffIdInAndStatusUpdatedSince(
                     @Param("staffIds") List<String> staffIds,
                     @Param("status") EReportStatus status,
                     @Param("from") LocalDateTime from);

       // Client community feed: excluding one status (rejected), optional status /
       // severity / keyword.
       String FEED_FILTER = "WHERE r.status <> :excluded " +
                     "AND (:status IS NULL OR r.status = :status) " +
                     "AND (:severity IS NULL OR r.severity = :severity) " +
                     CLIENT_DATE_FILTER +
                     CLIENT_KEYWORD_FILTER;

       String FEED_NEARBY_FILTER = FEED_FILTER + "AND r.latitude IS NOT NULL AND r.longitude IS NOT NULL ";

       // Newest first
       @Query(value = "SELECT r FROM Report r LEFT JOIN FETCH r.user LEFT JOIN FETCH r.assignedStaff " +
                     FEED_FILTER + "ORDER BY r.createdAt DESC, r.id DESC", countQuery = "SELECT COUNT(r) FROM Report r "
                                   + FEED_FILTER)
       Page<Report> findFeed(
                     @Param("excluded") EReportStatus excluded,
                     @Param("status") EReportStatus status,
                     @Param("severity") EReportSeverity severity,
                     @Param("search") String search,
                     @Param("createdFrom") LocalDateTime createdFrom,
                     @Param("createdTo") LocalDateTime createdTo,
                     Pageable pageable);

       // Nearest first ("Gần tôi"), sorted in the DB so paging stays correct. Order
       // key is the
       // equirectangular approximation (Δlat)² + (Δlng)²·cos²(lat) — same ranking as
       // haversine at city
       // scale, plain arithmetic so it stays JPQL (keeps JOIN FETCH, no N+1).
       // :lngScale = cos²(:lat),
       // computed by the caller. Reports without coordinates are excluded.
       @Query(value = "SELECT r FROM Report r LEFT JOIN FETCH r.user LEFT JOIN FETCH r.assignedStaff " +
                     FEED_NEARBY_FILTER +
                     "ORDER BY ((r.latitude - :lat) * (r.latitude - :lat) " +
                     "+ (r.longitude - :lng) * (r.longitude - :lng) * :lngScale) ASC, " +
                     "r.createdAt DESC, r.id DESC", countQuery = "SELECT COUNT(r) FROM Report r " + FEED_NEARBY_FILTER)
       Page<Report> findFeedNearby(
                     @Param("excluded") EReportStatus excluded,
                     @Param("status") EReportStatus status,
                     @Param("severity") EReportSeverity severity,
                     @Param("search") String search,
                     @Param("createdFrom") LocalDateTime createdFrom,
                     @Param("createdTo") LocalDateTime createdTo,
                     @Param("lat") Double lat,
                     @Param("lng") Double lng,
                     @Param("lngScale") Double lngScale,
                     Pageable pageable);

       // Admin map: same filters as the report list, optional lat/lng box (all bounds
       // null = whole map),
       // most severe first then newest. Reports without coordinates are excluded
       // before the limit.
       @Query("SELECT r FROM Report r " +
                     "WHERE r.latitude IS NOT NULL AND r.longitude IS NOT NULL " +
                     "AND (:status IS NULL OR r.status = :status) " +
                     "AND (:severity IS NULL OR r.severity = :severity) " +
                     "AND (:assigneeId IS NULL OR r.assignedStaff.id = :assigneeId) " +
                     "AND (:from IS NULL OR r.createdAt >= :from) " +
                     "AND (:to IS NULL OR r.createdAt <= :to) " +
                     "AND (:minLat IS NULL OR r.latitude BETWEEN :minLat AND :maxLat) " +
                     "AND (:minLng IS NULL OR r.longitude BETWEEN :minLng AND :maxLng) " +
                     "ORDER BY CASE r.severity " +
                     "WHEN com.vn.smart_space.consts.EReportSeverity.critical THEN 0 " +
                     "WHEN com.vn.smart_space.consts.EReportSeverity.high THEN 1 " +
                     "ELSE 2 END, r.createdAt DESC")
       List<Report> findAdminMapReports(
                     @Param("status") EReportStatus status,
                     @Param("severity") EReportSeverity severity,
                     @Param("assigneeId") String assigneeId,
                     @Param("from") LocalDateTime from,
                     @Param("to") LocalDateTime to,
                     @Param("minLat") Double minLat,
                     @Param("maxLat") Double maxLat,
                     @Param("minLng") Double minLng,
                     @Param("maxLng") Double maxLng,
                     Limit limit);

       // Client map viewport: reports inside a lat/lng box, most severe first then
       // newest.
       // Processed reports are only visible to their owner (viewerId) and only while
       // updatedAt >= processedSince.
       // status / ownerId null = no restriction.
       @Query("SELECT r FROM Report r " +
                     "WHERE r.latitude BETWEEN :minLat AND :maxLat " +
                     "AND r.longitude BETWEEN :minLng AND :maxLng " +
                     "AND r.status <> :excluded " +
                     "AND (r.status <> :processed OR (r.user.id = :viewerId AND r.updatedAt >= :processedSince)) " +
                     "AND (:status IS NULL OR r.status = :status) " +
                     "AND (:ownerId IS NULL OR r.user.id = :ownerId) " +
                     "AND (:createdAfter IS NULL OR r.createdAt >= :createdAfter) " +
                     "ORDER BY CASE r.severity " +
                     "WHEN com.vn.smart_space.consts.EReportSeverity.critical THEN 0 " +
                     "WHEN com.vn.smart_space.consts.EReportSeverity.high THEN 1 " +
                     "ELSE 2 END, r.createdAt DESC")
       List<Report> findInBounds(
                     @Param("minLat") Double minLat,
                     @Param("maxLat") Double maxLat,
                     @Param("minLng") Double minLng,
                     @Param("maxLng") Double maxLng,
                     @Param("excluded") EReportStatus excluded,
                     @Param("processed") EReportStatus processed,
                     @Param("processedSince") LocalDateTime processedSince,
                     @Param("createdAfter") LocalDateTime createdAfter,
                     @Param("viewerId") String viewerId,
                     @Param("status") EReportStatus status,
                     @Param("ownerId") String ownerId,
                     Limit limit);

       @Query("SELECT r.id, r.latitude, r.longitude, r.createdAt FROM Report r " +
                     "WHERE r.latitude IS NOT NULL AND r.longitude IS NOT NULL " +
                     "AND r.status <> :excluded")
       List<Object[]> findValidCoordinatesForDensity(@Param("excluded") EReportStatus excluded);

       @Query("SELECT r.id, r.latitude, r.longitude, r.createdAt FROM Report r " +
                     "WHERE r.latitude BETWEEN :minLat AND :maxLat " +
                     "AND r.longitude BETWEEN :minLng AND :maxLng " +
                     "AND r.status <> :excluded")
       List<Object[]> findValidCoordinatesInBounds(
                     @Param("minLat") Double minLat,
                     @Param("maxLat") Double maxLat,
                     @Param("minLng") Double minLng,
                     @Param("maxLng") Double maxLng,
                     @Param("excluded") EReportStatus excluded);

       List<Report> findByConversationIdAndStatusOrderByCreatedAtDesc(String conversationId, EReportStatus status);

       List<Report> findByConversationIdOrderByCreatedAtDesc(String conversationId);

       boolean existsByConversationIdAndStatus(String conversationId, EReportStatus status);

       boolean existsByConversationId(String conversationId);

       @Query("SELECT r FROM Report r WHERE r.conversation.id = :conversationId AND (r.status = com.vn.smart_space.consts.EReportStatus.processing OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) ORDER BY r.createdAt DESC")
       Page<Report> findActiveReportsByConversationId(
                     @Param("conversationId") String conversationId, Pageable pageable);

       @Query("SELECT r FROM Report r WHERE r.conversation.id = :conversationId AND (r.status = com.vn.smart_space.consts.EReportStatus.processing OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) ORDER BY r.createdAt DESC")
       List<Report> findActiveReportsByConversationId(@Param("conversationId") String conversationId);

       @Query("SELECT COUNT(r) FROM Report r WHERE r.conversation.id = :conversationId AND (r.status = com.vn.smart_space.consts.EReportStatus.processing OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false))")
       long countActiveReportsByConversationId(@Param("conversationId") String conversationId);

       @Query("SELECT r FROM Report r WHERE r.user.id = :clientId AND r.assignedStaff.id = :staffId " +
                     "AND (r.status = com.vn.smart_space.consts.EReportStatus.processing " +
                     "     OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) "
                     +
                     "ORDER BY r.createdAt DESC")
       List<Report> findActiveReportsByClientAndStaff(@Param("clientId") String clientId,
                     @Param("staffId") String staffId);

       @Query("SELECT r FROM Report r WHERE r.user.id = :clientId AND r.assignedStaff.id = :staffId " +
                     "AND (r.status = com.vn.smart_space.consts.EReportStatus.processing " +
                     "     OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) "
                     +
                     "ORDER BY r.createdAt DESC")
       org.springframework.data.domain.Page<Report> findActiveReportsByClientAndStaff(
                     @Param("clientId") String clientId,
                     @Param("staffId") String staffId,
                     org.springframework.data.domain.Pageable pageable);

       boolean existsByUserIdAndAssignedStaffIdAndIsAnonymous(String userId, String staffId, Boolean isAnonymous);

       @Query("SELECT r FROM Report r WHERE r.user.id = :clientId AND r.assignedStaff.id = :staffId " +
                     "AND (:isAnonymous IS NULL OR r.isAnonymous = :isAnonymous) " +
                     "AND (r.status = com.vn.smart_space.consts.EReportStatus.processing " +
                     "     OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) "
                     +
                     "ORDER BY r.createdAt DESC")
       List<Report> findActiveReportsByClientAndStaffAndAnonymous(
                     @Param("clientId") String clientId,
                     @Param("staffId") String staffId,
                     @Param("isAnonymous") Boolean isAnonymous);

       @Query("SELECT r FROM Report r WHERE r.user.id = :clientId AND r.assignedStaff.id = :staffId " +
                     "AND (:isAnonymous IS NULL OR r.isAnonymous = :isAnonymous) " +
                     "AND (r.status = com.vn.smart_space.consts.EReportStatus.processing " +
                     "     OR (r.status = com.vn.smart_space.consts.EReportStatus.processed AND r.isReviewResolved = false)) "
                     +
                     "ORDER BY r.createdAt DESC")
       org.springframework.data.domain.Page<Report> findActiveReportsByClientAndStaffAndAnonymous(
                     @Param("clientId") String clientId,
                     @Param("staffId") String staffId,
                     @Param("isAnonymous") Boolean isAnonymous,
                     org.springframework.data.domain.Pageable pageable);

}