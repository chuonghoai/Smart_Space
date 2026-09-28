import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_table_view.dart';

/// Mobile card-based view for the report list (replaces table on small screens).
class ReportCardView extends ConsumerWidget {
  const ReportCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(reportListProvider);

    return listAsync.when(
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 44,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(l10n.noReportsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            ...data.items.map((r) => _ReportCard(report: r)),
            const SizedBox(height: 12),
            _MobilePaginationRow(
              currentPage: data.currentPage,
              totalPages: data.totalPages,
              totalElements: data.totalElements,
              onPrev: data.currentPage > 1
                  ? () => ref
                      .read(reportListProvider.notifier)
                      .setPage(data.currentPage - 1)
                  : null,
              onNext: data.hasNextPage
                  ? () => ref
                      .read(reportListProvider.notifier)
                      .setPage(data.currentPage + 1)
                  : null,
            ),
          ],
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Center(
          child:
              Text('$e', style: TextStyle(color: theme.colorScheme.error))),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: InkWell(
          onTap: () =>
              context.push('/reports/${report.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(report.status, theme),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: Severity + Date
                Row(
                  children: [
                    if (report.severity != null) ...[
                      SeverityChip(report.severity, theme, l10n),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    if (report.createdAt != null)
                      Text(
                        DateFormat('dd/MM/yyyy').format(report.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 3: Reporter + Assignee
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.userName ?? l10n.anonymousUser,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (report.assignedStaffName != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.assignment_ind_outlined,
                          size: 14,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.assignedStaffName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobilePaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _MobilePaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$currentPage / $totalPages ($totalElements)',
          style: theme.textTheme.bodySmall,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
