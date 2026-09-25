import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/features/reports/models/report_list_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'report_table_view.dart' show SeverityChip;

// Valid flow
const _validTransitions = {
  'pending': ['processing', 'rejected'],
  'processing': ['processed', 'rejected'],
  'processed': <String>[],
  'rejected': <String>[],
};

class _DragData {
  final ReportListItem item;
  final String fromStatus;
  const _DragData(this.item, this.fromStatus);
}

// Board

class ReportKanbanBoard extends ConsumerWidget {
  const ReportKanbanBoard({super.key});

  static const _columns = ['pending', 'processing', 'processed', 'rejected'];

  static const _legend = [
    ('Thấp', Color(0xFF4CAF50)),
    ('Trung bình', Color(0xFFFF9800)),
    ('Cao', Color(0xFFFF5722)),
    ('Nghiêm trọng', Color(0xFFF44336)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            Text(
              'Mức độ: ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            ..._legend.map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: e.$2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      e.$1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Columns
        SizedBox(
          height: 600,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((status) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _KanbanColumn(status: status),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Column

class _KanbanColumn extends ConsumerWidget {
  final String status;

  const _KanbanColumn({required this.status});

  String _columnLabel(String status, AppLocalizations l10n) => switch (status) {
    'pending' => l10n.pendingStatus,
    'processing' => l10n.processingStatus,
    'processed' => l10n.resolvedReports,
    'rejected' => l10n.rejectedReports,
    _ => status,
  };

  Color _columnColor(String status) => switch (status) {
    'pending' => const Color(0xFFFF9800),
    'processing' => const Color(0xFF2196F3),
    'processed' => const Color(0xFF4CAF50),
    'rejected' => const Color(0xFFF44336),
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final columnAsync = ref.watch(kanbanColumnProvider(status));
    final color = _columnColor(status);

    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (details) {
        final allowed = _validTransitions[details.data.fromStatus] ?? [];
        if (!allowed.contains(status)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invalidTransition),
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
        return details.data.fromStatus != status;
      },
      onAcceptWithDetails: (details) async {
        final drag = details.data;

        // Optimistic update
        ref
            .read(kanbanColumnProvider(drag.fromStatus).notifier)
            .removeItem(drag.item.id);
        ref
            .read(kanbanColumnProvider(status).notifier)
            .addItem(drag.item.copyWith(status: status));

        // API call
        final ok = await ref
            .read(reportListProvider.notifier)
            .updateStatus(drag.item.id, status);

        if (!ok) {
          // Rollback
          ref
              .read(kanbanColumnProvider(status).notifier)
              .removeItem(drag.item.id);
          ref
              .read(kanbanColumnProvider(drag.fromStatus).notifier)
              .addItem(drag.item);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cập nhật trạng thái thất bại'),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        }
      },
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? color : theme.dividerColor,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _columnLabel(status, l10n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    columnAsync.when(
                      data: (d) => Text(
                        '${d.items.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Items
              Expanded(
                child: columnAsync.when(
                  data: (data) => ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: data.items.length + (data.hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == data.items.length) {
                        return TextButton.icon(
                          onPressed: () => ref
                              .read(kanbanColumnProvider(status).notifier)
                              .loadMore(),
                          icon: const Icon(Icons.expand_more, size: 16),
                          label: Text(l10n.loadMore),
                        );
                      }
                      final item = data.items[i];
                      return Draggable<_DragData>(
                        data: _DragData(item, status),
                        feedback: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 200,
                            child: _KanbanCard(item: item, isDragging: true),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _KanbanCard(item: item),
                        ),
                        child: _KanbanCard(item: item),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      '$e',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Card

class _KanbanCard extends StatelessWidget {
  final ReportListItem item;
  final bool isDragging;

  const _KanbanCard({required this.item, this.isDragging = false});

  Color _severityColor(String? severity) => switch (severity) {
    'low' => const Color(0xFF4CAF50),
    'medium' => const Color(0xFFFF9800),
    'high' => const Color(0xFFFF5722),
    'critical' => const Color(0xFFF44336),
    _ => Colors.transparent,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _severityColor(item.severity);

    return GestureDetector(
      onTap: () => context.push('${RouterPath.reportDetail}/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDragging
              ? theme.colorScheme.surfaceContainerHigh
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color strip = severity indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Date + severity dot row
                      Row(
                        children: [
                          if (item.severity != null)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (item.severity != null)
                            Text(
                              _severityLabel(item.severity!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: severityColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          const Spacer(),
                          if (item.createdAt != null)
                            Text(
                              DateFormat('dd/MM').format(item.createdAt!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),

                      // Staff row
                      if (item.assignedStaffName != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundImage:
                                  item.assignedStaffAvatarUrl != null
                                  ? NetworkImage(item.assignedStaffAvatarUrl!)
                                  : null,
                              child: item.assignedStaffAvatarUrl == null
                                  ? Text(
                                      item.assignedStaffName![0].toUpperCase(),
                                      style: const TextStyle(fontSize: 8),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.assignedStaffName!,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _severityLabel(String s) => switch (s) {
    'low' => 'Thấp',
    'medium' => 'TB',
    'high' => 'Cao',
    'critical' => 'Nghiêm trọng',
    _ => s,
  };
}
