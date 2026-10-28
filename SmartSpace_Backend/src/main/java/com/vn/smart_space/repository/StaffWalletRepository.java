package com.vn.smart_space.repository;

import com.vn.smart_space.model.StaffWallet;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StaffWalletRepository extends JpaRepository<StaffWallet, String> {

    Optional<StaffWallet> findByUserId(String userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM StaffWallet w WHERE w.user.id = :userId")
    Optional<StaffWallet> findByUserIdForUpdate(@Param("userId") String userId);
}

