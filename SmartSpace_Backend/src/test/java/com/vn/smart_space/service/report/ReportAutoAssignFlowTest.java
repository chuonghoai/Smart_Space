package com.vn.smart_space.service.report;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.MessageSource;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.autoassign.AssignmentDecisionSummaryResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.AssignmentDecisionLog;
import com.vn.smart_space.model.AutoAssignConfig;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.autoassign.AutoAssignDispatchResult;
import com.vn.smart_space.service.autoassign.IAutoAssignService;
import com.vn.smart_space.service.autoassign.ReportCreatedEvent;
import com.vn.smart_space.service.conversation.IConversationService;
import com.vn.smart_space.service.delegation.IReportDelegationService;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;

/**
 * Luồng tích hợp giữa ReportServiceImpl và bộ máy phân công tự động: thời điểm kích hoạt,
 * khoá phân công, phạm vi hiển thị phiếu giải trình và điều kiện gửi thông báo fallback.
 */
@ExtendWith(MockitoExtension.class)
class ReportAutoAssignFlowTest {

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

    @InjectMocks ReportServiceImpl reportService;

    private User client() {
        User client = User.builder().email("c@test.com").fullName("Client").role(ERole.client).language("vi").build();
        client.setId("client-1");
        return client;
    }

    private Report pendingReport(String id) {
        Report report = Report.builder()
                .title("Cống nghẹt")
                .status(EReportStatus.pending)
                .severity(EReportSeverity.medium)
                .latitude(10.78)
                .longitude(106.69)
                .user(client())
                .build();
        report.setId(id);
        return report;
    }

    private AutoAssignConfig config(EAutoAssignMode mode) {
        return AutoAssignConfig.builder().mode(mode).build();
    }

