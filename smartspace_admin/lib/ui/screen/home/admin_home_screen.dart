import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/new_reports_slider.dart';
import 'package:smartspace_admin/ui/screen/home/widgets/admin_quick_access_bar.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_card.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['all', 'pending', 'processing', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      connectionManager.resumeConnections();
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Re-render for new tab selection
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final currentTab = _tabs[_tabController.index];
    ref.invalidate(newsListProvider);
    ref.invalidate(pendingWithdrawalCountProvider);
    final futures = <Future<void>>[
      userStorageService.getUser(),
      ref.read(adminOverviewProvider.notifier).refresh(),
      ref.read(recentActivityProvider.notifier).refresh(),
      ref.read(recentReportProvider('pending').notifier).refresh(),
      ref.read(notificationProvider.notifier).fetchCount(forceRefresh: true),
    ];
    if (currentTab != 'pending') {
      futures.add(ref.read(recentReportProvider(currentTab).notifier).refresh());
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24.0 : 16.0,
                vertical: isDesktop ? 24.0 : 16.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Dashboard Desktop Header (Linear / Stripe style)
                      _buildDashboardHeader(context, l10n, theme, isDesktop),

                      // 2. Overview Stats Section (Key Metrics KPI)
                      _buildOverviewSection(context, l10n, theme, isDesktop),
                      const SizedBox(height: 24),

                      // 3. Body: Desktop Bento Split vs Mobile Sequential
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Column (flex: 7)
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Phản ánh gần đây
                                  _buildRecentReportSection(context, l10n, theme),
                                  const SizedBox(height: 28),
                                  // Tin tức mới nhất
                                  _buildLatestNewsSection(context, l10n, theme),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Side Column (380px)
                            SizedBox(
                              width: 380,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Quick Access Panel (Matrix Grid)
                                  const AdminQuickAccessBar(isPanelMode: true),
                                  const SizedBox(height: 24),
                                  // Live Urgent Incidents Monitor
                                  const NewReportsSlider(),
                                  const SizedBox(height: 24),
                                  // Recent Activity Timeline Card
                                  _buildRecentActivitySection(
                                    context,
                                    l10n,
                                    theme,
                                    isSidePanel: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile Layout: Sequential flow
                        const NewReportsSlider(),
                        const SizedBox(height: 20),
                        const AdminQuickAccessBar(isPanelMode: false),
                        const SizedBox(height: 24),
                        _buildRecentReportSection(context, l10n, theme),
                        const SizedBox(height: 24),
                        _buildLatestNewsSection(context, l10n, theme),
                        const SizedBox(height: 24),
                        _buildRecentActivitySection(
                          context,
                          l10n,
                          theme,
                          isSidePanel: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardHeader(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDesktop,
  ) {
    if (!isDesktop) return const SizedBox.shrink();
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.adminPortalBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adminOverview,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.adminPortalSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.retry),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDesktop,
  ) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final pendingWithdrawalCount =
        ref.watch(pendingWithdrawalCountProvider).valueOrNull ?? 0;

    return overviewAsync.when(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final hasUnsatisfactory =
            (data.unsatisfactoryProcessedCount > 0 ||
                data.rehandlingProcessingCount > 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasUnsatisfactory) ...[
              _buildUnsatisfactoryBanner(context, data, theme, l10n),
              const SizedBox(height: 16),
            ],
            if (pendingWithdrawalCount > 0) ...[
              _buildHomeWithdrawalBanner(
                context,
                pendingWithdrawalCount,
                theme,
                l10n,
              ),
              const SizedBox(height: 16),
            ],
            if (!isDesktop) ...[
              Text(
                l10n.adminOverview,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final int crossAxisCount = width >= 1100
                    ? 6
                    : (width >= 650 ? 3 : 2);
                final double extent = width >= 1100 ? 84 : 78;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: extent,
                  children: [
                    _buildStatCard(
                      l10n.users,
                      data.userCount.toString(),
                      Icons.people_outline,
                      theme,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      l10n.staff,
                      data.staffCount.toString(),
                      Icons.badge_outlined,
                      theme,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      l10n.admins,
                      data.adminCount.toString(),
                      Icons.admin_panel_settings_outlined,
                      theme,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      l10n.issues,
                      data.issueCount.toString(),
                      Icons.warning_amber_rounded,
                      theme,
                      Colors.red,
                    ),
                    _buildStatCard(
                      l10n.pendingIssues,
                      data.pendingCount.toString(),
                      Icons.hourglass_top_outlined,
                      theme,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      l10n.processingIssues,
                      data.processingCount.toString(),
                      Icons.autorenew_rounded,
                      theme,
                      Colors.teal,
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        'Error: $error',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }

  Widget _buildUnsatisfactoryBanner(
    BuildContext context,
    dynamic data,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2E1704) : const Color(0xFFFFF7ED);
    final border = isDark ? const Color(0xFF7C2D12) : const Color(0xFFFED7AA);
    final titleColor = isDark ? const Color(0xFFFFEDD5) : const Color(0xFF9A3412);
    final chipBg = isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RouterPath.unsatisfactoryReports),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFFF97316))
                    .withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  color: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.unsatisfactoryBannerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (data.unsatisfactoryProcessedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.unsatisfactoryProcessedCountFormat(
                                  data.unsatisfactoryProcessedCount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFFDBA74)
                                    : const Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        if (data.rehandlingProcessingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.rehandlingProcessingCountFormat(
                                  data.rehandlingProcessingCount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFFDBA74)
                                    : const Color(0xFFC2410C),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeWithdrawalBanner(
    BuildContext context,
    int count,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C1E0A) : const Color(0xFFFFF8E1);
    final border = isDark ? const Color(0xFF7A4A0A) : const Color(0xFFFFE082);
    final titleColor = isDark ? const Color(0xFFFFCC80) : const Color(0xFFBF360C);
    final subtitleColor = isDark
        ? const Color(0xFFFFB74D).withValues(alpha: 0.8)
        : const Color(0xFFD84315);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await context
              .push('${RouterPath.adminWithdrawalRequests}?filter=PENDING');
          ref.invalidate(pendingWithdrawalCountProvider);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFFF57F17))
                    .withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF7A4A0A) : const Color(0xFFFFE082),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notification_important_rounded,
                  color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homePendingWithdrawalBanner(count),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homePendingWithdrawalSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    ThemeData theme, [
    Color? customColor,
  ]) {
    final color = customColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final selectedTab = _tabs[_tabController.index];
    final reportsAsync = ref.watch(recentReportProvider(selectedTab));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentReports,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 500;
            return TabBar(
              controller: _tabController,
              isScrollable: !isWide,
              tabAlignment: isWide ? TabAlignment.fill : TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.hintColor,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: theme.dividerColor.withValues(alpha: 0.12),
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: l10n.all),
                Tab(text: l10n.pendingConfirmation),
                Tab(text: l10n.inProgress),
                Tab(text: l10n.resolved),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.noReportsYet,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              );
            }
            return Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 720 && reports.length > 1) {
                      final cardWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: reports.map((report) {
                          return SizedBox(
                            width: cardWidth,
                            child: _buildReportCard(report, theme, l10n),
                          );
                        }).toList(),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _buildReportCard(report, theme, l10n);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push(RouterPath.reportDashboard),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(l10n.viewAllReports),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestNewsSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final latestNewsAsync = ref.watch(latestNewsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.latestNews,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(RouterPath.newsManagement),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(l10n.viewAllNews),
            ),
          ],
        ),
        const SizedBox(height: 12),
        latestNewsAsync.when(
          data: (newsList) {
            if (newsList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  l10n.emptyNewsTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 650 && newsList.length > 1) {
                  final cardWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: newsList.map((news) {
                      return SizedBox(
                        width: cardWidth,
                        child: NewsCard(news: news),
                      );
                    }).toList(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: newsList.map((news) => NewsCard(news: news)).toList(),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error.toString(),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    bool isSidePanel = false,
  }) {
    final activityAsync = ref.watch(recentActivityProvider);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (isSidePanel) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      l10n.recentActivity,
                      style: isSidePanel
                          ? theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)
                          : theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(RouterPath.allActivities),
              child: Text(l10n.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activityAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return Text(
                l10n.noRecentActivity,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: isSidePanel && activities.length > 6
                  ? 6
                  : activities.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final activity = activities[index];
                final isNewsActivity = activity.targetId != null &&
                    (activity.targetType == 'NEWS' ||
                        (activity.targetType == null &&
                            (activity.message.toLowerCase().contains('tin tức') ||
                                activity.message.toLowerCase().contains('news'))));

                final isReportActivity = activity.targetId != null &&
                    (activity.targetType == 'REPORT' ||
                        (activity.targetType == null &&
                            (activity.message.toLowerCase().contains('phản ánh') ||
                                activity.message.toLowerCase().contains('report'))));

                final isClickable =
                    (isNewsActivity || isReportActivity) && activity.targetId != null;

                return ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundImage: activity.actorAvatarUrl != null
                        ? NetworkImage(activity.actorAvatarUrl!)
                        : null,
                    child: activity.actorAvatarUrl == null
                        ? Icon(
                            isNewsActivity ? Icons.newspaper : Icons.person,
                            size: 15,
                          )
                        : null,
                  ),
                  title: Text(
                    activity.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  subtitle: Text(
                    _formatDateTime(activity.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isClickable
                      ? Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: theme.hintColor,
                        )
                      : null,
                  onTap: isNewsActivity
                      ? () => context
                          .push(RouterPath.newsDetailWithId(activity.targetId!))
                      : (isReportActivity && activity.targetId != null)
                          ? () => context.push(
                              RouterPath.reportDetailWithId(activity.targetId!))
                          : null,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(
            'Error: $error',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );

    if (isSidePanel) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  bool _isWithin1Hour(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      return !diff.isNegative && diff.inMinutes <= 60;
    } catch (_) {
      return false;
    }
  }

  Widget _buildReportCard(
    RecentReportModel report,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isNew = _isWithin1Hour(report.createdAt);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push(RouterPath.reportDetailWithId(report.id)),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
              AppNetworkImage(
                url: report.imageUrl,
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(10),
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_not_supported, size: 24),
                ),
              ),
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (report.isAnonymous) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 12,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.anonymousUserNote,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.error,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(report.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor, fontSize: 11),
                  ),
                  if (report.assignedStaffName != null &&
                      report.assignedStaffName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
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
                        Expanded(
                          child: Text(
                            report.assignedStaffName!,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isNew) ...[
                  _buildNewBadge(theme, isDark, l10n),
                  const SizedBox(height: 6),
                ],
                if (report.isReviewResolved == false) ...[
                  _buildRehandlingBadge(theme, isDark, l10n),
                  const SizedBox(height: 6),
                ],
                _buildReportStatusBadge(report.status, theme, l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRehandlingBadge(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final badgeBg = isDark ? const Color(0xFF4A2800) : const Color(0xFFFFF3E0);
    final badgeColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh_rounded, size: 10, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            l10n.rehandlingBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final badgeBg = isDark ? const Color(0xFF5C1D1D) : const Color(0xFFFFEBEE);
    final badgeColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Text(
        l10n.newBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildReportStatusBadge(
    String? status,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final color = _getStatusColor(status, isDark);
    final label = _getStatusLabel(status, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String? status, AppLocalizations l10n) {
    switch (status?.toLowerCase()) {
      case 'processed':
      case 'resolved':
        return l10n.reportStatusProcessed;
      case 'processing':
        return l10n.reportStatusProcessing;
      case 'pending':
        return l10n.reportStatusPending;
      case 'rejected':
        return l10n.reportStatusRejected;
      default:
        return l10n.reportStatusUnknown;
    }
  }

  Color _getStatusColor(String? status, bool isDark) {
    switch (status?.toLowerCase()) {
      case 'processed':
      case 'resolved':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
      case 'processing':
        return isDark ? const Color(0xFF26A69A) : const Color(0xFF00796B);
      case 'pending':
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFF57F17);
      case 'rejected':
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }
}
