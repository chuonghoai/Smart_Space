package com.vn.smart_space.service.position;

import java.util.List;

import com.vn.smart_space.dto.request.admin.PositionRequest;
import com.vn.smart_space.dto.response.admin.PositionResponse;

public interface IPositionService {

    List<PositionResponse> getPositions(boolean activeOnly);

    PositionResponse createPosition(PositionRequest request, String adminId);

    PositionResponse updatePosition(String id, PositionRequest request, String adminId);

    void deletePosition(String id, String adminId);
}
