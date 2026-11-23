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
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.autoassign.IAutoAssignService;
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
import org.springframework.context.ApplicationEventPublisher;
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
    @Mock ReportCategoryRepository reportCategoryRepository;
    @Mock UserRepository userRepository;
    @Mock SimpMessagingTemplate messagingTemplate;
    @Mock IFCMService fcmService;
    @Mock INotificationService notificationService;
    @Mock ActivityHistoryRepository activityHistoryRepository;
    @Mock MessageSource messageSource;
    @Mock IReportDensityService reportDensityService;
    @Mock IReportDelegationService delegationService;
    @Mock IConversationService conversationService;
    @Mock IAutoAssignService autoAssignService;
    @Mock ApplicationEventPublisher eventPublisher;

    @Mock PositionRepository positionRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock IMailService mailService;

    @InjectMocks ReportServiceImpl reportService;
    @InjectMocks StaffServiceImpl staffService;

    // Test Case ID: SMP-299
    // Description: Xác minh deadlineDaysForSeverity ánh xạ đúng số ngày hạn xử lý cho null/low (3), medium (5), high (7) và critical (10).
    @Test
    void deadlineDaysForSeverityMatchesSpec() {
        assertEquals(3L, ReportServiceImpl.deadlineDaysForSeverity(null));
        assertEquals(3L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.low));
        assertEquals(5L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.medium));
        assertEquals(7L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.high));
        assertEquals(10L, ReportServiceImpl.deadlineDaysForSeverity(EReportSeverity.critical));
    }

    // Test Case ID: SMP-300
    // Description: Xác minh createReport tự động tính hạn xử lý mặc định 3 ngày (mức low) kể từ thời điểm tạo báo cáo.
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

    // Test Case ID: SMP-301
    // Description: Xác minh assignReport cập nhật mức độ nghiêm trọng và tính lại deadline 7 ngày (mức high) tính từ assignedAt.
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

    // Test Case ID: SMP-302
    // Description: Từ chối báo cáo từ trạng thái processing: lưu rejectedReason đã trim, rejectedAt, hủy phân công ủy quyền và gửi 2 thông báo.
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

    // Test Case ID: SMP-303
    // Description: Ném BadRequestException khi từ chối (rejected) một báo cáo đã ở trạng thái processed.
    @Test
    void rejectReportFromProcessedThrowsBadRequest() {
        Report report = Report.builder().title("Done").status(EReportStatus.processed).build();
        report.setId("rep-4");
        when(reportRepository.findById("rep-4")).thenReturn(Optional.of(report));

        assertThrows(BadRequestException.class,
                () -> reportService.updateReportStatus("rep-4", "rejected", "Too late", null));
    }

    // Test Case ID: SMP-304
    // Description: Kiểm tra getStatistics tổng hợp đúng số báo cáo quá hạn, hoàn thành trễ/đúng hạn, tỷ lệ đúng hạn và hiệu suất từng nhân viên.
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
        when(reportRepository.findAssignedAvailableMonths()).thenReturn(List.of());
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
        assertEquals(100.0, stats.getDeadlinePerformance().get(1).getEfficiencyRate());
    }

    // Test Case ID: SMP-305
    // Description: Mở lại báo cáo từ processed về processing: tính lại deadline theo mức độ high, đặt isOverdue không true và thông báo staff cùng admin.
    @Test
    void reopenReportRecalculatesDeadlineAndNotifiesStaffAndAdmins() {
        User staff = User.builder().fullName("Staff A").role(ERole.staff).language("vi").build();
        staff.setId("s-reopen");
        User admin = User.builder().fullName("Admin A").role(ERole.admin).language("en").build();
        admin.setId("a-1");

        LocalDateTime oldDeadline = LocalDateTime.now().minusDays(2);
        Report report = Report.builder()
                .title("Nắp cống vỡ")
                .status(EReportStatus.processed)
                .severity(EReportSeverity.high)
                .assignedStaff(staff)
                .isReviewResolved(false)
                .deadline(oldDeadline)
                .build();
        report.setId("rep-reopen");

        when(reportRepository.findById("rep-reopen")).thenReturn(Optional.of(report));
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));
        when(reportRepository.countStaffReportsGroupByStatus("s-reopen")).thenReturn(List.of());
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin));

        LocalDateTime before = LocalDateTime.now();
        ReportDetailResponse res = reportService.updateReportStatus("rep-reopen", "processing", null);

        assertEquals("processing", res.getStatus());
        assertNotNull(report.getDeadline());
        assertTrue(report.getDeadline().isAfter(before.plusDays(6)));
        assertFalse(Boolean.TRUE.equals(res.getIsOverdue()));
        verify(notificationService, times(2)).createNotification(anyString(), any(), any(), anyString(), any());
    }

    // Test Case ID: SMP-306
    // Description: Kiểm tra isReportOverdue và calculateRemainingDays phân biệt chính xác báo cáo processed sau hạn (overdue=true) và đúng hạn.
    @Test
    void overdueRemainsTrueWhenProcessedAfterDeadline() {
        LocalDateTime dl = LocalDateTime.now().minusDays(2);
        Report processedLate = Report.builder()
                .status(EReportStatus.processed)
                .deadline(dl)
                .resolvedAt(Date.from(dl.plusHours(5).atZone(ZoneId.systemDefault()).toInstant()))
                .build();
        assertTrue(ReportServiceImpl.isReportOverdue(processedLate, LocalDateTime.now()));
        assertNull(ReportServiceImpl.calculateRemainingDays(processedLate, LocalDateTime.now()));

        Report processedOnTime = Report.builder()
                .status(EReportStatus.processed)
                .deadline(dl)
                .resolvedAt(Date.from(dl.minusHours(1).atZone(ZoneId.systemDefault()).toInstant()))
                .build();
        assertFalse(ReportServiceImpl.isReportOverdue(processedOnTime, LocalDateTime.now()));
    }

    // Test Case ID: SMP-307
    // Description: Đảm bảo báo cáo legacy processed có resolvedAt=null không bị tính nhầm trễ hạn khi updatedAt bị đổi sau thời điểm review.
    @Test
    void staffWithoutLateReportsNotMarkedMissedWhenUpdatedAtMutatedAfterReview() {
        User staff = User.builder().fullName("Clean Staff").role(ERole.staff).build();
        staff.setId("s-clean");

        Report legacyOnTime = Report.builder()
                .status(EReportStatus.processed)
                .assignedStaff(staff)
                .deadline(LocalDateTime.now().minusDays(1))
                .resolvedAt(null)
                .build();
        // updatedAt mutated today (after deadline), resolvedAt null -> must NOT trigger false Trễ hạn
        legacyOnTime.setUpdatedAt(LocalDateTime.now());

        when(userRepository.countByRole(ERole.staff)).thenReturn(1L);
        when(userRepository.countByRoleAndStatus(eq(ERole.staff), any())).thenReturn(1L, 0L);
        when(reportRepository.findAssignedAvailableMonths()).thenReturn(List.of());
        when(reportRepository.findAssignedByStatusInWithStaff(anyList())).thenReturn(List.of(legacyOnTime));
        when(userRepository.findByRole(ERole.staff)).thenReturn(List.of(staff));

        StaffStatisticsResponse stats = staffService.getStatistics(LocalDateTime.now().getYear(), LocalDateTime.now().getMonthValue());
        assertFalse(stats.isAnyStaffMissedDeadline());
        assertEquals(0L, stats.getCompletedLate());
        assertEquals(1L, stats.getCompletedOnTime());
        assertFalse(stats.getDeadlinePerformance().get(0).isHasMissedDeadline());
        assertEquals(100.0, stats.getDeadlinePerformance().get(0).getEfficiencyRate());
    }
}
