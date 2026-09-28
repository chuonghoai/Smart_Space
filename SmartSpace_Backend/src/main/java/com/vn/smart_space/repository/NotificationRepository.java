package com.vn.smart_space.repository;

import com.vn.smart_space.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, String> {

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.user.id = :userId AND n.isRead = false")
    long countUnreadPersonalNotifications(@Param("userId") String userId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.user IS NULL")
    long countTotalBroadcastNotifications();

    @Query("SELECT n FROM Notification n WHERE n.user.id = :userId OR n.user IS NULL ORDER BY n.createdAt DESC")
    org.springframework.data.domain.Page<Notification> findByUserIdOrUserIsNullOrderByCreatedAtDesc(@Param("userId") String userId, org.springframework.data.domain.Pageable pageable);

    java.util.List<Notification> findByUserIdAndIsReadFalse(String userId);
}
