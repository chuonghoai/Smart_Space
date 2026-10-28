package com.vn.smart_space.repository;

import com.vn.smart_space.model.StaffWalletTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface StaffWalletTransactionRepository extends JpaRepository<StaffWalletTransaction, String> {

    @Query("SELECT t FROM StaffWalletTransaction t WHERE t.wallet.id = :walletId ORDER BY t.createdAt DESC")
    Page<StaffWalletTransaction> findByWalletIdOrderByCreatedAtDesc(@Param("walletId") String walletId, Pageable pageable);

    @Query("SELECT t FROM StaffWalletTransaction t WHERE t.wallet.id = :walletId ORDER BY t.createdAt DESC")
    List<StaffWalletTransaction> findTop10ByWalletIdOrderByCreatedAtDesc(@Param("walletId") String walletId);

    @Query("SELECT t FROM StaffWalletTransaction t WHERE t.report.id = :reportId AND t.type = :type ORDER BY t.createdAt ASC")
    List<StaffWalletTransaction> findByReportIdAndType(@Param("reportId") String reportId, @Param("type") com.vn.smart_space.consts.EWalletTransactionType type);
}

