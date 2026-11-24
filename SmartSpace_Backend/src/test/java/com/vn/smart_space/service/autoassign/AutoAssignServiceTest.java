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
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.consts.EReportSeverity;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.PageResponse;
import com.vn.smart_space.dto.request.report.AutoAssignConfigRequest;
import com.vn.smart_space.dto.request.report.AutoAssignSimulateRequest;
import com.vn.smart_space.dto.response.autoassign.AssignmentDecisionSummaryResponse;
import com.vn.smart_space.dto.response.autoassign.AutoAssignRecommendationResponse;
import com.vn.smart_space.dto.response.autoassign.StaffCandidateScoreResponse;
import com.vn.smart_space.dto.response.report.AssignmentDecisionLogResponse;
import com.vn.smart_space.dto.response.report.AutoAssignAnalyticsResponse;
import com.vn.smart_space.dto.response.report.AutoAssignConfigResponse;
import com.vn.smart_space.exception.BadRequestException;
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

        // Khi Admin bấm "Giao ngay" (recordRecommendClick) cho đúng người được đề xuất,
        // bản ghi RECOMMENDED hiện có được nâng cấp tại chỗ sang ASSIGNED (không tạo bản ghi trùng)
        lenient().when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.ASSIST)));
        lenient().when(reportCategoryRepository.findById("cat-env")).thenReturn(Optional.of(envCat));
        lenient().when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p3")))
                .thenReturn(List.of(recommended));
        lenient().when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of());
        lenient().when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of());
        lenient().when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any()))
                .thenReturn(List.of());
        lenient().when(reportRepository.findLastAssignedAtByStaffIds(anyList())).thenReturn(List.of());
        lenient().when(decisionLogRepository.save(any(AssignmentDecisionLog.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        AssignmentDecisionLog promoted = autoAssignService.recordRecommendClick(report, recommended, "admin-1");
        assertEquals("adl-rec", promoted.getId());
        assertEquals(EAssignmentSource.RECOMMEND_CLICK, promoted.getSource());
        assertEquals(EAssignmentOutcome.ASSIGNED, promoted.getOutcome());

        // Admin sau đó đổi người phụ trách sang người khác → OVERRIDDEN (phục vụ Acceptance Rate ở Giai đoạn 3)
        autoAssignService.markOverriddenIfNeeded(report, picked, "admin-1");
        assertEquals(EAssignmentOutcome.OVERRIDDEN, recommendation.getOutcome());
        assertEquals("u-picked", recommendation.getOverriddenToStaffId());
    }

    @Test
    void updateConfigNormalizesPercentageWeightsAndRejectsInvalidSum() {
        AutoAssignConfig existing = defaultConfig(EAutoAssignMode.ASSIST);
        existing.setId("cfg-1");
        when(autoAssignConfigRepository.findLatestForUpdate(any(Pageable.class))).thenReturn(List.of(existing));
        when(autoAssignConfigRepository.saveAndFlush(any(AutoAssignConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        AutoAssignConfigRequest validPercentageReq = AutoAssignConfigRequest.builder()
                .mode(EAutoAssignMode.AUTO)
                .distanceWeight(35.0)
                .monthlyWorkloadWeight(30.0)
                .activeLoadWeight(20.0)
                .onTimeRateWeight(15.0)
                .maxRadiusKm(12.0)
                .maxConcurrentTasks(8)
                .targetMonthlyTasks(25)
                .build();

        AutoAssignConfigResponse updated = autoAssignService.updateConfig(validPercentageReq, "admin-99");
        assertEquals(EAutoAssignMode.AUTO, updated.getMode());
        assertEquals(0.35, updated.getDistanceWeight(), 0.001);
        assertEquals(0.30, updated.getMonthlyWorkloadWeight(), 0.001);
        assertEquals(0.20, updated.getActiveLoadWeight(), 0.001);
        assertEquals(0.15, updated.getOnTimeRateWeight(), 0.001);
        assertEquals(12.0, updated.getMaxRadiusKm());
        assertEquals(8, updated.getMaxConcurrentTasks());
        assertEquals(25, updated.getTargetMonthlyTasks());
        assertEquals("admin-99", updated.getUpdatedByAdminId());

        AutoAssignConfigRequest invalidSumReq = AutoAssignConfigRequest.builder()
                .mode(EAutoAssignMode.AUTO)
                .distanceWeight(50.0)
                .monthlyWorkloadWeight(50.0)
                .activeLoadWeight(20.0)
                .onTimeRateWeight(10.0)
                .maxRadiusKm(10.0)
                .maxConcurrentTasks(5)
                .targetMonthlyTasks(20)
                .build();

        BadRequestException ex = assertThrows(BadRequestException.class,
                () -> autoAssignService.updateConfig(invalidSumReq, "admin-99"));
        assertEquals("auto_assign.weight.invalid_sum", ex.getMessage());
    }

    @Test
    void simulateReRanksCandidatesWhenWeightsShiftWithoutSavingLogs() {
        when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.ASSIST)));

        Position elec = buildPosition("p1", "ELECTRICIAN", "Kỹ thuật điện");
        ReportCategory elecCat = buildCategory("cat-elec", "ELEC", Set.of(elec));
        when(reportCategoryRepository.findWithPositionsById("cat-elec")).thenReturn(Optional.of(elecCat));
        when(reportCategoryRepository.findById("cat-elec")).thenReturn(Optional.of(elecCat));

        // Staff Near: right next to incident (10.77, 106.68), but heavy monthly workload (18 tasks)
        User staffNearHeavy = buildStaff("u-near", "Near Heavy", elec, 10.7705, 106.6805);
        // Staff Far: ~4.5 km away, but 0 monthly workload
        User staffFarLight = buildStaff("u-far", "Far Light", elec, 10.805, 106.705);

        when(userRepository.findActiveStaffByPositionIds(ERole.staff, EUserStatus.active, Set.of("p1")))
                .thenReturn(List.of(staffNearHeavy, staffFarLight));
        when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of(
                        new Object[] { "u-near", 3L },
                        new Object[] { "u-far", 0L }));
        when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of(
                        new Object[] { "u-near", 18L },
                        new Object[] { "u-far", 0L }));
        when(reportRepository.findLastAssignedAtByStaffIds(anyList())).thenReturn(List.of());
        when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any())).thenReturn(List.of());

        // Simulation 1: 90% weight on distance -> Near Heavy wins
        AutoAssignRecommendationResponse simDistance = autoAssignService.simulate(
                AutoAssignSimulateRequest.builder()
                        .categoryId("cat-elec")
                        .latitude(10.77)
                        .longitude(106.68)
                        .distanceWeight(90.0)
                        .monthlyWorkloadWeight(5.0)
                        .activeLoadWeight(5.0)
                        .onTimeRateWeight(0.0)
                        .build(),
                Locale.ENGLISH);
        assertEquals("u-near", simDistance.getCandidates().get(0).getStaffId());

        // Simulation 2: 90% weight on monthly workload -> Far Light wins
        AutoAssignRecommendationResponse simFairness = autoAssignService.simulate(
                AutoAssignSimulateRequest.builder()
                        .categoryId("cat-elec")
                        .latitude(10.77)
                        .longitude(106.68)
                        .distanceWeight(5.0)
                        .monthlyWorkloadWeight(90.0)
                        .activeLoadWeight(5.0)
                        .onTimeRateWeight(0.0)
                        .build(),
                Locale.ENGLISH);
        assertEquals("u-far", simFairness.getCandidates().get(0).getStaffId());

        // Verify dry-run never persists anything to decisionLogRepository
        verify(decisionLogRepository, never()).save(any());
    }

    @Test
    void getAnalyticsCalculatesAcceptanceRateAndJainFairnessIndex() {
        when(autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc())
                .thenReturn(Optional.of(defaultConfig(EAutoAssignMode.AUTO)));

        when(decisionLogRepository.count()).thenReturn(20L);
        when(decisionLogRepository.countByOutcome(EAssignmentOutcome.FALLBACK_PENDING)).thenReturn(4L);
        when(decisionLogRepository.countByOutcome(EAssignmentOutcome.OVERRIDDEN)).thenReturn(2L);
        when(decisionLogRepository.countBySourceAndOutcome(EAssignmentSource.AUTO, EAssignmentOutcome.ASSIGNED))
                .thenReturn(10L);
        when(decisionLogRepository.countBySourceAndOutcome(
                EAssignmentSource.RECOMMEND_CLICK, EAssignmentOutcome.ASSIGNED)).thenReturn(4L);

        Position elec = buildPosition("p1", "ELECTRICIAN", "Kỹ thuật điện");
        User s1 = buildStaff("u-1", "Staff 1", elec, 10.77, 106.68);
        User s2 = buildStaff("u-2", "Staff 2", elec, 10.78, 106.69);
        when(userRepository.findAllActiveStaffWithPosition(ERole.staff, EUserStatus.active))
                .thenReturn(List.of(s1, s2));
        when(reportRepository.countByAssignedStaffIdInAndStatus(anyList(), eq(EReportStatus.processing)))
                .thenReturn(List.of(new Object[] { "u-1", 2L }, new Object[] { "u-2", 2L }));
        // Equal monthly workload (10 and 10) -> Jain's Fairness Index = 100.0%
        when(reportRepository.countMonthlyWorkloadByStaffIds(anyList(), any(), any(), any(), any()))
                .thenReturn(List.of(new Object[] { "u-1", 10L }, new Object[] { "u-2", 10L }));
        when(reportRepository.countOnTimeResolvedSinceByStaffIds(anyList(), any())).thenReturn(List.of());

        AutoAssignAnalyticsResponse analytics = autoAssignService.getAnalytics();
        assertEquals(20L, analytics.getTotalDecisions());
        // 16 non-fallback out of 20 = 80.0% auto-assign success rate
        assertEquals(80.0, analytics.getAutoAssignSuccessRate(), 0.01);
        // 14 not overridden out of 16 successful = 87.5% admin acceptance rate
        assertEquals(87.5, analytics.getAdminAcceptanceRate(), 0.01);
        assertEquals(100.0, analytics.getMonthlyFairnessIndex(), 0.01);
        assertEquals(10.0, analytics.getAverageMonthlyWorkload(), 0.01);
        assertEquals(0.0, analytics.getWorkloadStandardDeviation(), 0.01);
        assertEquals(2, analytics.getStaffWorkloads().size());
    }

    @Test
    void getDecisionLogsReturnsFilteredPaginatedHistory() {
        Position elec = buildPosition("p1", "ELECTRICIAN", "Kỹ thuật điện");
        ReportCategory elecCat = buildCategory("cat-elec", "ELEC", Set.of(elec));
        Report report = buildReport("r-100", elecCat, 10.77, 106.68);
        User selected = buildStaff("u-1", "Staff One", elec, 10.77, 106.68);

        AssignmentDecisionLog logEntry = AssignmentDecisionLog.builder()
                .report(report)
                .categoryId("cat-elec")
                .categoryCode("ELEC")
                .modeAtDecision(EAutoAssignMode.AUTO)
                .source(EAssignmentSource.AUTO)
                .outcome(EAssignmentOutcome.ASSIGNED)
                .selectedStaff(selected)
                .finalScore(91.5)
                .distanceKm(1.2)
                .eligibleCandidateCount(3)
                .build();
        logEntry.setId("log-1");

        when(decisionLogRepository.findLogsFiltered(
                eq(EAssignmentOutcome.ASSIGNED), isNull(), isNull(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(logEntry)));
        when(reportCategoryRepository.findAll()).thenReturn(List.of(elecCat));

        PageResponse<AssignmentDecisionLogResponse> page = autoAssignService.getDecisionLogs(
                "ASSIGNED", null, null, 1, 10, Locale.ENGLISH);
        assertEquals(1, page.getTotalElements());
        assertEquals("log-1", page.getContent().get(0).getId());
        assertEquals("r-100", page.getContent().get(0).getReportId());
        assertEquals("Staff One", page.getContent().get(0).getSelectedStaffName());
        assertEquals(91.5, page.getContent().get(0).getFinalScore());
    }
}
