import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_filter_bar.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_kanban_board.dart';
import 'package:smartspace_admin/ui/screen/reports/widgets/report_table_view.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  const ReportListScreen({super.key});

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  final _searchController = TextEditingController();
  // 0 = Table, 1 = Kanban (Web only)
  int _viewMode = 0;

  @override
  void dispose() {
    _searchController.dispose();
    // Reset filter on leave
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(reportListProvider);

    return AppLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportList,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      listAsync.whenOrNull(
                            data: (d) => Text(
                              '${d.totalElements} phản ánh',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ) ??
                          const SizedBox.shrink(),
                    ],
                  ),
                ),

                // View toggle (Web only)
                if (kIsWeb)
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        icon: const Icon(Icons.table_rows_outlined, size: 18),
                        label: Text(l10n.tableView),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: const Icon(Icons.view_kanban_outlined, size: 18),
                        label: Text(l10n.kanbanView),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (s) =>
                        setState(() => _viewMode = s.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter bar
            const ReportFilterBar(),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(reportListProvider.notifier).setSearch(v),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã, tiêu đề, email người gửi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(reportListProvider.notifier).setSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            if (_viewMode == 0 || !kIsWeb)
              const ReportTableView()
            else
              const ReportKanbanBoard(),
          ],
        ),
      ),
    );
  }
}
