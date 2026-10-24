package com.vn.smart_space.service.admin;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.response.admin.AdminUserDetailResponse;
import com.vn.smart_space.dto.response.admin.AdminUserResponse;
import com.vn.smart_space.dto.response.admin.AdminUserStatisticsResponse;
import com.vn.smart_space.dto.response.admin.AdminUserTrendResponse;
import com.vn.smart_space.exception.ResourceNotFoundException;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.utils.TrendBucketHelper;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminUserServiceImpl implements IAdminUserService {

        static final int MAX_PAGE_SIZE = 50;
        static final int STATS_WINDOW_DAYS = 30;
        static final int TOP_REPORTER_LIMIT = 5;
        static final int RECENT_REPORT_LIMIT = 5;

        UserRepository userRepository;
        ReportRepository reportRepository;

        @Override
        @Transactional(readOnly = true)
        public PageResponse<AdminUserResponse> getUsersPaged(int page, int size, String search, String sort) {
                // 1. Normalize input
                int safePage = Math.max(page, 1);
                int safeSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
                String searchParam = (search != null && !search.trim().isEmpty()) ? search.trim() : null;

                // 2. Query users with pagination
                Pageable pageable = PageRequest.of(safePage - 1, safeSize, resolveSort(sort));
                Page<User> userPage = userRepository.searchByRole(ERole.client, searchParam, pageable);
                List<User> users = userPage.getContent();

                // 3. Batch query: số báo cáo công khai của từng user (tránh N+1)
                Map<String, Long> reportCountMap = Collections.emptyMap();
                if (!users.isEmpty()) {
                        List<String> userIds = users.stream().map(User::getId).collect(Collectors.toList());
                        reportCountMap = reportRepository.countPublicReportsByUserIdIn(userIds).stream()
                                        .collect(Collectors.toMap(
                                                        row -> (String) row[0],
                                                        row -> (Long) row[1]));
                }

                // 4. Map User → AdminUserResponse
                final Map<String, Long> countMap = reportCountMap;
                List<AdminUserResponse> content = users.stream()
                                .map(u -> AdminUserResponse.builder()
                                                .id(u.getId())
                                                .fullName(u.getFullName())
                                                .email(u.getEmail())
                                                .phoneNumber(u.getPhone())
                                                .avatarUrl(u.getAvatarUrl())
                                                .status(u.getStatus() != null ? u.getStatus().name() : null)
                                                .reportCount(countMap.getOrDefault(u.getId(), 0L))
                                                .createdAt(u.getCreatedAt())
                                                .build())
                                .collect(Collectors.toList());

                return PageResponse.<AdminUserResponse>builder()
                                .currentPage(safePage)
                                .pageSize(safeSize)
                                .totalPages(userPage.getTotalPages())
                                .totalElements(userPage.getTotalElements())
                                .content(content)
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public AdminUserStatisticsResponse getStatistics() {
                LocalDateTime now = LocalDateTime.now();
                LocalDateTime currentFrom = now.minusDays(STATS_WINDOW_DAYS);
                LocalDateTime previousFrom = currentFrom.minusDays(STATS_WINDOW_DAYS);

                long totalUsers = userRepository.countByRole(ERole.client);
                long newUsers = userRepository.countByRoleAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                                ERole.client, currentFrom, now);
                long newUsersPrevious = userRepository.countByRoleAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                                ERole.client, previousFrom, currentFrom);
                long activeReporters = reportRepository.countDistinctReportersSince(ERole.client, currentFrom);
                long reports = reportRepository.countByReporterRoleBetween(ERole.client, currentFrom, now);
                long reportsPrevious = reportRepository.countByReporterRoleBetween(
                                ERole.client, previousFrom, currentFrom);

                List<AdminUserStatisticsResponse.TopReporter> topReporters = reportRepository
                                .findTopPublicReporters(ERole.client, Limit.of(TOP_REPORTER_LIMIT)).stream()
                                .map(row -> AdminUserStatisticsResponse.TopReporter.builder()
                                                .userId((String) row[0])
                                                .fullName((String) row[1])
                                                .avatarUrl((String) row[2])
                                                .reportCount((Long) row[3])
                                                .build())
                                .collect(Collectors.toList());

                return AdminUserStatisticsResponse.builder()
                                .totalUsers(totalUsers)
                                .newUsers(newUsers)
                                .newUsersPrevious(newUsersPrevious)
                                .activeReporters(activeReporters)
                                .reports(reports)
                                .reportsPrevious(reportsPrevious)
                                .topReporters(topReporters)
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public AdminUserTrendResponse getRegistrationTrend(String period) {
                String normalized = TrendBucketHelper.normalizePeriod(period);
                List<LocalDate> bucketDates = TrendBucketHelper.buckets(normalized, LocalDate.now());
                Map<LocalDate, Long> buckets = TrendBucketHelper.emptyCounts(bucketDates);

                // Gom nhóm thời điểm đăng ký vào bucket
                List<LocalDateTime> createdAts = userRepository.findCreatedAtByRoleSince(
                                ERole.client, bucketDates.get(0).atStartOfDay());
                for (LocalDateTime createdAt : createdAts) {
                        if (createdAt != null) {
                                TrendBucketHelper.increment(buckets, createdAt.toLocalDate(), normalized);
                        }
                }

                List<AdminUserTrendResponse.TrendItem> items = new ArrayList<>(bucketDates.size());
                buckets.forEach((date, count) -> items.add(AdminUserTrendResponse.TrendItem.builder()
                                .date(date)
                                .count(count)
                                .build()));

                return AdminUserTrendResponse.builder()
                                .period(normalized)
                                .items(items)
                                .build();
        }

        @Override
        @Transactional(readOnly = true)
        public AdminUserDetailResponse getUserDetail(String userId) {
                // Chỉ trả về user role client: endpoint này không dùng để tra cứu admin/staff
                User user = userRepository.findByIdAndRole(userId, ERole.client)
                                .orElseThrow(() -> new ResourceNotFoundException("user.not_found"));

                // 1. Thống kê báo cáo công khai theo trạng thái
                Map<EReportStatus, Long> byStatus = new EnumMap<>(EReportStatus.class);
                for (Object[] row : reportRepository.countPublicReportsByUserGroupByStatus(user.getId())) {
                        byStatus.put((EReportStatus) row[0], (Long) row[1]);
                }
                long total = byStatus.values().stream().mapToLong(Long::longValue).sum();

                AdminUserDetailResponse.ReportStats stats = AdminUserDetailResponse.ReportStats.builder()
                                .total(total)
                                .pending(byStatus.getOrDefault(EReportStatus.pending, 0L))
                                .processing(byStatus.getOrDefault(EReportStatus.processing, 0L))
                                .processed(byStatus.getOrDefault(EReportStatus.processed, 0L))
                                .rejected(byStatus.getOrDefault(EReportStatus.rejected, 0L))
                                .build();

                // 2. Báo cáo công khai gần nhất
                List<AdminUserDetailResponse.RecentReport> recentReports = reportRepository
                                .findRecentPublicReportsByUser(user.getId(), Limit.of(RECENT_REPORT_LIMIT)).stream()
                                .map(r -> AdminUserDetailResponse.RecentReport.builder()
                                                .id(r.getId())
                                                .title(r.getTitle())
                                                .status(r.getStatus())
                                                .severity(r.getSeverity())
                                                .createdAt(r.getCreatedAt())
                                                .build())
                                .collect(Collectors.toList());

                return AdminUserDetailResponse.builder()
                                .id(user.getId())
                                .fullName(user.getFullName())
                                .email(user.getEmail())
                                .phoneNumber(user.getPhone())
                                .avatarUrl(user.getAvatarUrl())
                                .gender(user.getGender() != null ? user.getGender().name() : null)
                                .dateOfBirth(user.getDateOfBirth())
                                .language(user.getLanguage())
                                .status(user.getStatus() != null ? user.getStatus().name() : null)
                                .createdAt(user.getCreatedAt())
                                .reportStats(stats)
                                .recentReports(recentReports)
                                .build();
        }

        /** "newest" (mặc định) | "oldest" | "name". Giá trị lạ → newest. */
        private Sort resolveSort(String sort) {
                if ("oldest".equalsIgnoreCase(sort)) {
                        return Sort.by(Sort.Direction.ASC, "createdAt");
                }
                if ("name".equalsIgnoreCase(sort)) {
                        return Sort.by(Sort.Direction.ASC, "fullName").and(Sort.by(Sort.Direction.DESC, "createdAt"));
                }
                return Sort.by(Sort.Direction.DESC, "createdAt");
        }
}
