package com.vn.smart_space.service.autoassign;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Date;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.data.domain.Pageable;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.response.autoassign.AssignmentDecisionSummaryResponse;
import com.vn.smart_space.dto.response.autoassign.AutoAssignRecommendationResponse;
import com.vn.smart_space.dto.response.autoassign.StaffCandidateScoreResponse;
import com.vn.smart_space.model.AssignmentDecisionLog;
import com.vn.smart_space.model.AutoAssignConfig;
import com.vn.smart_space.model.Position;
import com.vn.smart_space.model.Report;
import com.vn.smart_space.model.ReportCategory;
import com.vn.smart_space.model.User;
import com.vn.smart_space.repository.AssignmentDecisionLogRepository;
import com.vn.smart_space.repository.AutoAssignConfigRepository;
import com.vn.smart_space.repository.ReportCategoryRepository;
import com.vn.smart_space.repository.ReportRepository;
import com.vn.smart_space.repository.UserRepository;

@ExtendWith(MockitoExtension.class)
class AutoAssignServiceTest {

    @Mock
    AutoAssignConfigRepository autoAssignConfigRepository;
    @Mock
    AssignmentDecisionLogRepository decisionLogRepository;
    @Mock
    ReportCategoryRepository reportCategoryRepository;
    @Mock
    UserRepository userRepository;
    @Mock
    ReportRepository reportRepository;
    @Mock
    MessageSource messageSource;

    AutoAssignServiceImpl autoAssignService;

    @BeforeEach
    void setUp() {
        autoAssignService = new AutoAssignServiceImpl(
                autoAssignConfigRepository,
                decisionLogRepository,
                reportCategoryRepository,
                userRepository,
                reportRepository,
                new ObjectMapper(),
                messageSource);
        lenient().when(decisionLogRepository.save(any(AssignmentDecisionLog.class)))
                .thenAnswer(inv -> {
                    AssignmentDecisionLog logEntity = inv.getArgument(0);
                    if (logEntity.getId() == null) {
                        logEntity.setId("adl-1");
                    }
                    return logEntity;
                });
        lenient().when(messageSource.getMessage(anyString(), any(), anyString(), any(Locale.class)))
                .thenAnswer(inv -> inv.getArgument(0));
    }

    private AutoAssignConfig defaultConfig(EAutoAssignMode mode) {
        return AutoAssignConfig.builder()
                .mode(mode)
                .distanceWeight(0.45)
                .monthlyWorkloadWeight(0.35)
                .activeLoadWeight(0.15)
                .onTimeRateWeight(0.05)
                .maxRadiusKm(15.0)
                .maxConcurrentTasks(10)
                .targetMonthlyTasks(20)
                .build();
    }

    private Report buildReport(String id, ReportCategory category, double lat, double lng) {
        Report r = Report.builder()
                .title("Vỡ ống nước")
                .latitude(lat)
                .longitude(lng)
                .severity(EReportSeverity.high)
                .status(EReportStatus.pending)
                .category(category)
                .build();
        r.setId(id);
        return r;
    }

    private ReportCategory buildCategory(String id, String code, Set<Position> positions) {
        ReportCategory c = ReportCategory.builder()
                .code(code)
                .nameVi("Cấp thoát nước")
                .nameEn("Water & Drainage")
                .positions(positions)
                .isActive(true)
                .build();
        c.setId(id);
        return c;
    }

    private Position buildPosition(String id, String code, String name) {
        Position p = Position.builder().code(code).name(name).isActive(true).build();
        p.setId(id);
        return p;
    }

    private User buildStaff(String id, String name, Position pos, double lat, double lng) {
        User u = User.builder()
                .fullName(name)
                .email(id + "@test.com")
                .role(ERole.staff)
                .status(EUserStatus.active)
                .position(pos)
                .baseLatitude(lat)
                .baseLongitude(lng)
                .build();
        u.setId(id);
        return u;
    }

