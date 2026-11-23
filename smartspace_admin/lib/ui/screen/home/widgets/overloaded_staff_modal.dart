import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/staff/application/staff_providers.dart';
import 'package:smartspace_admin/features/staff/models/staff_statistics_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/staff/widgets/staff_workload_badge.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

void showOverloadedStaffModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetCtx) => _OverloadedStaffSheet(
      parentContext: context,
      sheetContext: sheetCtx,
    ),
  );
}

class _OverloadedStaffSheet extends ConsumerWidget {
  final BuildContext parentContext;
  final BuildContext sheetContext;

  const _OverloadedStaffSheet({
    required this.parentContext,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statsAsync = ref.watch(staffStatisticsProvider);
    final fmt = NumberFormat(
      '#,##0.#',
      Localizations.localeOf(context).toLanguageTag(),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  Icon(Icons.manage_accounts_outlined,
                      size: 20, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.overloadedStaffModalTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '$e',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
                data: (stats) {
                  final overloaded = stats.deadlinePerformance
                      .where((item) => item.isOverloaded)
                      .toList();
                  final threshold = math.max(5.0, 1.5 * stats.teamAvgWeightedLoad);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cs.error.withValues(alpha: 0.24)),
                        ),
                        child: Text(
                          l10n.overloadedStaffThresholdInfo(
                            fmt.format(threshold),
                            fmt.format(stats.teamAvgWeightedLoad),
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (overloaded.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              l10n.overloadedStaffEmpty,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: overloaded.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _OverloadedStaffCard(
                              item: overloaded[i],
                              onTap: () {
                                final staff = overloaded[i].staff;
                                Navigator.of(sheetContext).pop();
                                parentContext.push(
                                  '${RouterPath.staffManagement}?staffId=${Uri.encodeComponent(staff.id)}',
                                  extra: staff,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverloadedStaffCard extends StatelessWidget {
  final StaffDeadlinePerformanceItem item;
  final VoidCallback onTap;

  const _OverloadedStaffCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final staff = item.staff;
    final breakdown = staff.severityBreakdown;
    final crit = breakdown['critical'] ?? 0;
    final high = breakdown['high'] ?? 0;
    final med = breakdown['medium'] ?? 0;
    final low = breakdown['low'] ?? 0;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.error.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: staff.avatarUrl,
                width: 40,
                height: 40,
                isCircle: true,
                errorWidget: CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    staff.fullName.isNotEmpty
                        ? staff.fullName[0].toUpperCase()
                        : 'S',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.fullName.isNotEmpty
                                ? staff.fullName
                                : staff.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StaffWorkloadBadge(
                          weightedLoad: item.weightedLoad,
                          processingCount: staff.processingCount,
                          isOverloaded: item.isOverloaded,
                          severityBreakdown: breakdown,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.overloadedStaffMetricsRow(
                        item.weightedLoad,
                        staff.processingCount,
                        item.overdueCount,
                        item.bottleneckCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.overloadedSeverityBreakdownLine(
                        crit,
                        high,
                        med,
                        low,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
