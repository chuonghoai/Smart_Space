package com.vn.smart_space.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.model.User;

@Repository
public interface UserRepository extends JpaRepository<User, String> {

    Optional<User> findById(String id);

    boolean existsByEmailAndRole(String email, ERole role);

    Optional<User> findByEmailAndRole(String email, ERole role);
}
