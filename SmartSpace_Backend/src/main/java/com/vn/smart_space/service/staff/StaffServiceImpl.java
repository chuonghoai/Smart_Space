package com.vn.smart_space.service.staff;

import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.admin.StaffListResponse;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import com.vn.smart_space.dto.response.admin.StaffSummaryResponse;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffServiceImpl implements IStaffService {

    UserRepository userRepository;
    ReportRepository reportRepository;


    @Override
    public List<StaffResponse> getStaffs() {
        List<User> staffs = userRepository.findByRole(ERole.staff);
        return staffs.stream().map(s -> StaffResponse.builder()
                .id(s.getId())
                .fullName(s.getFullName())
                .email(s.getEmail())
                .phoneNumber(s.getPhone())
                .avatarUrl(s.getAvatarUrl())
                .status(s.getStatus() != null ? s.getStatus().name() : null)
                .build()).collect(Collectors.toList());
    }

    @Override
    public StaffListResponse getStaffsPaged(int page, int size, String search, String status) {
        // 1. Parse status filter
        EUserStatus statusEnum = null;
        if (status != null && !status.isEmpty() && !status.equalsIgnoreCase("all")) {
            try {
                statusEnum = EUserStatus.valueOf(status.toLowerCase());
            } catch (IllegalArgumentException e) {
                // Invalid status → ignore filter
            }
        }

        // 2. Normalize search
        String searchParam = (search != null && !search.trim().isEmpty()) ? search.trim() : null;

        // 3. Query staffs with pagination
        Pageable pageable = PageRequest.of(page - 1, size);
        Page<User> staffPage = userRepository.findStaffs(ERole.staff, statusEnum, searchParam, pageable);
        List<User> staffUsers = staffPage.getContent();

        // 4. Batch query: count processing reports per staff
        Map<String, Long> processingCountMap = Collections.emptyMap();
        if (!staffUsers.isEmpty()) {
            List<String> staffIds = staffUsers.stream().map(User::getId).collect(Collectors.toList());
            List<Object[]> counts = reportRepository.countByAssignedStaffIdInAndStatus(
                    staffIds, EReportStatus.processing);
            processingCountMap = counts.stream()
                    .collect(Collectors.toMap(
                            row -> (String) row[0],
                            row -> (Long) row[1]));
        }

        // 5. Map User → StaffResponse
        final Map<String, Long> countMap = processingCountMap;
        List<StaffResponse> staffResponses = staffUsers.stream().map(s -> StaffResponse.builder()
                .id(s.getId())
                .fullName(s.getFullName())
                .email(s.getEmail())
                .phoneNumber(s.getPhone())
                .avatarUrl(s.getAvatarUrl())
                .status(s.getStatus() != null ? s.getStatus().name() : null)
                .processingCount(countMap.getOrDefault(s.getId(), 0L))
                .build()).collect(Collectors.toList());

        // 6. Build PageResponse
        PageResponse<StaffResponse> pageResponse = PageResponse.<StaffResponse>builder()
                .currentPage(page)
                .pageSize(pageable.getPageSize())
                .totalPages(staffPage.getTotalPages())
                .totalElements(staffPage.getTotalElements())
                .content(staffResponses)
                .build();

        // 7. Build Summary (tính trên toàn bộ dữ liệu, không filter)
        long totalStaffs = userRepository.countByRole(ERole.staff);
        long activeStaffs = userRepository.countByRoleAndStatus(ERole.staff, EUserStatus.active);
        long blockedStaffs = userRepository.countByRoleAndStatus(ERole.staff, EUserStatus.blocked);

        long totalProcessing = reportRepository.countByStatus(EReportStatus.processing);

        StaffSummaryResponse summary = StaffSummaryResponse.builder()
                .total(totalStaffs)
                .active(activeStaffs)
                .blocked(blockedStaffs)
                .totalProcessing(totalProcessing)
                .build();

        // 8. Return combined response
        return StaffListResponse.builder()
                .summary(summary)
                .staffs(pageResponse)
                .build();
    }
}
