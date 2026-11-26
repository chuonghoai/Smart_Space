package com.vn.smart_space.repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.vn.smart_space.consts.EEmergencyContactStatus;
import com.vn.smart_space.model.EmergencyContact;

@Repository
public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, String> {

    @Query("SELECT c FROM EmergencyContact c LEFT JOIN FETCH c.linkedUser "
            + "WHERE c.owner.id = :ownerId ORDER BY c.priority ASC, c.createdAt ASC")
    List<EmergencyContact> findAllByOwner(@Param("ownerId") String ownerId);

    @Query("SELECT c FROM EmergencyContact c LEFT JOIN FETCH c.linkedUser "
            + "WHERE c.id = :id AND c.owner.id = :ownerId")
    Optional<EmergencyContact> findByIdAndOwner(@Param("id") String id, @Param("ownerId") String ownerId);

    @Query("SELECT c FROM EmergencyContact c JOIN FETCH c.owner "
            + "WHERE c.linkedUser.id = :userId AND c.status IN :statuses ORDER BY c.createdAt DESC")
    List<EmergencyContact> findGuardianships(@Param("userId") String userId,
            @Param("statuses") Collection<EEmergencyContactStatus> statuses);

    @Query("SELECT c FROM EmergencyContact c JOIN FETCH c.owner JOIN FETCH c.linkedUser "
            + "WHERE c.id = :id AND c.linkedUser.id = :userId")
    Optional<EmergencyContact> findByIdAndLinkedUser(@Param("id") String id, @Param("userId") String userId);

    long countByOwnerId(String ownerId);

    /** Liên hệ đang nhận cảnh báo SOS của owner, theo thứ tự ưu tiên. */
    @Query("SELECT c FROM EmergencyContact c LEFT JOIN FETCH c.linkedUser "
            + "WHERE c.owner.id = :ownerId AND c.status = :status ORDER BY c.priority ASC")
    List<EmergencyContact> findByOwnerAndStatus(@Param("ownerId") String ownerId,
            @Param("status") EEmergencyContactStatus status);

    boolean existsByOwnerIdAndLinkedUserIdAndStatus(String ownerId, String linkedUserId,
            EEmergencyContactStatus status);
}
