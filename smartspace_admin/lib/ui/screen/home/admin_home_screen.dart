import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/core/auth/user_storage_service.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
import 'package:smartspace_admin/features/home/models/recent_report_model.dart';
import 'package:smartspace_admin/features/notifications/providers/notification_provider.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['all', 'pending', 'processing', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewSection(context, l10n, theme),
              const SizedBox(height: 24),
              _buildNeedsAttentionSection(context, l10n, theme),
              const SizedBox(height: 24),
              _buildRecentActivitySection(context, l10n, theme),
              const SizedBox(height: 24),
              _buildRecentReportSection(context, l10n, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final overviewAsync = ref.watch(adminOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.adminOverview,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        overviewAsync.when(
          data: (data) {
            if (data == null) return const SizedBox();
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(l10n.users, data.userCount.toString(), Icons.people, theme),
                _buildStatCard(l10n.staff, data.staffCount.toString(), Icons.badge, theme),
                _buildStatCard(l10n.admins, data.adminCount.toString(), Icons.admin_panel_settings, theme),
                _buildStatCard(l10n.issues, data.issueCount.toString(), Icons.warning, theme),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(count, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsAttentionSection(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final pendingReportsAsync = ref.watch(recentReportProvider('pending'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.needsYourAttention,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            pendingReportsAsync.maybeWhen(
              data: (reports) => reports.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${reports.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        pendingReportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  l10n.noPendingReports,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
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
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
          error: (error, stack) => Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final activityAsync = ref.watch(recentActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentActivity,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        activityAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return Text(l10n.noRecentActivity, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: activity.actorAvatarUrl != null ? NetworkImage(activity.actorAvatarUrl!) : null,
                    child: activity.actorAvatarUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(activity.message),
                  subtitle: Text(_formatDateTime(activity.createdAt)),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ],
    );
  }

  Widget _buildRecentReportSection(BuildContext context, AppLocalizations l10n, ThemeData theme) {
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
                child: Text(l10n.noReportsYet, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
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
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $error', style: TextStyle(color: theme.colorScheme.error))),
        ),
      ],
    );
  }

  bool _isWithin10Minutes(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(dateTime);
      return !diff.isNegative && diff.inMinutes <= 10;
    } catch (_) {
      return false;
    }
  }

  Widget _buildReportCard(RecentReportModel report, ThemeData theme, AppLocalizations l10n) {
    final isNew = _isWithin10Minutes(report.createdAt);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                report.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          if (report.imageUrl != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(report.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                if (report.assignedStaffName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: report.assignedStaffAvatarUrl != null
                            ? NetworkImage(report.assignedStaffAvatarUrl!)
                            : null,
                        child: report.assignedStaffAvatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        report.assignedStaffName!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isNew) ...[
                _buildNewBadge(theme, isDark, l10n),
                const SizedBox(height: 6),
              ],
              _buildReportStatusBadge(report.status, theme, l10n),
            ],
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

  Widget _buildReportStatusBadge(String? status, ThemeData theme, AppLocalizations l10n) {
    final isDark = theme.brightness == Brightness.dark;
    final color = _getStatusColor(status, isDark);
    final label = _getStatusLabel(status, l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
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
