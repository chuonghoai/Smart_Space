package com.vn.smart_space.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.model.User;

@Repository
public interface UserRepository extends JpaRepository<User, String> {

    Optional<User> findById(String id);

    boolean existsByEmailAndRole(String email, ERole role);

    Optional<User> findByEmailAndRole(String email, ERole role);

    long countByRole(ERole role);

    List<User> findByRole(ERole role);

    List<User> findByRoleIn(java.util.Collection<ERole> roles);

    // Search and Filter Staff
    @Query(value = "SELECT u FROM User u LEFT JOIN FETCH u.position WHERE u.role = :role " +
            "AND (:status IS NULL OR u.status = :status) " +
            "AND (:positionId IS NULL OR u.position.id = :positionId) " +
            "AND (:search IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR u.phone LIKE CONCAT('%', :search, '%'))",
            countQuery = "SELECT COUNT(u) FROM User u WHERE u.role = :role " +
                    "AND (:status IS NULL OR u.status = :status) " +
                    "AND (:positionId IS NULL OR u.position.id = :positionId) " +
                    "AND (:search IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%')) " +
                    "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')) " +
                    "OR u.phone LIKE CONCAT('%', :search, '%'))")
    Page<User> findStaffs(
            @Param("role") ERole role,
            @Param("status") EUserStatus status,
            @Param("positionId") String positionId,
            @Param("search") String search,
            Pageable pageable);

    // Đếm theo role + status
    long countByRoleAndStatus(ERole role, EUserStatus status);

    // Đếm số nhân viên đang giữ một chức vụ
    long countByPositionId(String positionId);

    // Đếm nhân viên theo từng chức vụ: [positionId, count]
    @Query("SELECT u.position.id, COUNT(u) FROM User u " +
            "WHERE u.role = :role AND u.position IS NOT NULL GROUP BY u.position.id")
    List<Object[]> countStaffGroupByPosition(@Param("role") ERole role);

    // Admin - User management: tìm kiếm theo role, sắp xếp lấy từ Pageable
    @Query(value = "SELECT u FROM User u WHERE u.role = :role " +
            "AND (:search IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR u.phone LIKE CONCAT('%', :search, '%'))",
            countQuery = "SELECT COUNT(u) FROM User u WHERE u.role = :role " +
                    "AND (:search IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%')) " +
                    "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')) " +
                    "OR u.phone LIKE CONCAT('%', :search, '%'))")
    Page<User> searchByRole(
            @Param("role") ERole role,
            @Param("search") String search,
            Pageable pageable);

    Optional<User> findByIdAndRole(String id, ERole role);

    // Đếm user đăng ký trong khoảng [from, to)
    long countByRoleAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
            ERole role, LocalDateTime from, LocalDateTime to);

    // Lấy thời điểm đăng ký từ :from để gom nhóm trend
    @Query("SELECT u.createdAt FROM User u WHERE u.role = :role AND u.createdAt >= :from")
    List<LocalDateTime> findCreatedAtByRoleSince(
            @Param("role") ERole role,
            @Param("from") LocalDateTime from);

}
