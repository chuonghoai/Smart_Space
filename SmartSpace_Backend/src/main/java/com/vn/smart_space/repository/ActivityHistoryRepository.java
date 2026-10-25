package com.vn.smart_space.repository;

import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.consts.ERole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityHistoryRepository extends JpaRepository<ActivityHistory, String> {

    @Query("SELECT a FROM ActivityHistory a ORDER BY a.createdAt DESC")
    List<ActivityHistory> findRecentActivities(Pageable pageable);

    @Query(value = "SELECT a FROM ActivityHistory a " +
            "WHERE (:role IS NULL OR a.actor.role = :role) " +
            "AND (:topicPrefix IS NULL OR a.i18nKey LIKE CONCAT(:topicPrefix, '%')) " +
            "ORDER BY a.createdAt DESC",
            countQuery = "SELECT count(a) FROM ActivityHistory a " +
            "WHERE (:role IS NULL OR a.actor.role = :role) " +
            "AND (:topicPrefix IS NULL OR a.i18nKey LIKE CONCAT(:topicPrefix, '%'))")
    Page<ActivityHistory> findActivitiesWithFilter(
            @Param("role") ERole role,
            @Param("topicPrefix") String topicPrefix,
            Pageable pageable
    );
}

