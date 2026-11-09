import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/features/reports/models/feed_sort.dart';
import 'package:smartspace_client/features/reports/providers/report_feed_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_bar.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_chip.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_options.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_sheet.dart';
import 'package:smartspace_client/ui/mobile/reports/feed/widgets/feed_post_card.dart';

class ReportFeedScreen extends ConsumerStatefulWidget {
  const ReportFeedScreen({super.key});

  @override
  ConsumerState<ReportFeedScreen> createState() => _ReportFeedScreenState();
}

class _ReportFeedScreenState extends ConsumerState<ReportFeedScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(reportFeedProvider).searchQuery;
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(reportFeedProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reportFeedProvider);
    final notifier = ref.read(reportFeedProvider.notifier);

    ref.listen(reportFeedProvider.select((s) => s.nearbyUnavailable), (previous, unavailable) {
      if (unavailable && previous != true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.nearbyLocationUnavailable)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeCommunityFeed), centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          ReportFilterBar(
            searchController: _searchController,
            searchHint: l10n.searchReportsPlaceholder,
            onSearchChanged: notifier.search,
            isFiltering: state.isFiltering,
            onClearFilters: notifier.clearFilters,
            resultCount: state.isLoading ? null : state.totalElements,
            chips: _buildChips(context, state, notifier),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, state, notifier)),
        ],
      ),
    );
  }

  List<Widget> _buildChips(BuildContext context, ReportFeedState state, ReportFeedNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final statusOptions = ReportFilterOptions.feedStatuses(l10n);
    final severityOptions = ReportFilterOptions.severities(l10n);

    return [
      ReportFilterChip(
        label: l10n.sortLabel,
        valueLabel: ReportFilterOptions.sortLabel(state.sort, l10n),
        icon: ReportFilterOptions.sortIcon(state.sort),
        active: state.sort != FeedSort.latest,
        onTap: () => showReportFilterSheet<FeedSort>(
          context: context,
          title: l10n.sortLabel,
          options: ReportFilterOptions.sorts(l10n),
          selected: state.sort,
          onSelected: notifier.setSort,
        ),
      ),
      ReportFilterChip(
        label: l10n.statusLabel,
        valueLabel: ReportFilterOptions.selectedLabel(statusOptions, state.statusFilter),
        active: state.statusFilter != null,
        onTap: () => showReportFilterSheet(
          context: context,
          title: l10n.statusLabel,
          options: statusOptions,
          selected: state.statusFilter,
          onSelected: notifier.setStatus,
        ),
      ),
      ReportFilterChip(
        label: l10n.severityLabel,
        valueLabel: ReportFilterOptions.selectedLabel(severityOptions, state.severityFilter),
        active: state.severityFilter != null,
        onTap: () => showReportFilterSheet(
          context: context,
          title: l10n.severityLabel,
          options: severityOptions,
          selected: state.severityFilter,
          onSelected: notifier.setSeverity,
        ),
      ),
    ];
  }

  Widget _buildBody(BuildContext context, ReportFeedState state, ReportFeedNotifier notifier) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: cs.error),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: notifier.refresh, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: state.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 96),
                Icon(
                  state.isFiltering ? Icons.search_off_rounded : Icons.dynamic_feed_outlined,
                  size: 48,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  state.isFiltering ? l10n.noMatchingReports : l10n.feedEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (state.isFiltering) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        _searchController.clear();
                        notifier.clearFilters();
                      },
                      child: Text(l10n.clearFilters),
                    ),
                  ),
                ],
              ],
            )
          : ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = state.items[i];
                return FeedPostCard(
                  key: ValueKey(item.report.id),
                  item: item,
                  onTap: () => context.push(RouterPath.reportDetail.replaceAll(':id', item.report.id)),
                );
              },
            ),
    );
  }
}
