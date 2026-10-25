import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/home/application/all_activities_notifier.dart';
import 'package:smartspace_admin/features/home/models/recent_activity_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class AdminAllActivitiesScreen extends ConsumerStatefulWidget {
  const AdminAllActivitiesScreen({super.key});

  @override
  ConsumerState<AdminAllActivitiesScreen> createState() =>
      _AdminAllActivitiesScreenState();
}

class _AdminAllActivitiesScreenState
    extends ConsumerState<AdminAllActivitiesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(allActivitiesProvider.notifier).fetchMore();
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _onActivityTap(RecentActivityModel activity) {
    if (activity.targetId == null || activity.targetId!.isEmpty) return;

    final isNews = activity.targetType == 'NEWS' ||
        (activity.targetType == null &&
            (activity.message.toLowerCase().contains('tin tức') ||
                activity.message.toLowerCase().contains('news')));

    final isReport = activity.targetType == 'REPORT' ||
        (activity.targetType == null &&
            (activity.message.toLowerCase().contains('phản ánh') ||
                activity.message.toLowerCase().contains('report')));

    if (isNews) {
      context.push(RouterPath.newsDetailWithId(activity.targetId!));
    } else if (isReport) {
      context.push(RouterPath.reportDetailWithId(activity.targetId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allActivitiesProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppLayout(
      customAppBar: AppBar(
        title: Text(l10n.allActivities),
        centerTitle: false,
      ),
      child: RefreshIndicator(
        onRefresh: () => ref.read(allActivitiesProvider.notifier).refresh(),
        child: Column(
          children: [
            // Filter Bar
            _buildFilterBar(context, l10n, theme, colorScheme, state),
            Divider(height: 1, color: theme.dividerColor),

            // Activity List
            Expanded(
              child: _buildListContent(
                  context, l10n, theme, colorScheme, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    AllActivitiesState state,
  ) {
    final roleFilters = [
      {'key': 'all', 'label': l10n.actorAll},
      {'key': 'admin', 'label': l10n.actorAdmin},
      {'key': 'staff', 'label': l10n.actorStaff},
    ];

    final topicFilters = [
      {'key': 'all', 'label': l10n.topicAll},
      {'key': 'news', 'label': l10n.topicNews},
      {'key': 'report_create', 'label': l10n.topicReportCreate},
      {'key': 'report_assign', 'label': l10n.topicReportAssign},
      {'key': 'report_process', 'label': l10n.topicReportProcess},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Role Filter
          Row(
            children: [
              Text(
                '${l10n.filterActor}:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: roleFilters.map((rf) {
                      final isSelected = state.roleFilter == rf['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(rf['label']!),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(allActivitiesProvider.notifier)
                                .setRoleFilter(rf['key']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Topic Filter
          Row(
            children: [
              Text(
                '${l10n.filterTopic}:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: topicFilters.map((tf) {
                      final isSelected = state.topicFilter == tf['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(tf['label']!),
                          selected: isSelected,
                          onSelected: (_) {
                            ref
                                .read(allActivitiesProvider.notifier)
                                .setTopicFilter(tf['key']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    AllActivitiesState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(allActivitiesProvider.notifier).refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                l10n.noActivitiesFound,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = state.items;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: items.length + (state.isFetchingMore ? 1 : 0),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final activity = items[index];
        final isNews = activity.targetType == 'NEWS' ||
            (activity.targetType == null &&
                (activity.message.toLowerCase().contains('tin tức') ||
                    activity.message.toLowerCase().contains('news')));

        final isReport = activity.targetType == 'REPORT' ||
            (activity.targetType == null &&
                (activity.message.toLowerCase().contains('phản ánh') ||
                    activity.message.toLowerCase().contains('report')));

        final isClickable =
            (isNews || isReport) && activity.targetId != null;

        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isNews
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            backgroundImage: activity.actorAvatarUrl != null
                ? NetworkImage(activity.actorAvatarUrl!)
                : null,
            child: activity.actorAvatarUrl == null
                ? Icon(
                    isNews
                        ? Icons.newspaper_rounded
                        : Icons.person_rounded,
                    size: 18,
                    color: isNews
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          title: Text(
            activity.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              _formatDateTime(activity.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          trailing: isClickable
              ? Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: colorScheme.outline,
                )
              : null,
          onTap: isClickable ? () => _onActivityTap(activity) : null,
        );
      },
    );
  }
}
