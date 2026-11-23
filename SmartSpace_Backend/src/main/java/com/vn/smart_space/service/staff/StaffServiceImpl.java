package com.vn.smart_space.service.staff;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import com.vn.smart_space.model.Report;
import com.vn.smart_space.service.report.ReportServiceImpl;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.mail.MailException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EGender;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.admin.CreateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffStatusRequest;
import com.vn.smart_space.dto.response.admin.StaffListResponse;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import com.vn.smart_space.dto.response.admin.StaffStatisticsResponse;
import com.vn.smart_space.dto.response.admin.StaffSummaryResponse;
import com.vn.smart_space.dto.response.admin.StaffTrendResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Position;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.PositionRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.utils.AnalyticsStatHelper;
import com.vn.smart_space.utils.PasswordGenerator;
import com.vn.smart_space.utils.TrendBucketHelper;
import java.util.EnumMap;
import java.util.HashMap;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class StaffServiceImpl implements IStaffService {

        static final int WORKLOAD_LIMIT = 5;

        UserRepository userRepository;
        ReportRepository reportRepository;
        ActivityHistoryRepository activityHistoryRepository;
        PositionRepository positionRepository;
        PasswordEncoder passwordEncoder;
        IMailService mailService;
        IAuthenticationService authenticationService;

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
        public StaffListResponse getStaffsPaged(int page, int size, String search, String status,
                        String positionId) {
                // 1. Parse status filter
                EUserStatus statusEnum = null;
                if (status != null && !status.isEmpty() && !status.equalsIgnoreCase("all")) {
                        try {
                                statusEnum = EUserStatus.valueOf(status.toLowerCase());
                        } catch (IllegalArgumentException e) {
                                // Invalid status → ignore filter
                        }
                }

                // 2. Normalize search + position filter
                String searchParam = (search != null && !search.trim().isEmpty()) ? search.trim() : null;
                String positionParam = (positionId != null && !positionId.trim().isEmpty()
                                && !positionId.equalsIgnoreCase("all")) ? positionId.trim() : null;

                // 3. Query staffs with pagination
                Pageable pageable = PageRequest.of(page - 1, size);
                Page<User> staffPage = userRepository.findStaffs(ERole.staff, statusEnum, positionParam, searchParam,
                                pageable);
                List<User> staffUsers = staffPage.getContent();

                // 4. Batch query: count processing reports per staff + active weighted workload
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

                LocalDateTime now = LocalDateTime.now();
                List<Report> activeProcessing = reportRepository.findActiveReportsWithStaff(
                                List.of(EReportStatus.processing));
                List<User> allActiveStaffs = userRepository.findByRole(ERole.staff).stream()
                                .filter(u -> u.getStatus() != EUserStatus.blocked)
                                .collect(Collectors.toList());
                if (allActiveStaffs.isEmpty()) {
                        allActiveStaffs = staffUsers.stream()
                                        .filter(u -> u.getStatus() != EUserStatus.blocked)
                                        .collect(Collectors.toList());
                }
                WorkloadSnapshot snapshot = buildWorkloadSnapshot(allActiveStaffs, activeProcessing, now);

                // 5. Map User -> StaffResponse
                final Map<String, Long> countMap = processingCountMap;
                List<StaffResponse> staffResponses = staffUsers.stream().map(s -> {
                        StaffResponse response = toStaffResponse(s);
                        long activeCnt = snapshot.processingByStaff.containsKey(s.getId())
                                        ? snapshot.processingByStaff.get(s.getId())
                                        : countMap.getOrDefault(s.getId(), 0L);
                        response.setProcessingCount(activeCnt);
                        applyWorkloadFields(response, snapshot);
                        return response;
                }).collect(Collectors.toList());

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

                // Khóa → đá mọi phiên đăng nhập ngay lập tức; mở khóa → gỡ cờ chặn
                if (newStatus == EUserStatus.blocked) {
                        authenticationService.revokeUserAccess(user.getId());
                } else {
                        authenticationService.restoreUserAccess(user.getId());
                }

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

                // 1. Validate email chưa tồn tại (fullName/email đã được @Valid kiểm tra ở
                // controller)
                String email = request.email().trim();
                if (userRepository.existsByEmailAndRole(email, ERole.staff)) {
                        throw new BadRequestException("auth.email.exists");
                }

                // 2-3. Parse dateOfBirth & gender (nullable, sai định dạng → 400)
                LocalDate dob = parseDateOfBirth(request.dateOfBirth());
                EGender gender = parseGender(request.gender());

                // 4. Tự sinh mật khẩu ngẫu nhiên và tạo User — password hash bằng BCrypt
                String rawPassword = PasswordGenerator.generateRandomPassword();
                User staff = User.builder()
                                .fullName(request.fullName().trim())
                                .email(email)
                                .phone(request.phone())
                                .password(passwordEncoder.encode(rawPassword))
                                .dateOfBirth(dob)
                                .gender(gender)
                                .role(ERole.staff)
                                .status(EUserStatus.active)
                                .avatarUrl(request.avatarUrl())
                                .language("vi")
                                .position(resolvePosition(request.positionId()))
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

                // 6. Gửi email thông báo tài khoản và mật khẩu cho nhân viên.
                try {
                        mailService.sendStaffCredentialsEmail(
                                        staff.getEmail(),
                                        staff.getFullName(),
                                        rawPassword,
                                        staff.getPosition() != null ? staff.getPosition().getName() : null,
                                        staff.getLanguage());
                } catch (MailException e) {
                        log.error("Failed to send staff credentials email to {}", staff.getEmail(), e);
                        throw new BadRequestException("mail.staff.credentials.send_failed");
                }

                // 7. Return response
                return toStaffResponse(staff);
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

                // 2. Cập nhật hồ sơ — email & mật khẩu là thông tin đăng nhập, admin không được sửa
                if (request.fullName() != null && !request.fullName().isEmpty()) {
                        staff.setFullName(request.fullName());
                }
                if (request.phone() != null) {
                        staff.setPhone(request.phone());
                }
                LocalDate dob = parseDateOfBirth(request.dateOfBirth());
                if (dob != null) {
                        staff.setDateOfBirth(dob);
                }
                EGender gender = parseGender(request.gender());
                if (gender != null) {
                        staff.setGender(gender);
                }
                if (request.avatarUrl() != null) {
                        staff.setAvatarUrl(request.avatarUrl());
                }
                // positionId: null = giữ nguyên, rỗng = bỏ chức vụ, có giá trị = đổi chức vụ
                if (request.positionId() != null) {
                        String currentId = staff.getPosition() != null ? staff.getPosition().getId() : "";
                        if (!request.positionId().trim().equals(currentId)) {
                                staff.setPosition(resolvePosition(request.positionId()));
                        }
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
                return toStaffResponse(staff);
        }

        /** Trả về Position hợp lệ (đang active), null nếu chuỗi rỗng. */
        /** Ngày sinh dạng ISO (yyyy-MM-dd); null/rỗng → null, sai định dạng → 400. */
        private LocalDate parseDateOfBirth(String value) {
                if (value == null || value.isBlank()) {
                        return null;
                }
                try {
                        return LocalDate.parse(value.trim());
                } catch (DateTimeParseException e) {
                        throw new BadRequestException("staff.date_of_birth.invalid");
                }
        }

        /**
         * Giới tính theo EGender (không phân biệt hoa thường); null/rỗng → null, sai
         * giá trị → 400.
         */
        private EGender parseGender(String value) {
                if (value == null || value.isBlank()) {
                        return null;
                }
                try {
                        return EGender.valueOf(value.trim().toLowerCase());
                } catch (IllegalArgumentException e) {
                        throw new BadRequestException("staff.gender.invalid");
                }
        }

        private Position resolvePosition(String positionId) {
                if (positionId == null || positionId.trim().isEmpty()) {
                        return null;
                }
                Position position = positionRepository.findById(positionId.trim())
                                .orElseThrow(() -> new ResourceNotFoundException("position.not_found"));
                if (!Boolean.TRUE.equals(position.getIsActive())) {
                        throw new BadRequestException("position.inactive");
                }
                return position;
        }

        private StaffResponse toStaffResponse(User s) {
                Position position = s.getPosition();
                return StaffResponse.builder()
                                .id(s.getId())
                                .fullName(s.getFullName())
                                .email(s.getEmail())
                                .phoneNumber(s.getPhone())
                                .avatarUrl(s.getAvatarUrl())
                                .dateOfBirth(s.getDateOfBirth())
                                .gender(s.getGender() != null ? s.getGender().name() : null)
                                .status(s.getStatus() != null ? s.getStatus().name() : null)
                                .processingCount(0)
                                .positionId(position != null ? position.getId() : null)
                                .positionName(position != null ? position.getName() : null)
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

        @Override
        @Transactional(readOnly = true)
        public StaffStatisticsResponse getStatistics(Integer year, Integer month) {
                LocalDateTime now = LocalDateTime.now();
                YearMonth currentCalendarMonth = YearMonth.from(now);
                YearMonth selectedMonth = (year != null && month != null && month >= 1 && month <= 12)
                                ? YearMonth.of(year, month)
                                : currentCalendarMonth;

                LocalDateTime rangeStart = selectedMonth.atDay(1).atStartOfDay();
                LocalDateTime rangeEnd = selectedMonth.equals(currentCalendarMonth)
                                ? now
                                : selectedMonth.plusMonths(1).atDay(1).atStartOfDay();
                LocalDateTime evalTime = now.isBefore(rangeEnd) ? now : rangeEnd;

                YearMonth prevMonth = selectedMonth.minusMonths(1);
                LocalDateTime prevStart = prevMonth.atDay(1).atStartOfDay();
                LocalDateTime prevEnd = rangeStart;

                List<StaffStatisticsResponse.AvailableMonthItem> availableMonths = buildAvailableMonths(selectedMonth);

                // 1. Nhân sự + danh sách toàn bộ nhân viên
                long total = userRepository.countByRole(ERole.staff);
                long active = userRepository.countByRoleAndStatus(ERole.staff, EUserStatus.active);
                long blocked = userRepository.countByRoleAndStatus(ERole.staff, EUserStatus.blocked);

                List<Report> trackedReports = reportRepository.findAssignedByStatusInWithStaff(
                                List.of(EReportStatus.processing, EReportStatus.processed));
                List<User> allStaffs = userRepository.findByRole(ERole.staff);
                Map<String, User> staffUsers = new LinkedHashMap<>();
                for (User s : allStaffs) {
                        staffUsers.put(s.getId(), s);
                }

                // Compute 90d P90 thresholds + active weighted workload snapshot from tracked reports
                List<AnalyticsStatHelper.DurationSample> durationSamples = new ArrayList<>();
                List<Report> currentActiveProcessing = new ArrayList<>();
                LocalDateTime p90Cutoff = now.minusDays(90);
                for (Report r : trackedReports) {
                        if (r.getStatus() == EReportStatus.processing) {
                                currentActiveProcessing.add(r);
                        } else if (r.getStatus() == EReportStatus.processed && r.getAssignedAt() != null) {
                                LocalDateTime resolvedTime = r.getResolvedAt() != null
                                                ? toLocalDateTime(r.getResolvedAt())
                                                : r.getUpdatedAt();
                                LocalDateTime assignedTime = toLocalDateTime(r.getAssignedAt());
                                if (resolvedTime != null && !resolvedTime.isBefore(p90Cutoff)
                                                && assignedTime != null && !resolvedTime.isBefore(assignedTime)) {
                                        durationSamples.add(new AnalyticsStatHelper.DurationSample(
                                                        r.getSeverity(),
                                                        Duration.between(assignedTime, resolvedTime).toMinutes()));
                                }
                        }
                }
                Map<EReportSeverity, Long> fallbackDays = new EnumMap<>(EReportSeverity.class);
                for (EReportSeverity s : EReportSeverity.values()) {
                        fallbackDays.put(s, ReportServiceImpl.deadlineDaysForSeverity(s));
                }
                Map<EReportSeverity, Long> p90BySeverity = AnalyticsStatHelper.computeP90Thresholds(
                                durationSamples, fallbackDays, null, null, null);
                List<User> activeStaffList = allStaffs.stream()
                                .filter(u -> u.getStatus() != EUserStatus.blocked)
                                .collect(Collectors.toList());
                WorkloadSnapshot activeSnapshot = buildWorkloadSnapshot(activeStaffList, currentActiveProcessing, now);

                // [0]=overdue, [1]=completedLate, [2]=completedOnTime, [3]=processing, [4]=rehandling, [5]=resolved, [6]=bottleneck
                Map<String, long[]> countsByStaff = new LinkedHashMap<>();
                for (String staffId : staffUsers.keySet()) {
                        countsByStaff.put(staffId, new long[7]);
                }

                long processingReports = 0;
                long resolved = 0;
                long resolvedPrevious = 0;
                long currDurationMinutes = 0;
                int currDurationSamples = 0;
                long prevDurationMinutes = 0;
                int prevDurationSamples = 0;
                long overdueReports = 0;
                long completedLate = 0;
                long completedOnTime = 0;
                long totalBottlenecks = 0;

                for (Report r : trackedReports) {
                        User assigned = r.getAssignedStaff();
                        if (assigned == null) {
                                continue;
                        }
                        staffUsers.putIfAbsent(assigned.getId(), assigned);
                        long[] c = countsByStaff.computeIfAbsent(assigned.getId(), k -> new long[7]);
                        LocalDateTime deadline = ReportServiceImpl.resolveDeadline(r);

                        if (r.getStatus() == EReportStatus.processed) {
                                LocalDateTime resolvedAt = toLocalDateTime(r.getResolvedAt());
                                LocalDateTime resolvedTime = resolvedAt != null ? resolvedAt : r.getUpdatedAt();
                                if (resolvedTime == null) {
                                        continue;
                                }
                                LocalDateTime assignedAt = toLocalDateTime(r.getAssignedAt());

                                if (!resolvedTime.isBefore(prevStart) && resolvedTime.isBefore(prevEnd)) {
                                        resolvedPrevious++;
                                        if (assignedAt != null && !resolvedTime.isBefore(assignedAt)) {
                                                prevDurationMinutes += Duration.between(assignedAt, resolvedTime).toMinutes();
                                                prevDurationSamples++;
                                        }
                                }

                                if (!resolvedTime.isBefore(rangeStart) && !resolvedTime.isAfter(rangeEnd)) {
                                        resolved++;
                                        c[5]++;
                                        if (assignedAt != null && !resolvedTime.isBefore(assignedAt)) {
                                                currDurationMinutes += Duration.between(assignedAt, resolvedTime).toMinutes();
                                                currDurationSamples++;
                                        }
                                        if (deadline != null) {
                                                if (resolvedAt != null && resolvedAt.isAfter(deadline)) {
                                                        completedLate++;
                                                        c[1]++;
                                                } else {
                                                        completedOnTime++;
                                                        c[2]++;
                                                }
                                        }
                                }
                        } else if (r.getStatus() == EReportStatus.processing) {
                                LocalDateTime assignedTime = r.getAssignedAt() != null
                                                ? toLocalDateTime(r.getAssignedAt())
                                                : r.getCreatedAt();
                                boolean inSelectedMonth;
                                if (selectedMonth.equals(currentCalendarMonth)) {
                                        inSelectedMonth = assignedTime == null || !assignedTime.isAfter(rangeEnd);
                                } else {
                                        boolean assignedInMonth = assignedTime != null
                                                        && !assignedTime.isBefore(rangeStart)
                                                        && assignedTime.isBefore(rangeEnd);
                                        boolean deadlineInMonth = deadline != null
                                                        && !deadline.isBefore(rangeStart)
                                                        && deadline.isBefore(rangeEnd);
                                        inSelectedMonth = assignedInMonth || deadlineInMonth;
                                }
                                if (!inSelectedMonth) {
                                        continue;
                                }

                                processingReports++;
                                c[3]++;
                                if (Boolean.FALSE.equals(r.getIsReviewResolved())) {
                                        c[4]++;
                                }
                                if (deadline != null && !deadline.isAfter(evalTime)) {
                                        overdueReports++;
                                        c[0]++;
                                }
                                if (AnalyticsStatHelper.isProcessingBottleneck(
                                                r.getStatus(), r.getSeverity(), r.getAssignedAt(), r.getCreatedAt(),
                                                p90BySeverity, evalTime)) {
                                        c[6]++;
                                        totalBottlenecks++;
                                }
                        }
                }

                Long avgMinutes = currDurationSamples == 0
                                ? null
                                : Math.round((double) currDurationMinutes / currDurationSamples);
                Long avgMinutesPrevious = prevDurationSamples == 0
                                ? null
                                : Math.round((double) prevDurationMinutes / prevDurationSamples);

                long totalFinished = completedOnTime + completedLate;
                Double onTimeRate = totalFinished == 0
                                ? null
                                : Math.round((completedOnTime * 1000.0) / totalFinished) / 10.0;

                List<StaffStatisticsResponse.WorkloadItem> workload = countsByStaff.entrySet().stream()
                                .filter(entry -> entry.getValue()[3] > 0 || entry.getValue()[5] > 0)
                                .sorted(Comparator
                                                .<Map.Entry<String, long[]>>comparingLong(e ->
                                                                activeSnapshot.weightedByStaff.getOrDefault(e.getKey(), 0L))
                                                .reversed()
                                                .thenComparing(Comparator.<Map.Entry<String, long[]>>comparingLong(
                                                                e -> e.getValue()[3]).reversed())
                                                .thenComparing(Comparator.<Map.Entry<String, long[]>>comparingLong(
                                                                e -> e.getValue()[5]).reversed()))
                                .limit(WORKLOAD_LIMIT)
                                .map(entry -> {
                                        StaffResponse staff = toStaffResponse(staffUsers.get(entry.getKey()));
                                        staff.setProcessingCount(entry.getValue()[3]);
                                        applyWorkloadFields(staff, activeSnapshot);
                                        return StaffStatisticsResponse.WorkloadItem.builder()
                                                        .staff(staff)
                                                        .resolvedCount(entry.getValue()[5])
                                                        .weightedLoad(staff.getWeightedLoad())
                                                        .isOverloaded(staff.isOverloaded())
                                                        .build();
                                })
                                .collect(Collectors.toList());

                List<StaffStatisticsResponse.DeadlinePerformanceItem> deadlinePerformance = countsByStaff.entrySet()
                                .stream()
                                .map(entry -> {
                                        long[] c = entry.getValue();
                                        long overdueCnt = c[0];
                                        long lateCnt = c[1];
                                        long onTimeCnt = c[2];
                                        long procCnt = c[3];
                                        long rehandleCnt = c[4];
                                        long resCnt = c[5];
                                        long bottleneckCnt = c[6];
                                        long totalTasks = procCnt + resCnt;
                                        long evaluated = overdueCnt + lateCnt + onTimeCnt;
                                        Double efficiencyRate = evaluated == 0
                                                        ? null
                                                        : Math.round((onTimeCnt * 1000.0) / evaluated) / 10.0;
                                        boolean missed = overdueCnt > 0 || lateCnt > 0;
                                        StaffResponse staffDto = toStaffResponse(staffUsers.get(entry.getKey()));
                                        staffDto.setProcessingCount(procCnt);
                                        applyWorkloadFields(staffDto, activeSnapshot);
                                        return StaffStatisticsResponse.DeadlinePerformanceItem.builder()
                                                        .staff(staffDto)
                                                        .overdueCount(overdueCnt)
                                                        .completedLateCount(lateCnt)
                                                        .completedOnTimeCount(onTimeCnt)
                                                        .processingCount(procCnt)
                                                        .resolvedCount(resCnt)
                                                        .rehandlingCount(rehandleCnt)
                                                        .totalTasks(totalTasks)
                                                        .weightedLoad(staffDto.getWeightedLoad())
                                                        .bottleneckCount(bottleneckCnt)
                                                        .isOverloaded(staffDto.isOverloaded())
                                                        .efficiencyRate(efficiencyRate)
                                                        .hasMissedDeadline(missed)
                                                        .build();
                                })
                                .sorted(Comparator
                                                .comparingLong((StaffStatisticsResponse.DeadlinePerformanceItem item) ->
                                                                item.getOverdueCount() + item.getCompletedLateCount())
                                                .reversed()
                                                .thenComparing(Comparator.comparingLong(
                                                                StaffStatisticsResponse.DeadlinePerformanceItem::getOverdueCount)
                                                                .reversed())
                                                .thenComparing(Comparator.comparingLong(
                                                                StaffStatisticsResponse.DeadlinePerformanceItem::getCompletedOnTimeCount)
                                                                .reversed())
                                                .thenComparing(item -> item.getStaff().getFullName() != null
                                                                ? item.getStaff().getFullName()
                                                                : ""))
                                .collect(Collectors.toList());

                boolean anyStaffMissedDeadline = overdueReports > 0 || completedLate > 0;

                return StaffStatisticsResponse.builder()
                                .selectedYear(selectedMonth.getYear())
                                .selectedMonth(selectedMonth.getMonthValue())
                                .availableMonths(availableMonths)
                                .totalStaff(total)
                                .activeStaff(active)
                                .blockedStaff(blocked)
                                .processingReports(processingReports)
                                .resolved(resolved)
                                .resolvedPrevious(resolvedPrevious)
                                .avgResolutionMinutes(avgMinutes)
                                .avgResolutionMinutesPrevious(avgMinutesPrevious)
                                .workload(workload)
                                .anyStaffMissedDeadline(anyStaffMissedDeadline)
                                .overdueReports(overdueReports)
                                .completedOnTime(completedOnTime)
                                .completedLate(completedLate)
                                .onTimeRate(onTimeRate)
                                .teamAvgWeightedLoad(activeSnapshot.teamAvgWeightedLoad)
                                .overloadedStaffCount(activeSnapshot.overloadedStaffCount)
                                .bottleneckCount(totalBottlenecks)
                                .deadlinePerformance(deadlinePerformance)
                                .build();
        }

        private static final class WorkloadSnapshot {
                final Map<String, Long> processingByStaff = new HashMap<>();
                final Map<String, Long> weightedByStaff = new HashMap<>();
                final Map<String, Long> overdueByStaff = new HashMap<>();
                final Map<String, Map<String, Long>> severityByStaff = new HashMap<>();
                double teamAvgWeightedLoad;
                long overloadedStaffCount;
        }

        private WorkloadSnapshot buildWorkloadSnapshot(
                        List<User> activeStaffs,
                        List<Report> processingReports,
                        LocalDateTime now) {
                WorkloadSnapshot snap = new WorkloadSnapshot();
                for (Report r : processingReports) {
                        User assigned = r.getAssignedStaff();
                        if (assigned == null) {
                                continue;
                        }
                        String sid = assigned.getId();
                        snap.processingByStaff.merge(sid, 1L, Long::sum);
                        snap.weightedByStaff.merge(sid, AnalyticsStatHelper.severityWeight(r.getSeverity()), Long::sum);
                        String sevKey = r.getSeverity() != null ? r.getSeverity().name() : EReportSeverity.low.name();
                        snap.severityByStaff
                                        .computeIfAbsent(sid, k -> new LinkedHashMap<>())
                                        .merge(sevKey, 1L, Long::sum);
                        LocalDateTime deadline = ReportServiceImpl.resolveDeadline(r);
                        if (deadline != null && !deadline.isAfter(now)) {
                                snap.overdueByStaff.merge(sid, 1L, Long::sum);
                        }
                }

                double sum = 0.0;
                for (User u : activeStaffs) {
                        sum += snap.weightedByStaff.getOrDefault(u.getId(), 0L);
                }
                snap.teamAvgWeightedLoad = activeStaffs.isEmpty()
                                ? 0.0
                                : AnalyticsStatHelper.round2(sum / activeStaffs.size());

                long overloadedCnt = 0;
                for (User u : activeStaffs) {
                        long w = snap.weightedByStaff.getOrDefault(u.getId(), 0L);
                        long od = snap.overdueByStaff.getOrDefault(u.getId(), 0L);
                        if (AnalyticsStatHelper.isOverloaded(w, snap.teamAvgWeightedLoad, od)) {
                                overloadedCnt++;
                        }
                }
                snap.overloadedStaffCount = overloadedCnt;
                return snap;
        }

        private void applyWorkloadFields(StaffResponse staff, WorkloadSnapshot snap) {
                if (staff == null) {
                        return;
                }
                String sid = staff.getId();
                long weighted = snap.weightedByStaff.getOrDefault(sid, 0L);
                long overdue = snap.overdueByStaff.getOrDefault(sid, 0L);
                boolean overloaded = AnalyticsStatHelper.isOverloaded(weighted, snap.teamAvgWeightedLoad, overdue);
                Map<String, Long> rawBreakdown = snap.severityByStaff.getOrDefault(sid, Collections.emptyMap());
                Map<String, Long> breakdown = new LinkedHashMap<>();
                for (EReportSeverity s : EReportSeverity.values()) {
                        breakdown.put(s.name(), rawBreakdown.getOrDefault(s.name(), 0L));
                }

                staff.setWeightedLoad(weighted);
                staff.setOverdueCount(overdue);
                staff.setOverloaded(overloaded);
                staff.setAssignmentHint(
                                AnalyticsStatHelper.assignmentHint(weighted, snap.teamAvgWeightedLoad, overloaded));
                staff.setSeverityBreakdown(breakdown);
        }

        private List<StaffStatisticsResponse.AvailableMonthItem> buildAvailableMonths(YearMonth selectedMonth) {
                Set<YearMonth> months = new LinkedHashSet<>();
                List<Object[]> rows = reportRepository.findAssignedAvailableMonths();
                if (rows != null) {
                        for (Object[] row : rows) {
                                if (row != null && row.length >= 2 && row[0] instanceof Number y && row[1] instanceof Number m) {
                                        int yr = y.intValue();
                                        int mo = m.intValue();
                                        if (mo >= 1 && mo <= 12 && yr >= 2000) {
                                                months.add(YearMonth.of(yr, mo));
                                        }
                                }
                        }
                }
                months.add(selectedMonth);
                return months.stream()
                                .sorted(Comparator.reverseOrder())
                                .map(ym -> StaffStatisticsResponse.AvailableMonthItem.builder()
                                                .year(ym.getYear())
                                                .month(ym.getMonthValue())
                                                .label(String.format(Locale.ROOT, "%02d/%04d", ym.getMonthValue(), ym.getYear()))
                                                .build())
                                .collect(Collectors.toList());
        }

        @Override
        @Transactional(readOnly = true)
        public StaffTrendResponse getTrend(String period, Integer year, Integer month) {
                String normalized = TrendBucketHelper.normalizePeriod(period);
                LocalDate today = LocalDate.now();
                YearMonth currentCalendarMonth = YearMonth.from(today);
                YearMonth selectedMonth = (year != null && month != null && month >= 1 && month <= 12)
                                ? YearMonth.of(year, month)
                                : currentCalendarMonth;

                LocalDate anchorEnd = selectedMonth.equals(currentCalendarMonth)
                                ? today
                                : selectedMonth.atEndOfMonth();

                List<LocalDate> bucketDates;
                if ("daily".equals(normalized)) {
                        bucketDates = new ArrayList<>();
                        LocalDate cursor = selectedMonth.atDay(1);
                        while (!cursor.isAfter(anchorEnd)) {
                                bucketDates.add(cursor);
                                cursor = cursor.plusDays(1);
                        }
                        if (bucketDates.isEmpty()) {
                                bucketDates.add(anchorEnd);
                        }
                } else {
                        bucketDates = TrendBucketHelper.buckets(normalized, anchorEnd);
                }

                LocalDateTime from = bucketDates.get(0).atStartOfDay();
                LocalDateTime toExclusive = anchorEnd.plusDays(1).atStartOfDay();

                Map<LocalDate, Long> assigned = TrendBucketHelper.emptyCounts(bucketDates);
                for (Date assignedAt : reportRepository.findAssignedAtBetween(toDate(from), toDate(toExclusive))) {
                        LocalDateTime time = toLocalDateTime(assignedAt);
                        if (time != null) {
                                TrendBucketHelper.increment(assigned, time.toLocalDate(), normalized);
                        }
                }

                Map<LocalDate, Long> resolved = TrendBucketHelper.emptyCounts(bucketDates);
                for (LocalDateTime resolvedTime : reportRepository.findAssignedResolvedTimeByStatusBetween(
                                EReportStatus.processed, from, toExclusive)) {
                        if (resolvedTime != null) {
                                TrendBucketHelper.increment(resolved, resolvedTime.toLocalDate(), normalized);
                        }
                }

                List<StaffTrendResponse.TrendItem> items = bucketDates.stream()
                                .map(date -> StaffTrendResponse.TrendItem.builder()
                                                .date(date)
                                                .assigned(assigned.get(date))
                                                .resolved(resolved.get(date))
                                                .build())
                                .collect(Collectors.toList());

                return StaffTrendResponse.builder()
                                .period(normalized)
                                .items(items)
                                .build();
        }

        private static LocalDateTime toLocalDateTime(Date date) {
                return date == null
                                ? null
                                : LocalDateTime.ofInstant(Instant.ofEpochMilli(date.getTime()), ZoneId.systemDefault());
        }

        private static Date toDate(LocalDateTime time) {
                return Date.from(time.atZone(ZoneId.systemDefault()).toInstant());
        }
}
