package com.vn.smart_space.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.SosLocationPoint;

@Repository
public interface SosLocationPointRepository extends JpaRepository<SosLocationPoint, String> {

    /** Tối đa 200 điểm gần nhất (~50 phút ở nhịp 15 giây). */
    List<SosLocationPoint> findTop200BySosAlertIdOrderByRecordedAtDesc(String sosAlertId);
}
