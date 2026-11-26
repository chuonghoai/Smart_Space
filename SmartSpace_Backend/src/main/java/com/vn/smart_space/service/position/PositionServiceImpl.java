package com.vn.smart_space.service.position;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.admin.PositionRequest;
import com.vn.smart_space.dto.response.admin.PositionResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Position;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.PositionRepository;
import com.vn.smart_space.repository.UserRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class PositionServiceImpl implements IPositionService {

    PositionRepository positionRepository;
    UserRepository userRepository;
    ActivityHistoryRepository activityHistoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<PositionResponse> getPositions(boolean activeOnly) {
        List<Position> positions = activeOnly
                ? positionRepository.findAllByIsActiveTrueOrderByNameAsc()
                : positionRepository.findAllByOrderByNameAsc();

        Map<String, Long> countMap = positions.isEmpty()
                ? Collections.emptyMap()
                : userRepository.countStaffGroupByPosition(ERole.staff).stream()
                        .collect(Collectors.toMap(row -> (String) row[0], row -> (Long) row[1]));

        return positions.stream()
                .map(p -> toResponse(p, countMap.getOrDefault(p.getId(), 0L)))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public PositionResponse createPosition(PositionRequest request, String adminId) {
        String code = normalizeCode(request.code());
        if (positionRepository.existsByCodeIgnoreCase(code)) {
            throw new BadRequestException("position.code.exists");
        }

        Position position = Position.builder()
                .code(code)
                .name(request.name().trim())
                .description(trimOrNull(request.description()))
                .isActive(request.isActive() == null || request.isActive())
                .build();
        position = positionRepository.save(position);

        logActivity("activity.position.created", adminId, position);
        return toResponse(position, 0L);
    }

    @Override
    @Transactional
    public PositionResponse updatePosition(String id, PositionRequest request, String adminId) {
        Position position = findOrThrow(id);

        String code = normalizeCode(request.code());
        if (positionRepository.existsByCodeIgnoreCaseAndIdNot(code, id)) {
            throw new BadRequestException("position.code.exists");
        }

        position.setCode(code);
        position.setName(request.name().trim());
        position.setDescription(trimOrNull(request.description()));
        if (request.isActive() != null) {
            position.setIsActive(request.isActive());
        }
        position = positionRepository.save(position);

        logActivity("activity.position.updated", adminId, position);
        return toResponse(position, userRepository.countByPositionId(id));
    }

    @Override
    @Transactional
    public void deletePosition(String id, String adminId) {
        Position position = findOrThrow(id);

        if (userRepository.countByPositionId(id) > 0) {
            throw new BadRequestException("position.in_use");
        }

        positionRepository.delete(position);
        logActivity("activity.position.deleted", adminId, position);
    }

    private Position findOrThrow(String id) {
        return positionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("position.not_found"));
    }

    private PositionResponse toResponse(Position p, long staffCount) {
        return PositionResponse.builder()
                .id(p.getId())
                .code(p.getCode())
                .name(p.getName())
                .description(p.getDescription())
                .active(Boolean.TRUE.equals(p.getIsActive()))
                .staffCount(staffCount)
                .build();
    }

    private String normalizeCode(String code) {
        return code.trim().toUpperCase().replaceAll("\\s+", "_");
    }

    private String trimOrNull(String value) {
        return value != null && !value.trim().isEmpty() ? value.trim() : null;
    }

    private void logActivity(String key, String adminId, Position position) {
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;
        String adminName = admin != null && admin.getFullName() != null
                ? admin.getFullName().trim()
                : "Admin";

        ActivityHistory activity = ActivityHistory.builder()
                .actor(admin)
                .i18nKey(key + "|" + adminName + "|" + position.getName())
                .targetId(position.getId())
                .build();
        activityHistoryRepository.save(activity);
    }
}
