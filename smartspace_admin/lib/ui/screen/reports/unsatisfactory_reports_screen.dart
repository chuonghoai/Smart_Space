import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/reports/application/report_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class UnsatisfactoryReportsScreen extends ConsumerStatefulWidget {
  const UnsatisfactoryReportsScreen({super.key});

  @override
  ConsumerState<UnsatisfactoryReportsScreen> createState() => _UnsatisfactoryReportsScreenState();
}

class _UnsatisfactoryReportsScreenState extends ConsumerState<UnsatisfactoryReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(adminOverviewProvider);
    final pendingAsync = ref.watch(unsatisfactoryReportsProvider('pending'));
    final processingAsync = ref.watch(unsatisfactoryReportsProvider('processing'));

    final pendingCount = pendingAsync.valueOrNull?.length ?? overviewAsync.valueOrNull?.unsatisfactoryProcessedCount;
    final processingCount = processingAsync.valueOrNull?.length ?? overviewAsync.valueOrNull?.rehandlingProcessingCount;

    return AppLayout(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouterPath.home);
              }
            },
          ),
          title: Text(
            l10n.unsatisfactoryBannerTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  _buildTab(
                    label: l10n.unsatisfactoryPendingTab,
                    count: pendingCount?.toInt(),
                    isSelected: _tabController.index == 0,
                    theme: theme,
                  ),
                  _buildTab(
                    label: l10n.unsatisfactoryProcessingTab,
                    count: processingCount?.toInt(),
                    isSelected: _tabController.index == 1,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _UnsatisfactoryReportListTab(
              tab: 'pending',
              emptyMessage: l10n.noUnsatisfactoryPending,
            ),
            _UnsatisfactoryReportListTab(
              tab: 'processing',
              emptyMessage: l10n.noUnsatisfactoryProcessing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required int? count,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.22)
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnsatisfactoryReportListTab extends ConsumerWidget {
  final String tab;
  final String emptyMessage;

  const _UnsatisfactoryReportListTab({
    required this.tab,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final asyncReports = ref.watch(unsatisfactoryReportsProvider(tab));

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(unsatisfactoryReportsProvider(tab).notifier).refresh(),
          ref.read(adminOverviewProvider.notifier).refresh(),
        ]);
      },
      child: asyncReports.when(
        data: (reports) {
          if (reports.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _UnsatisfactoryReportCard(report: report);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.read(unsatisfactoryReportsProvider(tab).notifier).refresh(),
                        child: Text(l10n.loading),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsatisfactoryReportCard extends StatelessWidget {
  final RecentReportModel report;

  const _UnsatisfactoryReportCard({required this.report});

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasImage = report.imageUrl != null && report.imageUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RouterPath.reportDetailWithId(report.id)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                AppNetworkImage(
                  url: report.imageUrl,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(10),
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Row(
                      children: [
                        // Rehandling badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4A2800) : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFFB74D).withValues(alpha: isDark ? 0.5 : 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 11,
                                color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.rehandlingBadge,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        _buildStatusBadge(report.status, theme, isDark, l10n),
                        const Spacer(),
                        if (report.createdAt != null)
                          Text(
                            _formatDateTime(report.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      report.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Address
                    if (report.address != null && report.address!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.address!.trim(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Assigned staff info
                    if (report.assignedStaffName != null && report.assignedStaffName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AppNetworkImage(
                            url: report.assignedStaffAvatarUrl,
                            width: 20,
                            height: 20,
                            isCircle: true,
                            errorWidget: CircleAvatar(
                              radius: 10,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: const Icon(Icons.person, size: 12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            report.assignedStaffName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status, ThemeData theme, bool isDark, AppLocalizations l10n) {
    Color color;
    String label;

    switch (status?.toLowerCase()) {
      case 'processing':
        color = Colors.teal;
        label = l10n.reportStatusProcessing;
        break;
      case 'processed':
      case 'resolved':
        color = Colors.green;
        label = l10n.reportStatusProcessed;
        break;
      default:
        color = Colors.orange;
        label = status ?? '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
