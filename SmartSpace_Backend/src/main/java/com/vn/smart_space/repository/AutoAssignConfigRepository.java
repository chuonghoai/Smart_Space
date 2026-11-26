package com.vn.smart_space.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import com.vn.smart_space.model.AutoAssignConfig;

import jakarta.persistence.LockModeType;

public interface AutoAssignConfigRepository extends JpaRepository<AutoAssignConfig, String> {

    Optional<AutoAssignConfig> findTopByOrderByUpdatedAtDesc();

    /**
     * Đọc cấu hình hiện hành kèm khoá ghi (SELECT ... FOR UPDATE). Dùng làm khoá phân công
     * tuần tự: khoá được giữ tới khi transaction commit/rollback nên bao trọn cả bước chấm
     * điểm lẫn bước lưu người được giao.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM AutoAssignConfig c ORDER BY c.updatedAt DESC")
    List<AutoAssignConfig> findLatestForUpdate(Pageable pageable);
}
