import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/features/reports/models/auto_assign_models.dart';
import 'package:smartspace_admin/features/reports/models/report_detail_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'package:smartspace_admin/ui/shared/position/position_widgets.dart';

/// Top-N smart staff recommendations panel for pending reports on Detail view.
class SmartRecommendationPanel extends ConsumerWidget {
  final ReportDetailModel report;
  final String? selectedStaffId;
  final bool isSubmitting;
  final ValueChanged<StaffCandidateScoreModel> onSelectCandidate;
  final ValueChanged<StaffCandidateScoreModel> onAssignNow;
  final VoidCallback onAutoAssign;

  const SmartRecommendationPanel({
    super.key,
    required this.report,
    required this.selectedStaffId,
    required this.isSubmitting,
    required this.onSelectCandidate,
    required this.onAssignNow,
    required this.onAutoAssign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final recsAsync = ref.watch(reportRecommendationsProvider(report.id));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined, size: 19, color: cs.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.autoAssignSectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (recsAsync.valueOrNull != null)
                    _ModeChip(mode: recsAsync.valueOrNull!.currentMode),
                  FilledButton.tonalIcon(
                    onPressed:
                        isSubmitting ||
                            recsAsync.isLoading ||
                            (recsAsync.valueOrNull?.candidates.isEmpty ?? false)
                        ? null
                        : onAutoAssign,
                    icon: const Icon(Icons.bolt_rounded, size: 17),
                    label: Text(l10n.autoAssignTriggerButton),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          recsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, _) =>
                _FallbackBox(message: l10n.autoAssignLoadFailed, isError: true),
            data: (recs) {
              if (recs.candidates.isEmpty) {
                return _FallbackBox(
                  message:
                      recs.fallbackMessage ??
                      l10n.autoAssignNoCandidatesDefault,
                  isError: false,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.autoAssignTopCandidates(recs.candidates.length),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.autoAssignEligibleCount(
                          recs.totalEligibleCandidates,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: semantic.info,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < recs.candidates.length; i++) ...[
                    _CandidateRecommendationCard(
                      candidate: recs.candidates[i],
                      isSelected: selectedStaffId == recs.candidates[i].staffId,
                      isSubmitting: isSubmitting,
                      onSelect: () => onSelectCandidate(recs.candidates[i]),
                      onAssignNow: () => onAssignNow(recs.candidates[i]),
                    ),
                    if (i < recs.candidates.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Explanation card rendered on reports that have an auto-assign or 1-tap decision log.
class AutoAssignDecisionExplanationCard extends StatelessWidget {
  final AssignmentDecisionSummaryModel decision;

  const AutoAssignDecisionExplanationCard({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);

    final (badgeLabel, badgeColor) = _resolveOutcomeBadge(
      decision,
      l10n,
      cs,
      semantic,
    );
    final weights = _resolveWeights(decision);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fact_check_outlined, size: 19, color: cs.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.autoAssignDecisionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  badgeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (decision.outcome == 'OVERRIDDEN' &&
              decision.overriddenToStaffName != null &&
              decision.overriddenToStaffName!.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: semantic.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: semantic.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: semantic.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.autoAssignOverriddenNotice(
                        decision.overriddenToStaffName!.trim(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (decision.fallbackReason != null &&
              decision.finalScore == null) ...[
            _FallbackBox(
              message:
                  decision.fallbackMessage ??
                  l10n.autoAssignNoCandidatesDefault,
              isError: false,
            ),
          ] else ...[
            Row(
              children: [
                if (decision.selectedStaffName != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          decision.selectedStaffName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (decision.selectedStaffPositionName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: PositionChip(
                              name: decision.selectedStaffPositionName!,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (decision.finalScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: semantic.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: semantic.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.autoAssignScoreLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          l10n.autoAssignScoreValue(
                            decision.finalScore!.toStringAsFixed(1),
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: semantic.success,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (decision.distanceKm != null)
                  _MetricTile(
                    label: _metricLabel(
                      l10n,
                      l10n.autoAssignDistanceLabel,
                      weights?.$1,
                    ),
                    value: l10n.autoAssignDistanceKm(
                      decision.distanceKm!.toStringAsFixed(2),
                    ),
                    score: decision.distanceScore,
                  ),
                if (decision.monthlyWorkload != null)
                  _MetricTile(
                    label: _metricLabel(
                      l10n,
                      l10n.autoAssignMonthlyLoadLabel,
                      weights?.$2,
                    ),
                    value: l10n.autoAssignTasksCount(decision.monthlyWorkload!),
                    score: decision.monthlyWorkloadScore,
                  ),
                if (decision.activeProcessingCount != null)
                  _MetricTile(
                    label: _metricLabel(
                      l10n,
                      l10n.autoAssignActiveLoadLabel,
                      weights?.$3,
                    ),
                    value: l10n.autoAssignTasksCount(
                      decision.activeProcessingCount!,
                    ),
                    score: decision.activeLoadScore,
                  ),
                if (decision.onTimeRate30d != null)
                  _MetricTile(
                    label: _metricLabel(
                      l10n,
                      l10n.autoAssignOnTimeLabel,
                      weights?.$4,
                    ),
                    value: '${decision.onTimeRate30d!.toStringAsFixed(0)}%',
                    score: decision.onTimeRateScore,
                  ),
              ],
            ),
          ],
          if (decision.candidatesSnapshot.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.autoAssignSnapshotTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < decision.candidatesSnapshot.length; i++)
                    _SnapshotRow(
                      candidate: decision.candidatesSnapshot[i],
                      isWinner:
                          decision.candidatesSnapshot[i].staffId ==
                          decision.selectedStaffId,
                      showDivider: i < decision.candidatesSnapshot.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color) _resolveOutcomeBadge(
    AssignmentDecisionSummaryModel d,
    AppLocalizations l10n,
    ColorScheme cs,
    AppSemanticColors semantic,
  ) {
    if (d.outcome == 'OVERRIDDEN') {
      return (l10n.autoAssignSourceOverridden, semantic.warning);
    }
    if (d.outcome == 'FALLBACK_PENDING') {
      return (l10n.autoAssignSourceFallback, cs.error);
    }
    if (d.outcome == 'RECOMMENDED') {
      return (l10n.autoAssignSourceRecommended, semantic.info);
    }
    if (d.source == 'RECOMMEND_CLICK') {
      return (l10n.autoAssignSourceRecommendClick, semantic.info);
    }
    if (d.source == 'AUTO') {
      return (l10n.autoAssignSourceAuto, semantic.success);
    }
    return (l10n.autoAssignSourceManual, cs.primary);
  }

  /// Trọng số thực tế lúc ra quyết định (lấy từ snapshot backend trả về).
  /// Không có snapshot thì trả null để ẩn phần trăm, tránh đoán sai cấu hình.
  (int, int, int, int)? _resolveWeights(AssignmentDecisionSummaryModel d) {
    if (d.candidatesSnapshot.isEmpty) return null;
    final first = d.candidatesSnapshot.first;
    return (
      (first.weightDistance * 100).round(),
      (first.weightMonthlyWorkload * 100).round(),
      (first.weightActiveLoad * 100).round(),
      (first.weightOnTimeRate * 100).round(),
    );
  }

  String _metricLabel(AppLocalizations l10n, String label, int? weight) =>
      weight == null
      ? label
      : '$label (${l10n.autoAssignWeightPercent(weight)})';
}

class _CandidateRecommendationCard extends StatelessWidget {
  final StaffCandidateScoreModel candidate;
  final bool isSelected;
  final bool isSubmitting;
  final VoidCallback onSelect;
  final VoidCallback onAssignNow;

  const _CandidateRecommendationCard({
    required this.candidate,
    required this.isSelected,
    required this.isSubmitting,
    required this.onSelect,
    required this.onAssignNow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    final isTop = candidate.rank == 1;

    return InkWell(
      onTap: isSubmitting ? null : onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.28)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : isTop
                ? semantic.success.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTop
                        ? semantic.success.withValues(alpha: 0.14)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${candidate.rank}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTop ? semantic.success : cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AppNetworkImage(
                  url: candidate.avatarUrl,
                  width: 36,
                  height: 36,
                  isCircle: true,
                  errorWidget: CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      candidate.fullName.isNotEmpty
                          ? candidate.fullName[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (candidate.positionName != null)
                        PositionChip(name: candidate.positionName!),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isTop ? semantic.success : cs.primary).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.autoAssignScoreValue(
                      candidate.finalScore.toStringAsFixed(1),
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isTop ? semantic.success : cs.primary,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CompactStatBadge(
                  icon: Icons.near_me_outlined,
                  text:
                      '${l10n.autoAssignDistanceLabel}: ${l10n.autoAssignDistanceKm(candidate.distanceKm.toStringAsFixed(1))}',
                ),
                _CompactStatBadge(
                  icon: Icons.calendar_month_outlined,
                  text:
                      '${l10n.autoAssignMonthlyLoadLabel}: ${l10n.autoAssignTasksCount(candidate.monthlyWorkload)}',
                ),
                _CompactStatBadge(
                  icon: Icons.pending_actions_outlined,
                  text:
                      '${l10n.autoAssignActiveLoadLabel}: ${l10n.autoAssignTasksCount(candidate.activeProcessingCount)}',
                ),
                _CompactStatBadge(
                  icon: Icons.verified_outlined,
                  text:
                      '${l10n.autoAssignOnTimeLabel}: ${candidate.onTimeRate30d.toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isSubmitting ? null : onSelect,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    isSelected
                        ? l10n.autoAssignSelectedCandidate
                        : l10n.autoAssignSelectCandidate,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : onAssignNow,
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: Text(l10n.autoAssignAssignNow),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String mode;
  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final (label, color) = switch (mode.toUpperCase()) {
      'AUTO' => (l10n.autoAssignModeAuto, semantic.success),
      'ASSIST' => (l10n.autoAssignModeAssist, semantic.info),
      _ => (l10n.autoAssignModeManual, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompactStatBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CompactStatBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final double? score;
  const _MetricTile({required this.label, required this.value, this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${score!.toStringAsFixed(0)})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final StaffCandidateScoreModel candidate;
  final bool isWinner;
  final bool showDivider;

  const _SnapshotRow({
    required this.candidate,
    required this.isWinner,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '#${candidate.rank}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWinner ? semantic.success : cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  candidate.fullName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l10n.autoAssignDistanceKm(
                  candidate.distanceKm.toStringAsFixed(1),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                candidate.finalScore.toStringAsFixed(1),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWinner ? semantic.success : cs.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}

class _FallbackBox extends StatelessWidget {
  final String message;
  final bool isError;
  const _FallbackBox({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final color = isError ? cs.error : semantic.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
