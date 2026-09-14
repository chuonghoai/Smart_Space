package com.vn.smart_space.service.staff;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EGender;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.CreateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffStatusRequest;
import com.vn.smart_space.dto.response.admin.StaffListResponse;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import com.vn.smart_space.dto.response.admin.StaffSummaryResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffServiceImpl implements IStaffService {

        UserRepository userRepository;
        ReportRepository reportRepository;
        ActivityHistoryRepository activityHistoryRepository;
        PasswordEncoder passwordEncoder;

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

        @Override
        public void updateStaffStatus(String id, UpdateStaffStatusRequest request, String adminId) {

                User user = userRepository.findById(id)
                                .orElseThrow(() -> new ResourceNotFoundException("Nhân viên không tồn tại"));

                if (user.getRole() != ERole.staff) {
                        throw new BadRequestException("Người dùng này không phải nhân viên");
                }

                EUserStatus newStatus;
                try {
                        newStatus = EUserStatus.valueOf(request.status().toLowerCase());
                } catch (IllegalArgumentException e) {
                        throw new BadRequestException("Trạng thái không hợp lệ: " + request.status());
                }

                user.setStatus(newStatus);
                userRepository.save(user);

                // Ghi Log
                User admin = findAdminOrNull(adminId);
                String adminName = resolveDisplayName(admin, "Quản trị viên");
                String staffName = resolveDisplayName(user, "Nhân viên");

                String i18nKey = "activity.staff.status_updated|" + adminName + "|" + staffName + "|"
                                + newStatus.name();

                ActivityHistory activity = ActivityHistory.builder()
                                .actor(admin)
                                .i18nKey(i18nKey)
                                .targetId(user.getId())
                                .build();
                activityHistoryRepository.save(activity);

        }

        @Override
        @Transactional
        public StaffResponse createStaff(CreateStaffRequest request, String adminId) {

                // 1. Validate email chưa tồn tại
                if (userRepository.existsByEmailAndRole(request.email(), ERole.staff)) {
                        throw new BadRequestException("Email đã được sử dụng");
                }

                // 2. Parse dateOfBirth (nullable)
                LocalDate dob = null;
                if (request.dateOfBirth() != null && !request.dateOfBirth().isEmpty()) {
                        dob = LocalDate.parse(request.dateOfBirth());
                }

                // 3. Parse gender (nullable)
                EGender gender = null;
                if (request.gender() != null && !request.gender().isEmpty()) {
                        gender = EGender.valueOf(request.gender().toLowerCase());
                }

                // 4. Tạo User — password hash bằng BCrypt
                User staff = User.builder()
                                .fullName(request.fullName())
                                .email(request.email())
                                .phone(request.phone())
                                .password(passwordEncoder.encode(request.password()))
                                .dateOfBirth(dob)
                                .gender(gender)
                                .role(ERole.staff)
                                .status(EUserStatus.active)
                                .avatarUrl(request.avatarUrl())
                                .language("vi")
                                .build();

                staff = userRepository.save(staff);

                // 5. Ghi Activity Log
                User admin = findAdminOrNull(adminId);
                String adminName = resolveDisplayName(admin, "Quản trị viên");
                String staffName = resolveDisplayName(staff, staff.getEmail());

                String i18nKey = "activity.staff.created|" + adminName + "|" + staffName;

                ActivityHistory activity = ActivityHistory.builder()
                                .actor(admin)
                                .i18nKey(i18nKey)
                                .targetId(staff.getId())
                                .build();
                activityHistoryRepository.save(activity);

                // 6. Return response
                return StaffResponse.builder()
                                .id(staff.getId())
                                .fullName(staff.getFullName())
                                .email(staff.getEmail())
                                .phoneNumber(staff.getPhone())
                                .avatarUrl(staff.getAvatarUrl())
                                .status(staff.getStatus().name())
                                .processingCount(0)
                                .build();
        }

        @Override
        @Transactional
        public StaffResponse updateStaff(String staffId, UpdateStaffRequest request, String adminId) {

                // 1. Tìm staff
                User staff = userRepository.findById(staffId)
                                .orElseThrow(() -> new ResourceNotFoundException("Nhân viên không tồn tại"));

                if (staff.getRole() != ERole.staff) {
                        throw new BadRequestException("Người dùng này không phải nhân viên");
                }

                // 2. Nếu email thay đổi → validate không trùng
                if (request.email() != null && !request.email().isEmpty()
                                && !request.email().equals(staff.getEmail())) {
                        if (userRepository.existsByEmailAndRole(request.email(), ERole.staff)) {
                                throw new BadRequestException("Email đã được sử dụng");
                        }
                        staff.setEmail(request.email());
                }

                // 3. Cập nhật các trường
                if (request.fullName() != null && !request.fullName().isEmpty()) {
                        staff.setFullName(request.fullName());
                }
                if (request.phone() != null) {
                        staff.setPhone(request.phone());
                }
                if (request.dateOfBirth() != null && !request.dateOfBirth().isEmpty()) {
                        staff.setDateOfBirth(LocalDate.parse(request.dateOfBirth()));
                }
                if (request.gender() != null && !request.gender().isEmpty()) {
                        staff.setGender(EGender.valueOf(request.gender().toLowerCase()));
                }
                if (request.avatarUrl() != null) {
                        staff.setAvatarUrl(request.avatarUrl());
                }

                staff = userRepository.save(staff);

                // 4. Ghi Activity Log
                User admin = findAdminOrNull(adminId);
                String adminName = resolveDisplayName(admin, "Quản trị viên");
                String staffName = resolveDisplayName(staff, staff.getEmail());

                String i18nKey = "activity.staff.updated|" + adminName + "|" + staffName;

                ActivityHistory activity = ActivityHistory.builder()
                                .actor(admin)
                                .i18nKey(i18nKey)
                                .targetId(staff.getId())
                                .build();
                activityHistoryRepository.save(activity);

                // 5. Return response
                return StaffResponse.builder()
                                .id(staff.getId())
                                .fullName(staff.getFullName())
                                .email(staff.getEmail())
                                .phoneNumber(staff.getPhone())
                                .avatarUrl(staff.getAvatarUrl())
                                .status(staff.getStatus().name())
                                .processingCount(0)
                                .build();
        }

        private String resolveDisplayName(User user, String fallback) {
                if (user == null)
                        return fallback;
                if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
                        return user.getFullName().trim();
                }
                if (user.getEmail() != null)
                        return user.getEmail().trim();
                return fallback;
        }

        private User findAdminOrNull(String adminId) {
                return adminId != null
                                ? userRepository.findById(adminId).orElse(null)
                                : null;
        }
}
