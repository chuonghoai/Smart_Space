package com.vn.smart_space.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.ECallStatus;
import com.vn.smart_space.model.CallSession;

@Repository
public interface CallSessionRepository extends JpaRepository<CallSession, String> {

    @EntityGraph(attributePaths = { "caller", "caller.position", "receiver", "receiver.position" })
    @Query("SELECT cs FROM CallSession cs WHERE cs.id = :id")
    Optional<CallSession> findByIdWithUsers(@Param("id") String id);

    @Query("SELECT cs FROM CallSession cs WHERE (cs.caller.id = :userId OR cs.receiver.id = :userId) " +
            "AND cs.status IN (com.vn.smart_space.consts.ECallStatus.CONNECTING, " +
            "com.vn.smart_space.consts.ECallStatus.RINGING, " +
            "com.vn.smart_space.consts.ECallStatus.ACCEPTED, " +
            "com.vn.smart_space.consts.ECallStatus.ONGOING)")
    List<CallSession> findActiveCallsByUserId(@Param("userId") String userId);

    @EntityGraph(attributePaths = { "caller", "receiver" })
    List<CallSession> findByStatusInAndExpiresAtBefore(List<ECallStatus> statuses, LocalDateTime now);
}
