package com.vn.smart_space.service.admin;

import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.response.admin.ActivityHistoryResponse;
import com.vn.smart_space.dto.response.admin.AdminOverviewResponse;
import com.vn.smart_space.model.ActivityHistory;
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
                .pendingCount(reportRepository.countByStatus(EReportStatus.pending))
                .processingCount(reportRepository.countByStatus(EReportStatus.processing))
                .build();
    }

    public List<ActivityHistoryResponse> getRecentActivities(int limit, Locale locale) {
        List<ActivityHistory> activities = activityHistoryRepository.findRecentActivities(PageRequest.of(0, limit));
        
        return activities.stream().map(a -> {
            String message = "";
            if (a.getI18nKey() != null && !a.getI18nKey().trim().isEmpty()) {
                String raw = a.getI18nKey().trim();
                Locale activeLocale = locale != null ? locale : Locale.getDefault();
                if (raw.contains("|")) {
                    String[] parts = raw.split("\\|", -1);
                    String key = parts[0];
                    Object[] args = java.util.Arrays.copyOfRange(parts, 1, parts.length);
                    message = messageSource.getMessage(key, args, key, activeLocale);
                } else {
                    int lastSpaceIndex = raw.lastIndexOf(' ');
                    if (lastSpaceIndex != -1) {
                        String prefix = raw.substring(0, lastSpaceIndex).trim();
                        String key = raw.substring(lastSpaceIndex + 1).trim();
                        
                        Object[] args;
                        if ("activity.report.assigned".equals(key)) {
                            String reportTitle = messageSource.getMessage("report.default_title", null, "Phản ánh", activeLocale);
                            String staffName = messageSource.getMessage("staff.default_name", null, "nhân viên", activeLocale);
                            if (a.getTargetId() != null) {
                                var optReport = reportRepository.findById(a.getTargetId());
                                if (optReport.isPresent()) {
                                    var rep = optReport.get();
                                    if (rep.getTitle() != null && !rep.getTitle().trim().isEmpty()) {
                                        reportTitle = rep.getTitle().trim();
                                    }
                                    if (rep.getAssignedStaff() != null && rep.getAssignedStaff().getFullName() != null) {
                                        staffName = rep.getAssignedStaff().getFullName().trim();
                                    }
                                }
                            }
                            args = new Object[]{prefix, reportTitle, staffName};
                        } else {
                            args = new Object[]{prefix};
                        }
                        
                        String translated = messageSource.getMessage(key, args, key, activeLocale);
                        message = prefix.isEmpty() ? translated : (translated.contains(prefix) ? translated : prefix + " " + translated);
                    } else {
                        message = messageSource.getMessage(raw, null, raw, activeLocale);
                    }
                }
                if (message != null) {
                    message = message.replaceAll("\\s*\"?\\{\\d+\\}\"?\\s*", " ").replaceAll("\\s+", " ").trim();
                }
            }
            String actorName = a.getActor() != null ? a.getActor().getFullName() : null;
            String actorAvatar = a.getActor() != null ? a.getActor().getAvatarUrl() : null;
            
            String targetType = (a.getI18nKey() != null && a.getI18nKey().contains("report")) ? "REPORT" : "USER";
            
            return ActivityHistoryResponse.builder()
                    .id(a.getId())
                    .actorName(actorName)
                    .actorAvatarUrl(actorAvatar)
                    .targetId(a.getTargetId())
                    .targetType(targetType)
                    .message(message)
                    .createdAt(a.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());
    }
}
