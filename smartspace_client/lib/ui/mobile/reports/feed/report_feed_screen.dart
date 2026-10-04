import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/report_feed_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/reports/feed/widgets/feed_post_card.dart';

class ReportFeedScreen extends ConsumerStatefulWidget {
  const ReportFeedScreen({super.key});

  @override
  ConsumerState<ReportFeedScreen> createState() => _ReportFeedScreenState();
}

class _ReportFeedScreenState extends ConsumerState<ReportFeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(reportFeedProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(reportFeedProvider);
    final notifier = ref.read(reportFeedProvider.notifier);

    final filters = <(String, ReportStatus?)>[
      (l10n.viewAll, null),
      (l10n.reportStatusPending, ReportStatus.pending),
      (l10n.reportStatusProcessing, ReportStatus.processing),
      (l10n.reportStatusProcessed, ReportStatus.processed),
    ];

    Widget body;
    if (state.isLoading && state.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.items.isEmpty) {
      body = Center(
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
    } else {
      body = RefreshIndicator(
        onRefresh: notifier.refresh,
        child: state.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.dynamic_feed_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(l10n.feedEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                ],
              )
            : ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeCommunityFeed), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<FeedTab>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: FeedTab.latest, icon: const Icon(Icons.schedule), label: Text(l10n.feedTabLatest)),
                ButtonSegment(value: FeedTab.nearby, icon: const Icon(Icons.near_me_outlined), label: Text(l10n.feedTabNearby)),
              ],
              selected: {state.tab},
              onSelectionChanged: (s) => notifier.setTab(s.first),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (label, value) = filters[i];
                return ChoiceChip(
                  label: Text(label),
                  selected: state.statusFilter == value,
                  onSelected: (_) => notifier.setFilter(value),
                );
              },
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
