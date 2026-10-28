package com.vn.smart_space.repository;

import com.vn.smart_space.model.WalletConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface WalletConfigRepository extends JpaRepository<WalletConfig, String> {
}

