package com.vn.smart_space.repository;

import com.vn.smart_space.consts.EWithdrawalStatus;
import com.vn.smart_space.model.StaffWithdrawalRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StaffWithdrawalRequestRepository extends JpaRepository<StaffWithdrawalRequest, String> {

    long countByStatus(EWithdrawalStatus status);

    Page<StaffWithdrawalRequest> findByStatusOrderByCreatedAtDesc(EWithdrawalStatus status, Pageable pageable);

    Page<StaffWithdrawalRequest> findAllByOrderByCreatedAtDesc(Pageable pageable);

    List<StaffWithdrawalRequest> findByUserIdOrderByCreatedAtDesc(String userId);
}

