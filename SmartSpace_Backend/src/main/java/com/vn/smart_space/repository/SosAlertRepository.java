package com.vn.smart_space.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.ESosStatus;
import com.vn.smart_space.model.SosAlert;

import jakarta.persistence.LockModeType;

@Repository
public interface SosAlertRepository extends JpaRepository<SosAlert, String> {

    @Query("SELECT s FROM SosAlert s JOIN FETCH s.user LEFT JOIN FETCH s.acknowledgedBy "
            + "WHERE s.user.id = :userId AND s.status IN :statuses ORDER BY s.createdAt DESC")
    List<SosAlert> findByUserAndStatuses(@Param("userId") String userId,
            @Param("statuses") Collection<ESosStatus> statuses);

    @Query("SELECT s FROM SosAlert s JOIN FETCH s.user LEFT JOIN FETCH s.acknowledgedBy LEFT JOIN FETCH s.resolvedBy "
            + "WHERE s.id = :id")
    Optional<SosAlert> findDetail(@Param("id") String id);

    @EntityGraph(attributePaths = { "user", "acknowledgedBy", "resolvedBy" })
    Page<SosAlert> findByStatusIn(Collection<ESosStatus> statuses, Pageable pageable);

    long countByStatusIn(Collection<ESosStatus> statuses);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM SosAlert s WHERE s.id = :id")
    Optional<SosAlert> lockById(@Param("id") String id);
}
