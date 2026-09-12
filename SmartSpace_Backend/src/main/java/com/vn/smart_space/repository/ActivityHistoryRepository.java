package com.vn.smart_space.repository;

import com.vn.smart_space.model.ActivityHistory;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityHistoryRepository extends JpaRepository<ActivityHistory, String> {

    @Query("SELECT a FROM ActivityHistory a ORDER BY a.createdAt DESC")
    List<ActivityHistory> findRecentActivities(Pageable pageable);
}
