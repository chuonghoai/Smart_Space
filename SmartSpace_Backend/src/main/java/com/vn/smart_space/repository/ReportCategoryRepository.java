package com.vn.smart_space.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.model.ReportCategory;

@Repository
public interface ReportCategoryRepository extends JpaRepository<ReportCategory, String> {

    boolean existsByCodeIgnoreCase(String code);

    boolean existsByCodeIgnoreCaseAndIdNot(String code, String id);

    @EntityGraph(attributePaths = { "positions" })
    List<ReportCategory> findAllByOrderByDisplayOrderAscNameViAsc();

    @EntityGraph(attributePaths = { "positions" })
    List<ReportCategory> findAllByIsActiveTrueOrderByDisplayOrderAscNameViAsc();

    @EntityGraph(attributePaths = { "positions" })
    Optional<ReportCategory> findWithPositionsById(String id);

}
