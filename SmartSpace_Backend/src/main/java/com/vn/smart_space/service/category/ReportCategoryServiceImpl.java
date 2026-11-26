package com.vn.smart_space.service.category;

import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.dto.request.admin.CategoryRequest;
import com.vn.smart_space.dto.response.category.CategoryResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Position;
import com.vn.smart_space.model.ReportCategory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.PositionRepository;
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ReportCategoryServiceImpl implements IReportCategoryService {

    ReportCategoryRepository categoryRepository;
    PositionRepository positionRepository;
    ReportRepository reportRepository;
    UserRepository userRepository;
    ActivityHistoryRepository activityHistoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<CategoryResponse> getCategories(boolean activeOnly) {
        List<ReportCategory> categories = activeOnly
                ? categoryRepository.findAllByIsActiveTrueOrderByDisplayOrderAscNameViAsc()
                : categoryRepository.findAllByOrderByDisplayOrderAscNameViAsc();

        Map<String, Long> reportCountMap = categories.isEmpty()
                ? Collections.emptyMap()
                : reportRepository.countReportsGroupByCategory().stream()
                        .collect(Collectors.toMap(
                                row -> (String) row[0],
                                row -> ((Number) row[1]).longValue()));

        return categories.stream()
                .map(c -> toResponse(c, reportCountMap.getOrDefault(c.getId(), 0L)))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public CategoryResponse createCategory(CategoryRequest request, String adminId) {
        String code = normalizeCode(request.code());
        if (categoryRepository.existsByCodeIgnoreCase(code)) {
            throw new BadRequestException("category.code.exists");
        }

        ReportCategory category = ReportCategory.builder()
                .code(code)
                .nameVi(request.nameVi().trim())
                .nameEn(request.nameEn().trim())
                .description(trimOrNull(request.description()))
                .iconKey(trimOrNull(request.iconKey()))
                .defaultSeverity(parseSeverity(request.defaultSeverity(), EReportSeverity.low))
                .isActive(request.isActive() == null || request.isActive())
                .displayOrder(request.displayOrder() != null ? request.displayOrder() : 0)
                .positions(resolvePositions(request.positionIds(), Collections.emptySet()))
                .build();

        category = categoryRepository.save(category);
        logActivity("activity.category.created", adminId, category);
        return toResponse(category, 0L);
    }

    @Override
    @Transactional
    public CategoryResponse updateCategory(String id, CategoryRequest request, String adminId) {
        ReportCategory category = categoryRepository.findWithPositionsById(id)
                .orElseThrow(() -> new ResourceNotFoundException("category.not_found"));

        String code = normalizeCode(request.code());
        if (categoryRepository.existsByCodeIgnoreCaseAndIdNot(code, id)) {
            throw new BadRequestException("category.code.exists");
        }

        Set<String> existingPositionIds = category.getPositions().stream()
                .map(Position::getId)
                .collect(Collectors.toSet());

        category.setCode(code);
        category.setNameVi(request.nameVi().trim());
        category.setNameEn(request.nameEn().trim());
        category.setDescription(trimOrNull(request.description()));
        category.setIconKey(trimOrNull(request.iconKey()));
        if (request.defaultSeverity() != null) {
            category.setDefaultSeverity(parseSeverity(request.defaultSeverity(), EReportSeverity.low));
        }
        if (request.isActive() != null) {
            category.setIsActive(request.isActive());
        }
        if (request.displayOrder() != null) {
            category.setDisplayOrder(request.displayOrder());
        }
        if (request.positionIds() != null) {
            category.setPositions(resolvePositions(request.positionIds(), existingPositionIds));
        }

        category = categoryRepository.save(category);
        logActivity("activity.category.updated", adminId, category);
        return toResponse(category, reportRepository.countByCategoryId(id));
    }

    @Override
    @Transactional
    public void deleteCategory(String id, String adminId) {
        ReportCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("category.not_found"));

        if (reportRepository.countByCategoryId(id) > 0) {
            throw new BadRequestException("category.in_use");
        }

        categoryRepository.delete(category);
        logActivity("activity.category.deleted", adminId, category);
    }

    private Set<Position> resolvePositions(List<String> positionIds, Set<String> allowedInactiveIds) {
        if (positionIds == null || positionIds.isEmpty()) {
            return new LinkedHashSet<>();
        }
        List<String> normalizedIds = positionIds.stream()
                .filter(id -> id != null && !id.isBlank())
                .map(String::trim)
                .distinct()
                .collect(Collectors.toList());
        if (normalizedIds.isEmpty()) {
            return new LinkedHashSet<>();
        }

        List<Position> found = positionRepository.findAllById(normalizedIds);
        Map<String, Position> byId = new HashMap<>();
        for (Position p : found) {
            byId.put(p.getId(), p);
        }

        Set<Position> result = new LinkedHashSet<>();
        for (String pid : normalizedIds) {
            Position position = byId.get(pid);
            if (position == null) {
                throw new ResourceNotFoundException("position.not_found");
            }
            if (!Boolean.TRUE.equals(position.getIsActive()) && !allowedInactiveIds.contains(pid)) {
                throw new BadRequestException("position.inactive");
            }
            result.add(position);
        }
        return result;
    }

    private EReportSeverity parseSeverity(String value, EReportSeverity fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        try {
            return EReportSeverity.valueOf(value.trim().toLowerCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("category.severity.invalid");
        }
    }

    private CategoryResponse toResponse(ReportCategory c, long reportCount) {
        List<CategoryResponse.PositionSummary> positionSummaries = c.getPositions().stream()
                .sorted(Comparator.comparing(Position::getName, String.CASE_INSENSITIVE_ORDER))
                .map(p -> CategoryResponse.PositionSummary.builder()
                        .id(p.getId())
                        .code(p.getCode())
                        .name(p.getName())
                        .active(Boolean.TRUE.equals(p.getIsActive()))
                        .build())
                .collect(Collectors.toList());

        return CategoryResponse.builder()
                .id(c.getId())
                .code(c.getCode())
                .nameVi(c.getNameVi())
                .nameEn(c.getNameEn())
                .description(c.getDescription())
                .iconKey(c.getIconKey())
                .defaultSeverity(c.getDefaultSeverity() != null ? c.getDefaultSeverity().name() : EReportSeverity.low.name())
                .active(Boolean.TRUE.equals(c.getIsActive()))
                .displayOrder(c.getDisplayOrder() != null ? c.getDisplayOrder() : 0)
                .reportCount(reportCount)
                .positions(positionSummaries)
                .build();
    }

    private String normalizeCode(String code) {
        return code.trim().toUpperCase().replaceAll("\\s+", "_");
    }

    private String trimOrNull(String value) {
        return value != null && !value.trim().isEmpty() ? value.trim() : null;
    }

    private void logActivity(String key, String adminId, ReportCategory category) {
        User admin = adminId != null ? userRepository.findById(adminId).orElse(null) : null;
        String adminName = admin != null && admin.getFullName() != null && !admin.getFullName().isBlank()
                ? admin.getFullName().trim()
                : "Admin";

        ActivityHistory activity = ActivityHistory.builder()
                .actor(admin)
                .i18nKey(key + "|" + adminName + "|" + category.getNameVi())
                .targetId(category.getId())
                .build();
        activityHistoryRepository.save(activity);
    }
}
