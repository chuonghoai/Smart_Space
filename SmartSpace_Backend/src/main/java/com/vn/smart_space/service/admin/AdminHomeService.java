package com.vn.smart_space.service.admin;

import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.response.admin.ActivityHistoryResponse;
import com.vn.smart_space.dto.response.admin.AdminOverviewResponse;
import com.vn.smart_space.dto.response.admin.RecentReportResponse;
import com.vn.smart_space.model.ActivityHistory;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.context.MessageSource;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AdminHomeService {

    UserRepository userRepository;
    ReportRepository reportRepository;
    ActivityHistoryRepository activityHistoryRepository;
    MessageSource messageSource;

    public AdminOverviewResponse getOverview() {
        return AdminOverviewResponse.builder()
                .userCount(userRepository.countByRole(ERole.client))
                .staffCount(userRepository.countByRole(ERole.staff))
                .adminCount(userRepository.countByRole(ERole.admin))
                .issueCount(reportRepository.countByStatusIn(List.of(EReportStatus.pending, EReportStatus.processing)))
                .build();
    }

    public List<ActivityHistoryResponse> getRecentActivities(int limit, Locale locale) {
        List<ActivityHistory> activities = activityHistoryRepository.findRecentActivities(PageRequest.of(0, limit));
        
        return activities.stream().map(a -> {
            String message = "";
            if (a.getI18nKey() != null && !a.getI18nKey().trim().isEmpty()) {
                String raw = a.getI18nKey().trim();
                int lastSpaceIndex = raw.lastIndexOf(' ');
                if (lastSpaceIndex != -1) {
                    String prefix = raw.substring(0, lastSpaceIndex).trim();
                    String key = raw.substring(lastSpaceIndex + 1).trim();
                    String translated = messageSource.getMessage(key, null, key, locale != null ? locale : Locale.getDefault());
                    message = prefix.isEmpty() ? translated : prefix + " " + translated;
                } else {
                    message = messageSource.getMessage(raw, null, raw, locale != null ? locale : Locale.getDefault());
                }
            }
            String actorName = a.getActor() != null ? a.getActor().getFullName() : null;
            String actorAvatar = a.getActor() != null ? a.getActor().getAvatarUrl() : null;
            
            return ActivityHistoryResponse.builder()
                    .id(a.getId())
                    .actorName(actorName)
                    .actorAvatarUrl(actorAvatar)
                    .targetId(a.getTargetId())
                    .message(message)
                    .createdAt(a.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());
    }

    public List<RecentReportResponse> getRecentReports(String tab, int limit) {
        List<EReportStatus> statuses;
        if ("all".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.pending, EReportStatus.processing);
        } else if ("pending".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.pending);
        } else if ("processing".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.processing);
        } else if ("resolved".equalsIgnoreCase(tab)) {
            statuses = List.of(EReportStatus.processed);
        } else {
            statuses = List.of(EReportStatus.pending, EReportStatus.processing);
        }

        List<Report> reports = reportRepository.findByStatusInOrderByCreatedAtDesc(statuses, PageRequest.of(0, limit));
        
        return reports.stream().map(r -> {
            User staff = r.getAssignedStaff();
            return RecentReportResponse.builder()
                    .id(r.getId())
                    .title(r.getTitle())
                    .status(r.getStatus())
                    .severity(r.getSeverity())
                    .createdAt(r.getCreatedAt())
                    .imageUrl(r.getImageUrl())
                    .assignedStaffName(staff != null ? staff.getFullName() : null)
                    .assignedStaffAvatarUrl(staff != null ? staff.getAvatarUrl() : null)
                    .build();
        }).collect(Collectors.toList());
    }
}
