import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';

// Column widths
const _colWidths = <int, TableColumnWidth>{
  0: FixedColumnWidth(60),   // Mã
  1: FlexColumnWidth(2.5),   // Tiêu đề
  2: FixedColumnWidth(100),  // Trạng thái 
  3: FixedColumnWidth(130),  // Mức độ      
  4: FlexColumnWidth(1.5),   // Người gửi
  5: FlexColumnWidth(1.5),   // Nhân viên
  6: FixedColumnWidth(95),   // Ngày tạo
};

class ReportTableView extends ConsumerWidget {
  const ReportTableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(reportListProvider);

    return listAsync.when(
      data: (data) {
        if (data.items.isEmpty) return _buildEmpty(l10n, theme);
        return Column(
          children: [
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // On wide screens: fill full width. On small screens: allow horizontal scroll.
                  final tableWidth = constraints.maxWidth > 860
                      ? constraints.maxWidth
                      : 860.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Table(
                    columnWidths: _colWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      // ponytail: consider TableCellVerticalAlignment.intrinsicHeight for mixed heights
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: theme.dividerColor,
                        width: 0.5,
                      ),
                    ),
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        children: [
                          _hCell(l10n.reportIdShort, theme),
                          _hCell(l10n.reportTitle, theme),
                          _hCell(l10n.statusTitle, theme),
                          _hCell(l10n.severityLabel, theme),
                          _hCell(l10n.reporter, theme),
                          _hCell(l10n.assignee, theme),
                          _hCell(l10n.createdDate, theme),
                        ],
                      ),
                      // Data rows
                      ...data.items.map((r) => TableRow(
                            children: [
                              _dCell(
                                GestureDetector(
                                  onTap: () => context.push(
                                      '${RouterPath.reportDetail}/${r.id}'),
                                  child: Text(
                                    r.id.length > 8
                                        ? r.id.substring(0, 8)
                                        : r.id,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              _dCell(
                                GestureDetector(
                                  onTap: () => context.push(
                                      '${RouterPath.reportDetail}/${r.id}'),
                                  child: Text(
                                    r.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              _dCell(Align(
                                alignment: Alignment.centerLeft,
                                child: StatusChip(r.status, theme),
                              )),
                              _dCell(Align(
                                alignment: Alignment.centerLeft,
                                child: SeverityChip(r.severity, theme, l10n),
                              )),
                              _dCell(Text(
                                r.userName ?? l10n.anonymousUser,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              )),
                              _dCell(Text(
                                r.assignedStaffName ?? '—',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              )),
                              _dCell(Text(
                                r.createdAt != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(r.createdAt!)
                                    : '—',
                                style: theme.textTheme.bodySmall,
                              )),
                            ],
                          )),
                    ],
                  ),
                ),       // SizedBox
                  );     // return SingleChildScrollView
                },       // builder
              ),         // LayoutBuilder
            ),           // Container

            const SizedBox(height: 12),
            _PaginationRow(
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
              theme: theme,
            ),
          ],
        );
      },
      loading: () => _buildShimmer(theme),
      error: (e, _) =>
          Center(child: Text('$e', style: TextStyle(color: theme.colorScheme.error))),
    );
  }

  // Header cell
  Widget _hCell(String label, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      );

  // Data cell
  Widget _dCell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      );

  Widget _buildEmpty(AppLocalizations l10n, ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 44,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text(l10n.noReportsFound,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );

  Widget _buildShimmer(ThemeData theme) => Container(
        height: 260,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
}

// Status chip

class _StatusChip extends StatelessWidget {
  final String status;
  final ThemeData theme;

  const _StatusChip(this.status, this.theme, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending'    => ('Chờ XL',   const Color(0xFFFF9800)),
      'processing' => ('Đang XL',  const Color(0xFF2196F3)),
      'processed'  => ('Đã XL',    const Color(0xFF4CAF50)),
      'rejected'   => ('Từ chối',  const Color(0xFFF44336)),
      _ => (status, theme.colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Severity chip

class _SeverityChip extends StatelessWidget {
  final String? severity;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _SeverityChip(this.severity, this.theme, this.l10n, {super.key});

  @override
  Widget build(BuildContext context) {
    if (severity == null) return const Text('—');
    final (label, color) = switch (severity!) {
      'low'      => (l10n.severityLow,      const Color(0xFF4CAF50)),
      'medium'   => (l10n.severityMedium,   const Color(0xFFFF9800)),
      'high'     => (l10n.severityHigh,     const Color(0xFFFF5722)),
      'critical' => (l10n.severityCritical, const Color(0xFFF44336)),
      _ => (severity!, theme.colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Pagination row 

class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ThemeData theme;

  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.onPrev,
    required this.onNext,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Trang $currentPage / $totalPages  ($totalElements phản ánh)',
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

/// Exported for reuse in Kanban.
class StatusChip extends _StatusChip {
  const StatusChip(super.status, super.theme, {super.key});
}

class SeverityChip extends _SeverityChip {
  const SeverityChip(super.severity, super.theme, super.l10n, {super.key});
}

