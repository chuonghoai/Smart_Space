package com.vn.smart_space.service.category;

import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.request.admin.CategoryRequest;
import com.vn.smart_space.dto.request.admin.CreateStaffRequest;
import com.vn.smart_space.dto.request.admin.UpdateStaffRequest;
import com.vn.smart_space.dto.request.report.ReportCreateRequest;
import com.vn.smart_space.dto.response.admin.StaffResponse;
import com.vn.smart_space.dto.response.category.CategoryResponse;
import com.vn.smart_space.dto.response.report.ReportDetailResponse;
import com.vn.smart_space.exception.BadRequestException;
import com.vn.smart_space.model.Position;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.ReportCategory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.ActivityHistoryRepository;
import com.vn.smart_space.repository.PositionRepository;
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;
import com.vn.smart_space.service.auth.IAuthenticationService;
import com.vn.smart_space.service.autoassign.IAutoAssignService;
import com.vn.smart_space.service.conversation.IConversationService;
import com.vn.smart_space.service.delegation.IReportDelegationService;
import com.vn.smart_space.service.mail.IMailService;
import com.vn.smart_space.service.notification.IFCMService;
import com.vn.smart_space.service.notification.INotificationService;
import com.vn.smart_space.service.report.IReportDensityService;
import com.vn.smart_space.service.report.ReportServiceImpl;
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

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReportCategoryAndStaffLocationTest {

    @Mock ReportCategoryRepository categoryRepository;
    @Mock PositionRepository positionRepository;
    @Mock ReportRepository reportRepository;
    @Mock UserRepository userRepository;
    @Mock ActivityHistoryRepository activityHistoryRepository;
    @Mock PasswordEncoder passwordEncoder;
    @Mock IMailService mailService;
    @Mock IAuthenticationService authenticationService;
    @Mock SimpMessagingTemplate messagingTemplate;
    @Mock IFCMService fcmService;
    @Mock INotificationService notificationService;
    @Mock MessageSource messageSource;
    @Mock IReportDensityService reportDensityService;
    @Mock IReportDelegationService delegationService;
    @Mock IConversationService conversationService;
    @Mock IAutoAssignService autoAssignService;
    @Mock ApplicationEventPublisher eventPublisher;

    @InjectMocks ReportCategoryServiceImpl categoryService;
    @InjectMocks StaffServiceImpl staffService;
    @InjectMocks ReportServiceImpl reportService;

    @Test
    void createCategoryNormalizesCodeAndMapsActivePositions() {
        Position p1 = Position.builder().code("ELECTRIC").name("Kỹ thuật điện").isActive(true).build();
        p1.setId("pos-1");

        when(categoryRepository.existsByCodeIgnoreCase("LIGHTING_ELECTRIC")).thenReturn(false);
        when(positionRepository.findAllById(List.of("pos-1"))).thenReturn(List.of(p1));
        when(categoryRepository.save(any(ReportCategory.class))).thenAnswer(inv -> {
            ReportCategory c = inv.getArgument(0);
            c.setId("cat-1");
            return c;
        });

        CategoryRequest req = new CategoryRequest(
                "lighting electric",
                "Chiếu sáng & Điện",
                "Lighting & Electricity",
                "Mô tả",
                "bolt",
                "high",
                true,
                2,
                List.of("pos-1"));

        CategoryResponse res = categoryService.createCategory(req, null);

        assertEquals("LIGHTING_ELECTRIC", res.getCode());
        assertEquals("high", res.getDefaultSeverity());
        assertEquals(1, res.getPositions().size());
        assertEquals("pos-1", res.getPositions().get(0).getId());
    }

    @Test
    void deleteCategoryInUseThrowsBadRequest() {
        ReportCategory cat = ReportCategory.builder().code("ENV").nameVi("Môi trường").nameEn("Environment").build();
        cat.setId("cat-1");
        when(categoryRepository.findById("cat-1")).thenReturn(Optional.of(cat));
        when(reportRepository.countByCategoryId("cat-1")).thenReturn(3L);

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> categoryService.deleteCategory("cat-1", null));
        assertEquals("category.in_use", ex.getMessage());
        verify(categoryRepository, never()).delete(any());
    }

    @Test
    void createStaffRejectsPartialOrOutOfRangeCoordinates() {
        when(userRepository.existsByEmailAndRole("s@test.com", ERole.staff)).thenReturn(false);
        when(passwordEncoder.encode(any())).thenReturn("encoded");

        CreateStaffRequest missingPair = new CreateStaffRequest(
                "Staff A", "s@test.com", null, null, null, null, null,
                10.8, null, "District 1");
        assertThrows(BadRequestException.class, () -> staffService.createStaff(missingPair, null));

        CreateStaffRequest invalidLat = new CreateStaffRequest(
                "Staff A", "s@test.com", null, null, null, null, null,
                95.0, 106.7, "District 1");
        assertThrows(BadRequestException.class, () -> staffService.createStaff(invalidLat, null));
    }

    @Test
    void updateStaffSavesAndClearsBaseLocation() {
        User staff = User.builder()
                .fullName("Staff A")
                .email("s@test.com")
                .role(ERole.staff)
                .status(EUserStatus.active)
                .language("vi")
                .build();
        staff.setId("staff-1");

        when(userRepository.findById("staff-1")).thenReturn(Optional.of(staff));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UpdateStaffRequest setLoc = new UpdateStaffRequest(
                "Staff A", null, null, null, null, null,
                10.7769, 106.7009, "  Quận 1, TP.HCM  ", false);
        StaffResponse updated = staffService.updateStaff("staff-1", setLoc, null);

        assertEquals(10.7769, updated.getBaseLatitude());
        assertEquals(106.7009, updated.getBaseLongitude());
        assertEquals("Quận 1, TP.HCM", updated.getBaseAddress());

        UpdateStaffRequest clearLoc = new UpdateStaffRequest(
                "Staff A", null, null, null, null, null,
                null, null, null, true);
        StaffResponse cleared = staffService.updateStaff("staff-1", clearLoc, null);

        assertNull(cleared.getBaseLatitude());
        assertNull(cleared.getBaseLongitude());
        assertNull(cleared.getBaseAddress());
    }

    @Test
    void createReportAppliesCategoryAndDefaultSeverity() {
        ReportCategory category = ReportCategory.builder()
                .code("WATER_DRAINAGE")
                .nameVi("Cấp thoát nước")
                .nameEn("Water & Drainage")
                .defaultSeverity(EReportSeverity.high)
                .isActive(true)
                .build();
        category.setId("cat-water");

        User client = User.builder().email("c@test.com").fullName("Client").role(ERole.client).language("vi").build();
        client.setId("client-1");

        when(categoryRepository.findById("cat-water")).thenReturn(Optional.of(category));
        when(userRepository.findById("client-1")).thenReturn(Optional.of(client));
        when(userRepository.findByRole(ERole.admin)).thenReturn(List.of());
        when(reportRepository.saveAndFlush(any(Report.class))).thenAnswer(inv -> {
            Report r = inv.getArgument(0);
            r.setId("rep-cat-1");
            r.setCreatedAt(LocalDateTime.of(2026, 11, 22, 10, 0));
            return r;
        });
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));

        ReportCreateRequest req = ReportCreateRequest.builder()
                .title("Cống nghẹt")
                .description("Ngập nước trước cổng")
                .latitude(10.8)
                .longitude(106.7)
                .categoryId("cat-water")
                .build();

        ReportDetailResponse res = reportService.createReport(req, "client-1");

        assertEquals("cat-water", res.getCategoryId());
        assertEquals("WATER_DRAINAGE", res.getCategoryCode());
        assertEquals("high", res.getSeverity());
        assertEquals(LocalDateTime.of(2026, 11, 29, 10, 0), LocalDateTime.parse(res.getDeadline()));
    }

    private Report pendingReportWithCategory(ReportCategory category, User owner) {
        Report report = new Report();
        report.setId("rep-edit-1");
        report.setTitle("Cống nghẹt");
        report.setStatus(EReportStatus.pending);
        report.setSeverity(EReportSeverity.medium);
        report.setCategory(category);
        report.setUser(owner);
        return report;
    }

    @Test
    void updateReportKeepsInactiveCategoryWhenUnchanged() {
        ReportCategory inactive = ReportCategory.builder()
                .code("NOISE_LEGACY").nameVi("Tiếng ồn").nameEn("Noise").isActive(false).build();
        inactive.setId("cat-legacy");
        User client = User.builder().email("c@test.com").fullName("Client").role(ERole.client).language("vi").build();
        client.setId("client-1");

        Report report = pendingReportWithCategory(inactive, client);
        when(reportRepository.findById("rep-edit-1")).thenReturn(Optional.of(report));
        when(reportRepository.save(any(Report.class))).thenAnswer(inv -> inv.getArgument(0));

        ReportCreateRequest req = ReportCreateRequest.builder()
                .title("Cống nghẹt (cập nhật)")
                .categoryId("cat-legacy")
                .build();

        ReportDetailResponse res = reportService.updateReport("rep-edit-1", req, "client-1");

        assertEquals("cat-legacy", res.getCategoryId());
        assertEquals("Cống nghẹt (cập nhật)", res.getTitle());
        verify(categoryRepository, never()).findById(any());
    }

    @Test
    void updateReportRejectsSwitchingToInactiveCategory() {
        ReportCategory current = ReportCategory.builder()
                .code("ENV").nameVi("Môi trường").nameEn("Environment").isActive(true).build();
        current.setId("cat-env");
        ReportCategory inactive = ReportCategory.builder()
                .code("NOISE_LEGACY").nameVi("Tiếng ồn").nameEn("Noise").isActive(false).build();
        inactive.setId("cat-legacy");
        User client = User.builder().email("c@test.com").fullName("Client").role(ERole.client).language("vi").build();
        client.setId("client-1");

        when(reportRepository.findById("rep-edit-1"))
                .thenReturn(Optional.of(pendingReportWithCategory(current, client)));
        when(categoryRepository.findById("cat-legacy")).thenReturn(Optional.of(inactive));

        ReportCreateRequest req = ReportCreateRequest.builder().categoryId("cat-legacy").build();

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> reportService.updateReport("rep-edit-1", req, "client-1"));
        assertEquals("category.inactive", ex.getMessage());
        verify(reportRepository, never()).save(any());
    }
}
