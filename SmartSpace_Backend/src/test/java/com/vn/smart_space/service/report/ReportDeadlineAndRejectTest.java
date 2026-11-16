package com.vn.smart_space.service.report;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.admin.ReportAssignRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.StaffStatisticsResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.PositionRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.conversation.IConversationService;
import com.vn.smart_space.service.delegation.IReportDelegationService;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import com.vn.smart_space.service.staff.StaffServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReportDeadlineAndRejectTest {

    @Mock ReportRepository reportRepository;
    @Mock UserRepository userRepository;
    @Mock SimpMessagingTemplate messagingTemplate;
    @Mock IFCMService fcmService;
    @Mock INotificationService notificationService;
    @Mock ActivityHistoryRepository activityHistoryRepository;
    @Mock MessageSource messageSource;
    @Mock IReportDensityService reportDensityService;
    @Mock IReportDelegationService delegationService;
    @Mock IConversationService conversationService;

    @Mock PositionRepository positionRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock IMailService mailService;

    @InjectMocks ReportServiceImpl reportService;
    @InjectMocks StaffServiceImpl staffService;

    @Test
    void deadlineDaysForSeverityMatchesSpec() {
        assertEquals(3L, ReportServiceImpl.deadlineDaysForSeverity(null));
        assertEquals(3L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.low));
        assertEquals(5L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.medium));
        assertEquals(7L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.high));
        assertEquals(10L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.critical));
    }

    @Test
    void createReportSetsDefaultLow3DayDeadline() {
        User client = User.builder().email("c@test.com").fullName("Client").role(ERole.client).language("vi").build();
        client.setId("client-1");
        when(userRepository.findById("client-1")).thenReturn(Optional.of(client));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of());
        when(reportRepository.saveAndFlush(any(Report.class))).thenAnswer(inv -> {
            Report r = inv.getArgument(0);
            r.setId("rep-1");
            r.setCreatedAt(LocalDateTime.of(2026, 5, 1, 10, 0));
            return r;
        });
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));

        ReportCreateRequest req = new ReportCreateRequest();
        req.setTitle("Đèn hỏng");
        req.setDescription("Hỏng ngoài cổng");
        req.setLatitude(10.8);
        req.setLongitude(106.7);

        ReportDetailResponse res = reportService.createReport(req, "client-1");

        assertNotNull(res.getDeadline());
        assertEquals(LocalDateTime.of(2026, 5, 4, 10, 0), LocalDateTime.parse(res.getDeadline()));
    }

    @Test
    void assignReportRecalculatesDeadlineFromAssignedAtAndSeverity() {
        User staff = User.builder().email("s@test.com").fullName("Staff A").role(ERole.staff).language("vi").build();
        staff.setId("staff-1");
        Report existing = Report.builder()
                .title("Nước rò rỉ")
                .status(EReportStatus.pending)
                .severity(EReportSeverity.low)
                .build();
        existing.setId("rep-2");
        existing.setCreatedAt(LocalDateTime.of(2026, 5, 1, 9, 0));

        when(reportRepository.findById("rep-2")).thenReturn(Optional.of(existing));
        when(userRepository.findById("staff-1")).thenReturn(Optional.of(staff));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of());
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));

        ReportAssignRequest req = new ReportAssignRequest();
        req.setStaffId("staff-1");
        req.setSeverity("high");

        ReportDetailResponse res = reportService.assignReport("rep-2", req, null);

        assertEquals("high", res.getSeverity());
        assertNotNull(existing.getAssignedAt());
        assertNotNull(existing.getDeadline());
        LocalDateTime assignedLdt = existing.getAssignedAt().toInstant()
                .atZone(ZoneId.systemDefault()).toLocalDateTime();
        assertEquals(7L, Duration.between(assignedLdt, existing.getDeadline()).toDays());
    }

    @Test
    void rejectReportFromProcessingStoresReasonAndNotifies() {
        User client = User.builder().fullName("Client").role(ERole.client).language("en").build();
        client.setId("c1");
        User staff = User.builder().fullName("Staff").role(ERole.staff).language("vi").build();
        staff.setId("s1");

        Report report = Report.builder()
                .title("Spam test")
                .status(EReportStatus.processing)
                .user(client)
                .assignedStaff(staff)
                .build();
        report.setId("rep-3");
        report.setCreatedAt(LocalDateTime.now().minusDays(1));

        when(reportRepository.findById("rep-3")).thenReturn(Optional.of(report));
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));
        when(reportRepository.countStaffReportsGroupByStatus("s1")).thenReturn(List.of());

        ReportDetailResponse res = reportService.updateReportStatus("rep-3", "rejected", "  Trùng lặp phản ánh  ", null);

        assertEquals("rejected", res.getStatus());
        assertEquals("Trùng lặp phản ánh", res.getRejectedReason());
        assertNotNull(res.getRejectedAt());
        verify(notificationService, times(2)).createNotification(anyString(), any(), any(), anyString(), any());
        verify(delegationService).onReportUnassigned(report);
    }

    @Test
    void rejectReportFromProcessedThrowsBadRequest() {
        Report report = Report.builder().title("Done").status(EReportStatus.processed).build();
        report.setId("rep-4");
        when(reportRepository.findById("rep-4")).thenReturn(Optional.of(report));

        assertThrows(BadRequestException.class,
                () -> reportService.updateReportStatus("rep-4", "rejected", "Too late", null));
    }

    @Test
    void staffStatisticsComputesDeadlinePerformance() {
        User staffLate = User.builder().fullName("Late Staff").role(ERole.staff).build();
        staffLate.setId("s-late");
        User staffOnTime = User.builder().fullName("Timely Staff").role(ERole.staff).build();
        staffOnTime.setId("s-ok");

        Report overdueProcessing = Report.builder()
                .status(EReportStatus.processing)
                .assignedStaff(staffLate)
                .deadline(LocalDateTime.now().minusDays(2))
                .build();
        Report completedLate = Report.builder()
                .status(EReportStatus.processed)
                .assignedStaff(staffLate)
                .deadline(LocalDateTime.now().minusDays(5))
                .resolvedAt(Date.from(LocalDateTime.now().minusDays(2).atZone(ZoneId.systemDefault()).toInstant()))
                .build();
        Report completedOnTime = Report.builder()
                .status(EReportStatus.processed)
                .assignedStaff(staffOnTime)
                .deadline(LocalDateTime.now().plusDays(1))
                .resolvedAt(new Date())
                .build();

        when(userRepository.countByRole(ERole.staff)).thenReturn(2L);
        when(userRepository.countByRoleAndStatus(eq(ERole.staff), any())).thenReturn(2L, 0L);
        when(reportRepository.countByStatus(EReportStatus.processing)).thenReturn(1L);
        when(reportRepository.countAssignedByStatusUpdatedBetween(eq(EReportStatus.processed), any(), any())).thenReturn(2L, 0L);
        when(reportRepository.findAssignedAndUpdatedAtByStatusBetween(eq(EReportStatus.processed), any(), any())).thenReturn(List.of());
        when(reportRepository.findTopAssigneesByStatus(eq(EReportStatus.processing), any())).thenReturn(List.of());
        when(reportRepository.findAssignedByStatusInWithStaff(anyList()))
                .thenReturn(List.of(overdueProcessing, completedLate, completedOnTime));
        when(userRepository.findByRole(ERole.staff)).thenReturn(List.of(staffLate, staffOnTime));

        StaffStatisticsResponse stats = staffService.getStatistics();

        assertTrue(stats.isAnyStaffMissedDeadline());
        assertEquals(1L, stats.getOverdueReports());
        assertEquals(1L, stats.getCompletedLate());
        assertEquals(1L, stats.getCompletedOnTime());
        assertEquals(50.0, stats.getOnTimeRate());
        assertEquals(2, stats.getDeadlinePerformance().size());
        assertEquals("s-late", stats.getDeadlinePerformance().get(0).getStaff().getId());
        assertTrue(stats.getDeadlinePerformance().get(0).isHasMissedDeadline());
        assertFalse(stats.getDeadlinePerformance().get(1).isHasMissedDeadline());
    }
}
