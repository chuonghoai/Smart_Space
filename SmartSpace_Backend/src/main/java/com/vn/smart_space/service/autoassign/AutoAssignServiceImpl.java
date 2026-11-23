package com.vn.smart_space.service.autoassign;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vn.smart_space.consts.EAssignmentOutcome;
import com.vn.smart_space.consts.EAssignmentSource;
import com.vn.smart_space.consts.EAutoAssignMode;
import com.vn.smart_space.consts.EReportStatus;
import com.vn.smart_space.consts.ERole;
import com.vn.smart_space.consts.EUserStatus;
import com.vn.smart_space.dto.response.autoassign.AssignmentDecisionSummaryResponse;
import com.vn.smart_space.dto.response.autoassign.AutoAssignRecommendationResponse;
import com.vn.smart_space.dto.response.autoassign.StaffCandidateScoreResponse;
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
import com.vn.smart_space.utils.GeoUtils;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class AutoAssignServiceImpl implements IAutoAssignService {

    static final double DEFAULT_NEW_STAFF_ON_TIME_RATE = 85.0;
    static final int SNAPSHOT_LIMIT = 3;

    AutoAssignConfigRepository autoAssignConfigRepository;
    AssignmentDecisionLogRepository decisionLogRepository;
    ReportCategoryRepository reportCategoryRepository;
    UserRepository userRepository;
    ReportRepository reportRepository;
    ObjectMapper objectMapper;
    MessageSource messageSource;

    @Override
    @Transactional(propagation = Propagation.MANDATORY)
    public AutoAssignConfig lockDispatchConfig() {
        List<AutoAssignConfig> locked = autoAssignConfigRepository.findLatestForUpdate(PageRequest.of(0, 1));
        if (!locked.isEmpty()) {
            return locked.get(0);
        }
        // DB chưa có cấu hình: tạo bản mặc định để luôn có một hàng làm khoá phân công
        return autoAssignConfigRepository.saveAndFlush(defaultConfig());
    }

    @Override
    @Transactional(propagation = Propagation.MANDATORY)
    public AutoAssignDispatchResult evaluateOnReportCreated(Report report, AutoAssignConfig config) {
        EAutoAssignMode mode = resolveMode(config);
        if (mode == EAutoAssignMode.MANUAL) {
            return AutoAssignDispatchResult.builder()
                    .assigned(false)
                    .mode(mode)
                    .build();
        }

        PoolEvaluation evaluation = evaluatePool(report, config);
        if (!evaluation.hasCandidates()) {
            AssignmentDecisionLog fallbackLog = decisionLogRepository.save(buildFallbackLog(
                    report, evaluation.category(), config, EAssignmentSource.AUTO, evaluation.fallbackReason()));
            return AutoAssignDispatchResult.builder()
                    .assigned(false)
                    .mode(mode)
                    .decisionLog(fallbackLog)
                    .fallbackReason(evaluation.fallbackReason())
                    .build();
        }

        List<ScoredCandidate> scored = evaluation.candidates();
        ScoredCandidate winner = scored.get(0);
        boolean autoMode = mode == EAutoAssignMode.AUTO;
        EAssignmentOutcome outcome = autoMode ? EAssignmentOutcome.ASSIGNED : EAssignmentOutcome.RECOMMENDED;

        AssignmentDecisionLog savedLog = decisionLogRepository.save(
                buildCandidateLog(report, evaluation.category(), config, EAssignmentSource.AUTO, outcome, winner,
                        scored.size(), serializeSnapshot(scored, SNAPSHOT_LIMIT)));

        return AutoAssignDispatchResult.builder()
                .assigned(autoMode)
                .mode(mode)
                .selectedStaff(autoMode ? winner.staff() : null)
                .decisionLog(savedLog)
                .build();
    }

    @Override
    @Transactional(propagation = Propagation.MANDATORY)
    public AutoAssignDispatchResult evaluateManualTrigger(Report report, AutoAssignConfig config) {
        PoolEvaluation evaluation = evaluatePool(report, config);
        if (!evaluation.hasCandidates()) {
            throw new BadRequestException(evaluation.fallbackReason());
        }

        List<ScoredCandidate> scored = evaluation.candidates();
        ScoredCandidate winner = scored.get(0);

        AssignmentDecisionLog savedLog = decisionLogRepository.save(
                buildCandidateLog(report, evaluation.category(), config, EAssignmentSource.AUTO,
                        EAssignmentOutcome.ASSIGNED, winner, scored.size(), serializeSnapshot(scored, SNAPSHOT_LIMIT)));

        return AutoAssignDispatchResult.builder()
                .assigned(true)
                .mode(resolveMode(config))
                .selectedStaff(winner.staff())
                .decisionLog(savedLog)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public AutoAssignRecommendationResponse getRecommendations(Report report, int limit, Locale locale) {
        AutoAssignConfig config = getEffectiveConfig();
        int safeLimit = limit <= 0 ? SNAPSHOT_LIMIT : Math.min(limit, 10);
        PoolEvaluation evaluation = evaluatePool(report, config);
        ReportCategory category = evaluation.category();

        List<StaffCandidateScoreResponse> topCandidates = evaluation.candidates().stream()
                .limit(safeLimit)
                .map(ScoredCandidate::dto)
                .collect(Collectors.toList());

        Locale activeLocale = locale != null ? locale : LocaleContextHolder.getLocale();
        String fallbackMsg = evaluation.fallbackReason() != null
                ? resolveMessage(evaluation.fallbackReason(), activeLocale)
                : null;

        return AutoAssignRecommendationResponse.builder()
                .reportId(report.getId())
                .categoryId(category != null ? category.getId() : null)
                .categoryCode(category != null ? category.getCode() : null)
                .categoryNameVi(category != null ? category.getNameVi() : null)
                .categoryNameEn(category != null ? category.getNameEn() : null)
                .currentMode(resolveMode(config).name())
                .maxRadiusKm(safeMaxRadius(config))
                .maxConcurrentTasks(safeMaxConcurrent(config))
                .totalEligibleCandidates(evaluation.candidates().size())
                .fallbackReason(evaluation.fallbackReason())
                .fallbackMessage(fallbackMsg)
                .candidates(topCandidates)
                .build();
    }

    @Override
    @Transactional
    public AssignmentDecisionLog recordRecommendClick(Report report, User staff, String adminId) {
        AutoAssignConfig config = getEffectiveConfig();
        PoolEvaluation evaluation = evaluatePool(report, config);
        List<ScoredCandidate> scored = evaluation.candidates();

        Optional<ScoredCandidate> matched = scored.stream()
                .filter(c -> c.staff().getId().equals(staff.getId()))
                .findFirst();

        String snapshotJson = serializeSnapshot(scored, SNAPSHOT_LIMIT);
        ReportCategory category = evaluation.category();
        AssignmentDecisionLog logEntity;
        if (matched.isPresent()) {
            logEntity = buildCandidateLog(report, category, config, EAssignmentSource.RECOMMEND_CLICK,
                    EAssignmentOutcome.ASSIGNED, matched.get(), scored.size(), snapshotJson);
        } else {
            // Staff selected outside eligible pool: record clean direct metrics if possible
            Double distKm = (GeoUtils.isValidCoordinate(report.getLatitude(), report.getLongitude())
                    && GeoUtils.isValidCoordinate(staff.getBaseLatitude(), staff.getBaseLongitude()))
                            ? round2(GeoUtils.haversineKm(report.getLatitude(), report.getLongitude(),
                                    staff.getBaseLatitude(), staff.getBaseLongitude()))
                            : null;
            logEntity = AssignmentDecisionLog.builder()
                    .report(report)
                    .categoryId(category != null ? category.getId() : null)
                    .categoryCode(category != null ? category.getCode() : null)
                    .modeAtDecision(resolveMode(config))
                    .source(EAssignmentSource.RECOMMEND_CLICK)
                    .outcome(EAssignmentOutcome.ASSIGNED)
                    .selectedStaff(staff)
                    .distanceKm(distKm)
                    .eligibleCandidateCount(scored.size())
                    .candidatesSnapshotJson(snapshotJson)
                    .build();
        }
        return decisionLogRepository.save(logEntity);
    }

    @Override
    @Transactional
    public void markOverriddenIfNeeded(Report report, User newStaff, String adminId) {
        if (report == null || newStaff == null) {
            return;
        }
        Optional<AssignmentDecisionLog> optLog = Optional.empty();
        if (report.getDecisionLogId() != null && !report.getDecisionLogId().isBlank()) {
            optLog = decisionLogRepository.findById(report.getDecisionLogId());
        }
        if (optLog.isEmpty()) {
            optLog = decisionLogRepository.findTopByReportIdOrderByCreatedAtDesc(report.getId());
        }
        if (optLog.isEmpty()) {
            return;
        }

        AssignmentDecisionLog prevLog = optLog.get();
        boolean wasSystemOrRecommend = prevLog.getSource() == EAssignmentSource.AUTO
                || prevLog.getSource() == EAssignmentSource.RECOMMEND_CLICK;
        // RECOMMENDED (chế độ ASSIST) cũng tính: Admin chọn người khác với đề xuất số 1 là "ghi đè"
        boolean wasAssigned = prevLog.getOutcome() == EAssignmentOutcome.ASSIGNED
                || prevLog.getOutcome() == EAssignmentOutcome.RECOMMENDED;
        User prevStaff = prevLog.getSelectedStaff();

        if (wasSystemOrRecommend && wasAssigned
                && (prevStaff == null || !prevStaff.getId().equals(newStaff.getId()))) {
            prevLog.setOutcome(EAssignmentOutcome.OVERRIDDEN);
            prevLog.setOverriddenByAdminId(adminId);
            prevLog.setOverriddenToStaffId(newStaff.getId());
            prevLog.setOverriddenAt(LocalDateTime.now());
            decisionLogRepository.save(prevLog);
        }
    }

    @Override
    @Transactional(readOnly = true)
    public AssignmentDecisionSummaryResponse getDecisionSummary(Report report, Locale locale) {
        if (report == null || report.getId() == null) {
            return null;
        }
        Optional<AssignmentDecisionLog> optLog = Optional.empty();
        if (report.getDecisionLogId() != null && !report.getDecisionLogId().isBlank()) {
            optLog = decisionLogRepository.findById(report.getDecisionLogId());
        }
        if (optLog.isEmpty()) {
            optLog = decisionLogRepository.findTopByReportIdOrderByCreatedAtDesc(report.getId());
        }
        if (optLog.isEmpty()) {
            return null;
        }

        AssignmentDecisionLog entry = optLog.get();
        // Log FALLBACK_PENDING chỉ có ý nghĩa khi phản ánh vẫn đang chờ xử lý;
        // nếu đã được Admin phân công thủ công (status != pending) thì không trả về
        // thẻ cảnh báo lỗi fallback cũ trên màn chi tiết.
        if (entry.getOutcome() == EAssignmentOutcome.FALLBACK_PENDING
                && report.getStatus() != null
                && report.getStatus() != EReportStatus.pending) {
            return null;
        }
        User selected = entry.getSelectedStaff();
        String overriddenToName = null;
        if (entry.getOverriddenToStaffId() != null && !entry.getOverriddenToStaffId().isBlank()) {
            overriddenToName = userRepository.findById(entry.getOverriddenToStaffId())
                    .map(User::getFullName)
                    .orElse(null);
        }
        Locale activeLocale = locale != null ? locale : LocaleContextHolder.getLocale();
        String fallbackMsg = entry.getFallbackReason() != null
                ? resolveMessage(entry.getFallbackReason(), activeLocale)
                : null;

        return AssignmentDecisionSummaryResponse.builder()
                .id(entry.getId())
                .modeAtDecision(entry.getModeAtDecision() != null ? entry.getModeAtDecision().name() : null)
                .source(entry.getSource() != null ? entry.getSource().name() : null)
                .outcome(entry.getOutcome() != null ? entry.getOutcome().name() : null)
                .selectedStaffId(selected != null ? selected.getId() : null)
                .selectedStaffName(selected != null ? selected.getFullName() : null)
                .selectedStaffEmail(selected != null ? selected.getEmail() : null)
                .selectedStaffPositionName(
                        selected != null && selected.getPosition() != null ? selected.getPosition().getName() : null)
                .finalScore(entry.getFinalScore())
                .distanceKm(entry.getDistanceKm())
                .distanceScore(entry.getDistanceScore())
                .monthlyWorkload(entry.getMonthlyWorkload())
                .monthlyWorkloadScore(entry.getMonthlyWorkloadScore())
                .activeProcessingCount(entry.getActiveProcessingCount())
                .activeLoadScore(entry.getActiveLoadScore())
                .onTimeRate30d(entry.getOnTimeRate30d())
                .onTimeRateScore(entry.getOnTimeRateScore())
                .eligibleCandidateCount(entry.getEligibleCandidateCount())
                .fallbackReason(entry.getFallbackReason())
                .fallbackMessage(fallbackMsg)
                .overriddenByAdminId(entry.getOverriddenByAdminId())
                .overriddenToStaffId(entry.getOverriddenToStaffId())
                .overriddenToStaffName(overriddenToName)
                .overriddenAt(formatIso(entry.getOverriddenAt()))
                .createdAt(formatIso(entry.getCreatedAt()))
                .candidatesSnapshot(deserializeSnapshot(entry.getCandidatesSnapshotJson()))
                .build();
    }

    // -------------------------------------------------------------------------
    // Core two-stage filtering & multi-criteria scoring
    // -------------------------------------------------------------------------

    PoolEvaluation evaluatePool(Report report, AutoAssignConfig config) {
        // Resolve danh mục một lần cho cả lượt đánh giá (log, response đều dùng lại)
        ReportCategory category = resolveCategory(report);
        if (report == null || !GeoUtils.isValidCoordinate(report.getLatitude(), report.getLongitude())) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.invalid_report_coordinates");
        }

        if (category == null) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.no_category");
        }

        Set<String> activePositionIds = category.getPositions() == null
                ? Collections.emptySet()
                : category.getPositions().stream()
                        .filter(p -> p != null && Boolean.TRUE.equals(p.getIsActive()))
                        .map(Position::getId)
                        .collect(Collectors.toSet());
        if (activePositionIds.isEmpty()) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.no_mapped_positions");
        }

        List<User> positionStaffs = userRepository.findActiveStaffByPositionIds(
                ERole.staff, EUserStatus.active, activePositionIds);
        if (positionStaffs == null || positionStaffs.isEmpty()) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.no_staff_in_positions");
        }

        List<User> geoReadyStaffs = positionStaffs.stream()
                .filter(u -> GeoUtils.isValidCoordinate(u.getBaseLatitude(), u.getBaseLongitude()))
                .collect(Collectors.toList());
        if (geoReadyStaffs.isEmpty()) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.no_staff_with_base_location");
        }

        double maxRadiusKm = safeMaxRadius(config);
        List<StaffDistancePair> withinRadius = new ArrayList<>();
        for (User staff : geoReadyStaffs) {
            double distKm = GeoUtils.haversineKm(
                    report.getLatitude(), report.getLongitude(),
                    staff.getBaseLatitude(), staff.getBaseLongitude());
            if (distKm <= maxRadiusKm) {
                withinRadius.add(new StaffDistancePair(staff, distKm));
            }
        }
        if (withinRadius.isEmpty()) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.out_of_radius");
        }

        List<String> radiusStaffIds = withinRadius.stream()
                .map(pair -> pair.staff().getId())
                .collect(Collectors.toList());

        Map<String, Integer> activeCountMap = toIntCountMap(
                reportRepository.countByAssignedStaffIdInAndStatus(radiusStaffIds, EReportStatus.processing));

        int maxConcurrent = safeMaxConcurrent(config);
        List<StaffDistancePair> eligiblePairs = new ArrayList<>();
        for (StaffDistancePair pair : withinRadius) {
            int activeCount = activeCountMap.getOrDefault(pair.staff().getId(), 0);
            if (activeCount < maxConcurrent) {
                eligiblePairs.add(pair);
            }
        }
        if (eligiblePairs.isEmpty()) {
            return PoolEvaluation.fallback(category, "auto_assign.fallback.all_staff_overloaded");
        }

        List<String> eligibleIds = eligiblePairs.stream()
                .map(pair -> pair.staff().getId())
                .collect(Collectors.toList());

        YearMonth currentMonth = YearMonth.now();
        LocalDateTime monthStartLdt = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime monthEndLdt = currentMonth.plusMonths(1).atDay(1).atStartOfDay();
        Date monthStart = Date.from(monthStartLdt.atZone(ZoneId.systemDefault()).toInstant());
        Date monthEnd = Date.from(monthEndLdt.atZone(ZoneId.systemDefault()).toInstant());

        Map<String, Integer> monthlyCountMap = toIntCountMap(
                reportRepository.countMonthlyWorkloadByStaffIds(
                        eligibleIds, monthStart, monthEnd, monthStartLdt, monthEndLdt));
        Map<String, Date> lastAssignedMap = toDateMap(reportRepository.findLastAssignedAtByStaffIds(eligibleIds));
        Map<String, Double> onTimeRateMap = toOnTimeRateMap(
                reportRepository.countOnTimeResolvedSinceByStaffIds(eligibleIds, LocalDateTime.now().minusDays(30)));

        int maxMonthlyInPool = 0;
        for (String id : eligibleIds) {
            maxMonthlyInPool = Math.max(maxMonthlyInPool, monthlyCountMap.getOrDefault(id, 0));
        }

        NormalizedWeights weights = normalizeWeights(config);
        int targetMonthly = Math.max(1, config.getTargetMonthlyTasks() != null ? config.getTargetMonthlyTasks() : 20);
        int monthlyDivisor = maxMonthlyInPool == 0 ? 1 : Math.max(maxMonthlyInPool, Math.max(5, targetMonthly));

        List<ScoredWorkingItem> working = new ArrayList<>(eligiblePairs.size());
        for (StaffDistancePair pair : eligiblePairs) {
            User staff = pair.staff();
            String sid = staff.getId();
            double distKm = pair.distanceKm();
            int monthly = monthlyCountMap.getOrDefault(sid, 0);
            int active = activeCountMap.getOrDefault(sid, 0);
            double onTime = onTimeRateMap.getOrDefault(sid, DEFAULT_NEW_STAFF_ON_TIME_RATE);

            double distScore = Math.max(0.0, 100.0 * (1.0 - distKm / Math.max(0.1, maxRadiusKm)));
            double monthlyScore = maxMonthlyInPool == 0
                    ? 100.0
                    : Math.max(0.0, 100.0 * (1.0 - (double) monthly / monthlyDivisor));
            double activeScore = Math.max(0.0, 100.0 * (1.0 - (double) active / Math.max(1, maxConcurrent)));
            double onTimeScore = Math.max(0.0, Math.min(100.0, onTime));

            double rawFinal = weights.distance() * distScore
                    + weights.monthlyWorkload() * monthlyScore
                    + weights.activeLoad() * activeScore
                    + weights.onTimeRate() * onTimeScore;

            working.add(new ScoredWorkingItem(
                    staff,
                    round2(distKm),
                    monthly,
                    active,
                    round1(onTime),
                    round1(distScore),
                    round1(monthlyScore),
                    round1(activeScore),
                    round1(onTimeScore),
                    round1(rawFinal),
                    lastAssignedMap.get(sid)));
        }

        // Tie-breaker: finalScore DESC -> monthlyWorkload ASC -> activeProcessing ASC
        // -> distanceKm ASC -> lastAssignedAt ASC (null first) -> staffId ASC
        working.sort(Comparator
                .comparingDouble(ScoredWorkingItem::finalScore).reversed()
                .thenComparingInt(ScoredWorkingItem::monthlyWorkload)
                .thenComparingInt(ScoredWorkingItem::activeProcessingCount)
                .thenComparingDouble(ScoredWorkingItem::distanceKm)
                .thenComparing(ScoredWorkingItem::lastAssignedAt, Comparator.nullsFirst(Comparator.naturalOrder()))
                .thenComparing(item -> item.staff().getId()));

        List<ScoredCandidate> ranked = new ArrayList<>(working.size());
        for (int i = 0; i < working.size(); i++) {
            ScoredWorkingItem item = working.get(i);
            User s = item.staff();
            StaffCandidateScoreResponse dto = StaffCandidateScoreResponse.builder()
                    .rank(i + 1)
                    .staffId(s.getId())
                    .fullName(s.getFullName())
                    .email(s.getEmail())
                    .phoneNumber(s.getPhone())
                    .avatarUrl(s.getAvatarUrl())
                    .positionId(s.getPosition() != null ? s.getPosition().getId() : null)
                    .positionName(s.getPosition() != null ? s.getPosition().getName() : null)
                    .baseLatitude(s.getBaseLatitude())
                    .baseLongitude(s.getBaseLongitude())
                    .baseAddress(s.getBaseAddress())
                    .distanceKm(item.distanceKm())
                    .monthlyWorkload(item.monthlyWorkload())
                    .activeProcessingCount(item.activeProcessingCount())
                    .onTimeRate30d(item.onTimeRate30d())
                    .distanceScore(item.distanceScore())
                    .monthlyWorkloadScore(item.monthlyWorkloadScore())
                    .activeLoadScore(item.activeLoadScore())
                    .onTimeRateScore(item.onTimeRateScore())
                    .finalScore(item.finalScore())
                    .weightDistance(weights.distance())
                    .weightMonthlyWorkload(weights.monthlyWorkload())
                    .weightActiveLoad(weights.activeLoad())
                    .weightOnTimeRate(weights.onTimeRate())
                    .build();
            ranked.add(new ScoredCandidate(s, dto));
        }

        return new PoolEvaluation(category, ranked, null);
    }

    // -------------------------------------------------------------------------
    // Config & helpers
    // -------------------------------------------------------------------------

    private AutoAssignConfig getEffectiveConfig() {
        return autoAssignConfigRepository.findTopByOrderByUpdatedAtDesc()
                .orElseGet(AutoAssignServiceImpl::defaultConfig);
    }

    /** Cấu hình mặc định: ASSIST (chỉ gợi ý, Admin quyết định) cho tới khi có màn cấu hình. */
    private static AutoAssignConfig defaultConfig() {
        return AutoAssignConfig.builder()
                .mode(EAutoAssignMode.ASSIST)
                .distanceWeight(0.45)
                .monthlyWorkloadWeight(0.35)
                .activeLoadWeight(0.15)
                .onTimeRateWeight(0.05)
                .maxRadiusKm(15.0)
                .maxConcurrentTasks(10)
                .targetMonthlyTasks(20)
                .build();
    }

    private static EAutoAssignMode resolveMode(AutoAssignConfig config) {
        return config != null && config.getMode() != null ? config.getMode() : EAutoAssignMode.ASSIST;
    }

    private ReportCategory resolveCategory(Report report) {
        if (report == null || report.getCategory() == null) {
            return null;
        }
        String categoryId = report.getCategory().getId();
        if (categoryId == null || categoryId.isBlank()) {
            return report.getCategory();
        }
        return reportCategoryRepository.findById(categoryId).orElse(report.getCategory());
    }

    private AssignmentDecisionLog buildCandidateLog(
            Report report,
            ReportCategory category,
            AutoAssignConfig config,
            EAssignmentSource source,
            EAssignmentOutcome outcome,
            ScoredCandidate winner,
            int eligibleCount,
            String snapshotJson) {
        StaffCandidateScoreResponse dto = winner.dto();
        return AssignmentDecisionLog.builder()
                .report(report)
                .categoryId(category != null ? category.getId() : null)
                .categoryCode(category != null ? category.getCode() : null)
                .modeAtDecision(resolveMode(config))
                .source(source)
                .outcome(outcome)
                .selectedStaff(winner.staff())
                .finalScore(dto.getFinalScore())
                .distanceKm(dto.getDistanceKm())
                .distanceScore(dto.getDistanceScore())
                .monthlyWorkload(dto.getMonthlyWorkload())
                .monthlyWorkloadScore(dto.getMonthlyWorkloadScore())
                .activeProcessingCount(dto.getActiveProcessingCount())
                .activeLoadScore(dto.getActiveLoadScore())
                .onTimeRate30d(dto.getOnTimeRate30d())
                .onTimeRateScore(dto.getOnTimeRateScore())
                .eligibleCandidateCount(eligibleCount)
                .candidatesSnapshotJson(snapshotJson)
                .build();
    }

    private AssignmentDecisionLog buildFallbackLog(
            Report report,
            ReportCategory category,
            AutoAssignConfig config,
            EAssignmentSource source,
            String fallbackReason) {
        return AssignmentDecisionLog.builder()
                .report(report)
                .categoryId(category != null ? category.getId() : null)
                .categoryCode(category != null ? category.getCode() : null)
                .modeAtDecision(resolveMode(config))
                .source(source)
                .outcome(EAssignmentOutcome.FALLBACK_PENDING)
                .eligibleCandidateCount(0)
                .fallbackReason(fallbackReason)
                .build();
    }

    private String serializeSnapshot(List<ScoredCandidate> candidates, int limit) {
        if (candidates == null || candidates.isEmpty()) {
            return null;
        }
        List<StaffCandidateScoreResponse> slice = candidates.stream()
                .limit(limit)
                .map(ScoredCandidate::dto)
                .collect(Collectors.toList());
        try {
            return objectMapper.writeValueAsString(slice);
        } catch (JsonProcessingException ex) {
            log.warn("[AutoAssign] Failed to serialize candidates snapshot: {}", ex.getMessage());
            return null;
        }
    }

    private List<StaffCandidateScoreResponse> deserializeSnapshot(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<StaffCandidateScoreResponse>>() {
            });
        } catch (Exception ex) {
            log.warn("[AutoAssign] Failed to deserialize candidates snapshot: {}", ex.getMessage());
            return Collections.emptyList();
        }
    }

    private String resolveMessage(String key, Locale locale) {
        try {
            return messageSource.getMessage(key, null, key, locale);
        } catch (Exception ex) {
            return key;
        }
    }

    private static Map<String, Integer> toIntCountMap(List<Object[]> rows) {
        if (rows == null || rows.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, Integer> map = new HashMap<>();
        for (Object[] row : rows) {
            if (row != null && row.length >= 2 && row[0] instanceof String staffId && row[1] instanceof Number cnt) {
                map.put(staffId, cnt.intValue());
            }
        }
        return map;
    }

    private static Map<String, Date> toDateMap(List<Object[]> rows) {
        if (rows == null || rows.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, Date> map = new HashMap<>();
        for (Object[] row : rows) {
            if (row != null && row.length >= 2 && row[0] instanceof String staffId && row[1] instanceof Date date) {
                map.put(staffId, date);
            }
        }
        return map;
    }

    private static Map<String, Double> toOnTimeRateMap(List<Object[]> rows) {
        if (rows == null || rows.isEmpty()) {
            return Collections.emptyMap();
        }
        Map<String, Double> map = new HashMap<>();
        for (Object[] row : rows) {
            if (row != null && row.length >= 3 && row[0] instanceof String staffId
                    && row[1] instanceof Number onTime && row[2] instanceof Number total) {
                long totalCount = total.longValue();
                if (totalCount > 0) {
                    map.put(staffId, (onTime.doubleValue() * 100.0) / totalCount);
                }
            }
        }
        return map;
    }

    private static NormalizedWeights normalizeWeights(AutoAssignConfig config) {
        double wDist = Math.max(0.0, config.getDistanceWeight() != null ? config.getDistanceWeight() : 0.45);
        double wMonth = Math.max(0.0,
                config.getMonthlyWorkloadWeight() != null ? config.getMonthlyWorkloadWeight() : 0.35);
        double wActive = Math.max(0.0, config.getActiveLoadWeight() != null ? config.getActiveLoadWeight() : 0.15);
        double wOnTime = Math.max(0.0, config.getOnTimeRateWeight() != null ? config.getOnTimeRateWeight() : 0.05);
        double sum = wDist + wMonth + wActive + wOnTime;
        if (sum <= 0.0) {
            return new NormalizedWeights(0.45, 0.35, 0.15, 0.05);
        }
        return new NormalizedWeights(wDist / sum, wMonth / sum, wActive / sum, wOnTime / sum);
    }

    private static double safeMaxRadius(AutoAssignConfig config) {
        return (config.getMaxRadiusKm() != null && config.getMaxRadiusKm() > 0)
                ? config.getMaxRadiusKm()
                : 15.0;
    }

    private static int safeMaxConcurrent(AutoAssignConfig config) {
        return (config.getMaxConcurrentTasks() != null && config.getMaxConcurrentTasks() > 0)
                ? config.getMaxConcurrentTasks()
                : 10;
    }

    private static double round1(double val) {
        return Math.round(val * 10.0) / 10.0;
    }

    private static double round2(double val) {
        return Math.round(val * 100.0) / 100.0;
    }

    private static String formatIso(LocalDateTime dt) {
        return dt != null ? dt.format(DateTimeFormatter.ISO_DATE_TIME) : null;
    }

    private record StaffDistancePair(User staff, double distanceKm) {
    }

    private record NormalizedWeights(double distance, double monthlyWorkload, double activeLoad, double onTimeRate) {
    }

    private record ScoredWorkingItem(
            User staff,
            double distanceKm,
            int monthlyWorkload,
            int activeProcessingCount,
            double onTimeRate30d,
            double distanceScore,
            double monthlyWorkloadScore,
            double activeLoadScore,
            double onTimeRateScore,
            double finalScore,
            Date lastAssignedAt) {
    }

    record ScoredCandidate(User staff, StaffCandidateScoreResponse dto) {
    }

    record PoolEvaluation(ReportCategory category, List<ScoredCandidate> candidates, String fallbackReason) {
        static PoolEvaluation fallback(ReportCategory category, String reason) {
            return new PoolEvaluation(category, Collections.emptyList(), reason);
        }

        boolean hasCandidates() {
            return candidates != null && !candidates.isEmpty();
        }
    }
}