    @Test
    void hardFiltersReturnExpectedFallbackReasons() {
        when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.AUTO)));

        // 1. No category
        Report noCat = buildReport("r-nocat", null, 10.78, 106.69);
        AutoAssignRecommendationResponse resNoCat = autoAssignService.getRecommendations(noCat, 3, Locale.ENGLISH);
        assertEquals("auto_assign.fallback.no_category", resNoCat.getFallbackReason());
        assertTrue(resNoCat.getCandidates().isEmpty());

        // 2. Category without mapped positions
        ReportCategory emptyPosCat = buildCategory("cat-empty", "PARKS", new LinkedHashSet<>());
        when(reportCategoryRepository.findById("cat-empty")).thenReturn(Optional.of(emptyPosCat));
        Report noPosReport = buildReport("r-nopos", emptyPosCat, 10.78, 106.69);
        assertEquals("auto_assign.fallback.no_mapped_positions",
                autoAssignService.getRecommendations(noPosReport, 3, Locale.ENGLISH).getFallbackReason());

        // 3. Out of radius
        Position plumber = buildPosition("p2", "PLUMBER", "Cấp thoát nước");
        ReportCategory waterCat = buildCategory("cat-water", "WATER", Set.of(plumber));
        when(reportCategoryRepository.findById("cat-water")).thenReturn(Optional.of(waterCat));
        // Distant staff in Hanoi (~1100km away from HCMC)
        User farStaff = buildStaff("u-far", "Far Staff", plumber, 21.0285, 105.8542);
        when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p2")))
                .thenReturn(List.of(farStaff));
        Report waterReport = buildReport("r-far", waterCat, 10.78, 106.69);
        assertEquals("auto_assign.fallback.out_of_radius",
                autoAssignService.getRecommendations(waterReport, 3, Locale.ENGLISH).getFallbackReason());

        // 4. All nearby staff overloaded (>= maxConcurrentTasks = 10)
        User busyStaff = buildStaff("u-busy", "Busy Staff", plumber, 10.781, 106.691);
        when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p2")))
                .thenReturn(List.of(busyStaff));
        when(reportRepository.countByAssignedStaffIdInAndStatus(List.of("u-busy"), EReportStatus.processing))
                .thenReturn(List.<Object[]>of(new Object[] { "u-busy", 10L }));
        assertEquals("auto_assign.fallback.all_staff_overloaded",
                autoAssignService.getRecommendations(waterReport, 3, Locale.ENGLISH).getFallbackReason());
    }

    @Test
    void multiCriteriaScoringBalancesDistanceAndMonthlyWorkload() {
        when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.AUTO)));

        Position plumber = buildPosition("p2", "PLUMBER", "Cấp thoát nước");
        ReportCategory waterCat = buildCategory("cat-water", "WATER", Set.of(plumber));
        when(reportCategoryRepository.findById("cat-water")).thenReturn(Optional.of(waterCat));

        // Report in District 3: (10.7798, 106.6930)
        Report report = buildReport("r-d3", waterCat, 10.7798, 106.6930);

        // Staff A: right nearby (~0 km) BUT heavy monthly (18) & active (7) & lower on-time (60%)
        User staffHeavy = buildStaff("u-heavy", "Staff Heavy", plumber, 10.7798, 106.6930);
        // Staff B: ~2.5 km away (10.799, 106.705) BUT very light monthly (1) & active (0) & 100% on-time
        User staffLight = buildStaff("u-light", "Staff Light", plumber, 10.799, 106.705);

        when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p2")))
                .thenReturn(List.of(staffHeavy, staffLight));
        when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of(
                        new Object[] { "u-heavy", 7L },
                        new Object[] { "u-light", 0L }));
        when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of(
                        new Object[] { "u-heavy", 18L },
                        new Object[] { "u-light", 1L }));
        when(reportRepository.findLastAssignedAtByStaffIds(anyList())).thenReturn(List.of());
        when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any()))
                .thenReturn(List.of(
                        new Object[] { "u-heavy", 3L, 5L },   // 60%
                        new Object[] { "u-light", 5L, 5L })); // 100%

        AutoAssignRecommendationResponse recs = autoAssignService.getRecommendations(report, 3, Locale.ENGLISH);
        assertEquals(2, recs.getCandidates().size());
        StaffCandidateScoreResponse first = recs.getCandidates().get(0);
        StaffCandidateScoreResponse second = recs.getCandidates().get(1);

        assertEquals("u-light", first.getStaffId());
        assertEquals(1, first.getRank());
        assertEquals("u-heavy", second.getStaffId());
        assertEquals(2, second.getRank());
        assertTrue(first.getFinalScore() > second.getFinalScore());
    }

    @Test
    void tieBreakerOrdersDeterministicallyByLastAssignedAtNullFirstThenId() {
        when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.AUTO)));

        Position elec = buildPosition("p1", "ELECTRICIAN", "Kỹ thuật điện");
        ReportCategory elecCat = buildCategory("cat-elec", "ELEC", Set.of(elec));
        when(reportCategoryRepository.findById("cat-elec")).thenReturn(Optional.of(elecCat));

        Report report = buildReport("r-tie", elecCat, 10.78, 106.69);
        // Same coordinates, zero active/monthly tasks
        User staffRecent = buildStaff("u-1", "Staff Recent", elec, 10.78, 106.69);
        User staffOlder = buildStaff("u-2", "Staff Older", elec, 10.78, 106.69);
        User staffNever = buildStaff("u-3", "Staff Never", elec, 10.78, 106.69);

        when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p1")))
                .thenReturn(List.of(staffRecent, staffOlder, staffNever));
        when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of());
        when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of());
        when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any()))
                .thenReturn(List.of());
        when(reportRepository.findLastAssignedAtByStaffIds(anyList()))
                .thenReturn(List.of(
                        new Object[] { "u-1", new Date(System.currentTimeMillis() - 60_000L) },
                        new Object[] { "u-2", new Date(System.currentTimeMillis() - 3_600_000L) }));

        AutoAssignRecommendationResponse recs = autoAssignService.getRecommendations(report, 3, Locale.ENGLISH);
        assertEquals(List.of("u-3", "u-2", "u-1"),
                recs.getCandidates().stream().map(StaffCandidateScoreResponse::getStaffId).toList());
    }

    @Test
    void evaluateOnReportCreatedRespectsModesAndLogsOverriddenOnManualReassign() {
        Position p3 = buildPosition("p3", "SANITATION", "Vệ sinh MT");
        ReportCategory envCat = buildCategory("cat-env", "ENV", Set.of(p3));
        Report report = buildReport("r-auto", envCat, 10.77, 106.68);
        User winner = buildStaff("u-win", "Winner", p3, 10.77, 106.68);
        User other = buildStaff("u-other", "Other", p3, 10.79, 106.70);

        // MANUAL mode skips scoring entirely
        AutoAssignDispatchResult manualRes = autoAssignService.evaluateOnReportCreated(
                report, defaultConfig(EAutoAssignMode.MANUAL));
        assertFalse(manualRes.isAssigned());
        assertNull(manualRes.getDecisionLog());

        // Setup eligible candidate pool for ASSIST & AUTO
        lenient().when(reportCategoryRepository.findById("cat-env")).thenReturn(Optional.of(envCat));
        lenient().when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p3")))
                .thenReturn(List.of(winner));
        lenient().when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of());
        lenient().when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of());
        lenient().when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any()))
                .thenReturn(List.of());
        lenient().when(reportRepository.findLastAssignedAtByStaffIds(anyList())).thenReturn(List.of());

        // ASSIST mode recommends without assigning
        AutoAssignDispatchResult assistRes = autoAssignService.evaluateOnReportCreated(
                report, defaultConfig(EAutoAssignMode.ASSIST));
        assertFalse(assistRes.isAssigned());
        assertNull(assistRes.getSelectedStaff());
        assertNotNull(assistRes.getDecisionLog());
        assertEquals(EAssignmentOutcome.RECOMMENDED, assistRes.getDecisionLog().getOutcome());

        // AUTO mode assigns winner
        AutoAssignDispatchResult autoRes = autoAssignService.evaluateOnReportCreated(
                report, defaultConfig(EAutoAssignMode.AUTO));
        assertTrue(autoRes.isAssigned());
        assertEquals("u-win", autoRes.getSelectedStaff().getId());
        assertEquals(EAssignmentOutcome.ASSIGNED, autoRes.getDecisionLog().getOutcome());

        // Mark overridden when Admin reassigns to another staff
        report.setDecisionLogId(autoRes.getDecisionLog().getId());
        when(decisionLogRepository.findById(autoRes.getDecisionLog().getId()))
                .thenReturn(Optional.of(autoRes.getDecisionLog()));

        autoAssignService.markOverriddenIfNeeded(report, other, "admin-1");
        ArgumentCaptor<AssignmentDecisionLog> savedCaptor = ArgumentCaptor.forClass(AssignmentDecisionLog.class);
        verify(decisionLogRepository, atLeastOnce()).save(savedCaptor.capture());
        AssignmentDecisionLog lastSaved = savedCaptor.getValue();
        assertEquals(EAssignmentOutcome.OVERRIDDEN, lastSaved.getOutcome());
        assertEquals("admin-1", lastSaved.getOverriddenByAdminId());
        assertEquals("u-other", lastSaved.getOverriddenToStaffId());

        when(userRepository.findById("u-other")).thenReturn(Optional.of(other));
        AssignmentDecisionSummaryResponse summary = autoAssignService.getDecisionSummary(report, Locale.ENGLISH);
        assertEquals("OVERRIDDEN", summary.getOutcome());
        assertEquals("Other", summary.getOverriddenToStaffName());
        assertFalse(summary.getCandidatesSnapshot().isEmpty());
    }

    @Test
    void lockDispatchConfigReturnsLockedRowOrCreatesAssistDefault() {
        AutoAssignConfig existing = defaultConfig(EAutoAssignMode.AUTO);
        when(autoAssignConfigRepository.findLatestForUpdate(any(Pageable.class))).thenReturn(List.of(existing));
        assertSame(existing, autoAssignService.lockDispatchConfig());
        verify(autoAssignConfigRepository, never()).saveAndFlush(any());

        // DB trống: tạo cấu hình mặc định ASSIST để luôn có hàng làm khoá
        when(autoAssignConfigRepository.findLatestForUpdate(any(Pageable.class))).thenReturn(List.of());
        when(autoAssignConfigRepository.saveAndFlush(any(AutoAssignConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        AutoAssignConfig created = autoAssignService.lockDispatchConfig();
        assertEquals(EAutoAssignMode.ASSIST, created.getMode());
    }

    @Test
    void markOverriddenAlsoAppliesToAssistRecommendation() {
        Position p3 = buildPosition("p3", "SANITATION", "Vệ sinh MT");
        ReportCategory envCat = buildCategory("cat-env", "ENV", Set.of(p3));
        Report report = buildReport("r-assist", envCat, 10.77, 106.68);
        User recommended = buildStaff("u-rec", "Recommended", p3, 10.77, 106.68);
        User picked = buildStaff("u-picked", "Picked", p3, 10.78, 106.69);

        AssignmentDecisionLog recommendation = AssignmentDecisionLog.builder()
                .report(report)
                .modeAtDecision(EAutoAssignMode.ASSIST)
                .source(EAssignmentSource.AUTO)
                .outcome(EAssignmentOutcome.RECOMMENDED)
                .selectedStaff(recommended)
                .build();
        recommendation.setId("adl-rec");
        report.setDecisionLogId("adl-rec");
        when(decisionLogRepository.findById("adl-rec")).thenReturn(Optional.of(recommendation));

        // Admin chọn đúng người được đề xuất → không phải ghi đè
        autoAssignService.markOverriddenIfNeeded(report, recommended, "admin-1");
        assertEquals(EAssignmentOutcome.RECOMMENDED, recommendation.getOutcome());

        // Admin chọn người khác → OVERRIDDEN (phục vụ Acceptance Rate ở Giai đoạn 3)
        autoAssignService.markOverriddenIfNeeded(report, picked, "admin-1");
        assertEquals(EAssignmentOutcome.OVERRIDDEN, recommendation.getOutcome());
        assertEquals("u-picked", recommendation.getOverriddenToStaffId());
    }
}
