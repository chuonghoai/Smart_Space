package com.vn.smart_space.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.Position;

@Repository
public interface PositionRepository extends JpaRepository<Position, String> {

    boolean existsByCodeIgnoreCase(String code);

    boolean existsByCodeIgnoreCaseAndIdNot(String code, String id);

    List<Position> findAllByOrderByNameAsc();

    List<Position> findAllByIsActiveTrueOrderByNameAsc();
}
