package com.vn.smart_space.repository;

import java.util.List;
import org.springframework.data.repository.CrudRepository;
import com.vn.smart_space.model.RefreshTokenSession;

public interface RefreshTokenSessionRepository extends CrudRepository<RefreshTokenSession, String> {

    List<RefreshTokenSession> findByUserId(String userId);
}
