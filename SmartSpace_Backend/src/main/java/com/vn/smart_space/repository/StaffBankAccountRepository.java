package com.vn.smart_space.repository;

import com.vn.smart_space.model.StaffBankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StaffBankAccountRepository extends JpaRepository<StaffBankAccount, String> {

    List<StaffBankAccount> findByUserIdOrderByCreatedAtDesc(String userId);

    Optional<StaffBankAccount> findByUserIdAndBankAccountNumber(String userId, String bankAccountNumber);

    boolean existsByUserIdAndBankAccountNumber(String userId, String bankAccountNumber);
}

