package com.vn.smart_space.repository;

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

    // Search and Filter Staff
    @Query("SELECT u FROM User u WHERE u.role = :role " +
            "AND (:status IS NULL OR u.status = :status) " +
            "AND (:search IS NULL OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR LOWER(u.email) LIKE LOWER(CONCAT('%', :search, '%')) " +
            "OR u.phone LIKE CONCAT('%', :search, '%'))")
    Page<User> findStaffs(
            @Param("role") ERole role,
            @Param("status") EUserStatus status,
            @Param("search") String search,
            Pageable pageable);

    // Đếm theo role + status
    long countByRoleAndStatus(ERole role, EUserStatus status);

}