    // Description: createReport chỉ phát ReportCreatedEvent; không chạy phân công trong transaction tạo phản ánh.
    @Test
    void createReportPublishesEventInsteadOfAssigningInline() {
        when(userRepository.findById("client-1")).thenReturn(Optional.of(client()));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of());
        when(reportRepository.saveAndFlush(any(Report.class))).thenAnswer(inv -> {
            Report r = inv.getArgument(0);
            r.setId("rep-new");
            return r;
        });
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));

        ReportCreateRequest req = ReportCreateRequest.builder()
                .title("Cống nghẹt")
                .description("Ngập trước cổng")
                .latitude(10.78)
                .longitude(106.69)
                .build();

        ReportDetailResponse res = reportService.createReport(req, "client-1");

        ArgumentCaptor<Object> event = ArgumentCaptor.forClass(Object.class);
        verify(eventPublisher).publishEvent(event.capture());
        assertEquals(new ReportCreatedEvent("rep-new"), event.getValue());
        verifyNoInteractions(autoAssignService);
        assertNull(res.getAutoAssignDecision());
    }

    // Description: Phiếu giải trình (chứa thông tin liên hệ & tọa độ nhân viên) chỉ trả cho Admin.
    @Test
    void decisionSummaryIsOnlyAttachedForAdminViewers() {
        Report report = pendingReport("rep-1");
        when(reportRepository.findById("rep-1")).thenReturn(Optional.of(report));
        AssignmentDecisionSummaryResponse summary = AssignmentDecisionSummaryResponse.builder().id("adl-1").build();
        when(autoAssignService.getDecisionSummary(eq(report), any())).thenReturn(summary);

        assertNull(reportService.getReportDetail("rep-1", "someone", "ROLE_client").getAutoAssignDecision());
        assertNull(reportService.getReportDetail("rep-1", "client-1", "ROLE_client").getAutoAssignDecision());
        assertNull(reportService.getReportDetail("rep-1", "staff-1", "ROLE_staff").getAutoAssignDecision());
        verify(autoAssignService, never()).getDecisionSummary(any(), any());

        assertSame(summary, reportService.getReportDetail("rep-1", "admin-1", "ROLE_admin").getAutoAssignDecision());
    }

    // Description: Nút "Phân công tự động" chỉ áp dụng cho phản ánh đang chờ; khoá phân công lấy trước khi đọc report.
    @Test
    void autoAssignTriggerRejectsNonPendingReportAfterTakingLock() {
        Report processing = pendingReport("rep-2");
        processing.setStatus(EReportStatus.processing);
        when(autoAssignService.lockDispatchConfig()).thenReturn(config(EAutoAssignMode.ASSIST));
        when(reportRepository.findById("rep-2")).thenReturn(Optional.of(processing));

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> reportService.autoAssignReport("rep-2", "admin-1"));
        assertEquals("auto_assign.invalid_report_status", ex.getMessage());

        var order = inOrder(autoAssignService, reportRepository);
        order.verify(autoAssignService).lockDispatchConfig();
        order.verify(reportRepository).findById("rep-2");
        verify(autoAssignService, never()).evaluateManualTrigger(any(), any());
        verify(reportRepository, never()).save(any());
    }

    // Description: Ở ASSIST, phản ánh mới chỉ được gắn log đề xuất; không giao việc, không gửi thông báo fallback.
    @Test
    void assistModeStoresRecommendationWithoutAssigningOrNotifying() {
        Report report = pendingReport("rep-3");
        AutoAssignConfig assist = config(EAutoAssignMode.ASSIST);
        AssignmentDecisionLog recommendation = AssignmentDecisionLog.builder()
                .outcome(EAssignmentOutcome.RECOMMENDED).build();
        recommendation.setId("adl-rec");

        when(autoAssignService.lockDispatchConfig()).thenReturn(assist);
        when(reportRepository.findById("rep-3")).thenReturn(Optional.of(report));
        when(autoAssignService.evaluateOnReportCreated(report, assist)).thenReturn(AutoAssignDispatchResult.builder()
                .assigned(false).mode(EAutoAssignMode.ASSIST).decisionLog(recommendation).build());

        reportService.autoAssignOnReportCreated("rep-3");

        assertEquals("adl-rec", report.getDecisionLogId());
        assertEquals(EReportStatus.pending, report.getStatus());
        assertNull(report.getAssignedStaff());
        verify(reportRepository).save(report);
        verifyNoInteractions(notificationService);
    }

    // Description: Ở AUTO, máy không tìm được ứng viên → báo Admin cần phân công thủ công.
    @Test
    void autoModeFallbackNotifiesAdmins() {
        Report report = pendingReport("rep-4");
        AutoAssignConfig auto = config(EAutoAssignMode.AUTO);
        AssignmentDecisionLog fallback = AssignmentDecisionLog.builder()
                .outcome(EAssignmentOutcome.FALLBACK_PENDING).build();
        fallback.setId("adl-fb");
        User admin = User.builder().fullName("Admin").role(ERole.admin).language("en").build();
        admin.setId("admin-1");

        when(autoAssignService.lockDispatchConfig()).thenReturn(auto);
        when(reportRepository.findById("rep-4")).thenReturn(Optional.of(report));
        when(autoAssignService.evaluateOnReportCreated(report, auto)).thenReturn(AutoAssignDispatchResult.builder()
                .assigned(false).mode(EAutoAssignMode.AUTO).decisionLog(fallback)
                .fallbackReason("auto_assign.fallback.out_of_radius").build());
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of(admin));
        when(messageSource.getMessage(anyString(), any(), anyString(), any())).thenAnswer(inv -> inv.getArgument(0));

        reportService.autoAssignOnReportCreated("rep-4");

        verify(notificationService).createNotification(eq("admin-1"),
                eq("notification.report.auto_assign_fallback.title"), anyString(), anyString(), any());
    }

    // Description: Phản ánh đã được Admin giao trước khi listener chạy thì máy không giao đè.
    @Test
    void skipsReportsNoLongerPending() {
        Report report = pendingReport("rep-5");
        report.setStatus(EReportStatus.processing);
        when(autoAssignService.lockDispatchConfig()).thenReturn(config(EAutoAssignMode.AUTO));
        when(reportRepository.findById("rep-5")).thenReturn(Optional.of(report));

        reportService.autoAssignOnReportCreated("rep-5");

        verify(autoAssignService, never()).evaluateOnReportCreated(any(), any());
        verify(reportRepository, never()).save(any());
    }
}
