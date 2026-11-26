import 'package:flutter/material.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';

class StaffWorkloadBadge extends StatelessWidget {
  final int weightedLoad;
  final int processingCount;
  final bool isOverloaded;
  final String assignmentHint;
  final Map<String, int> severityBreakdown;
  final bool showAssignmentHint;
  final bool compact;

  const StaffWorkloadBadge({
    super.key,
    required this.weightedLoad,
    required this.processingCount,
    this.isOverloaded = false,
    this.assignmentHint = 'normal',
    this.severityBreakdown = const {},
    this.showAssignmentHint = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = AppSemanticColors.of(context);

    final low = severityBreakdown['low'] ?? 0;
    final med = severityBreakdown['medium'] ?? 0;
    final high = severityBreakdown['high'] ?? 0;
    final crit = severityBreakdown['critical'] ?? 0;
    final totalSev = low + med + high + crit;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (weightedLoad > 0 || processingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isOverloaded
                  ? cs.error.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isOverloaded
                    ? cs.error.withValues(alpha: 0.35)
                    : cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              l10n.weightedLoadValue(weightedLoad, processingCount),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: isOverloaded ? cs.error : cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        if (isOverloaded)
          _HintChip(
            label: l10n.staffOverloadedBadge,
            color: cs.error,
            compact: compact,
          )
        else if (showAssignmentHint && assignmentHint == 'recommended')
          _HintChip(
            label: l10n.staffRecommendedBadge,
            color: semantic.success,
            compact: compact,
          ),
        if (totalSev > 0 && !compact)
          SizedBox(
            width: 52,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  if (crit > 0)
                    Expanded(
                      flex: crit,
                      child: Container(color: cs.error),
                    ),
                  if (high > 0)
                    Expanded(
                      flex: high,
                      child: Container(color: semantic.warning),
                    ),
                  if (med > 0)
                    Expanded(
                      flex: med,
                      child: Container(color: semantic.info),
                    ),
                  if (low > 0)
                    Expanded(
                      flex: low,
                      child: Container(color: cs.outline),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _HintChip({
    required this.label,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
