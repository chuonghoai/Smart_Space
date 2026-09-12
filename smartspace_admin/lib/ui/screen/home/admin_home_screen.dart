// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_admin/features/home/application/home_providers.dart';
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
    ref.read(adminOverviewProvider.notifier).refresh();
    ref.read(recentActivityProvider.notifier).refresh();
    ref.read(recentReportProvider(_tabs[_tabController.index]).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildStatCard(l10n.users, data['userCount']?.toString() ?? '0', Icons.people, theme),
                _buildStatCard(l10n.staff, data['staffCount']?.toString() ?? '0', Icons.badge, theme),
                _buildStatCard(l10n.admins, data['adminCount']?.toString() ?? '0', Icons.admin_panel_settings, theme),
                _buildStatCard(l10n.issues, data['issueCount']?.toString() ?? '0', Icons.warning, theme),
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
            color: Colors.black.withOpacity(0.05),
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
              color: theme.primaryColor.withOpacity(0.1),
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
        Text(
          l10n.needsYourAttention,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        pendingReportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return Text('No pending items', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor));
            }
            final count = reports.length;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_late, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have $count pending report(s) that need confirmation.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox(),
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
                    backgroundImage: activity['actorAvatarUrl'] != null ? NetworkImage(activity['actorAvatarUrl']) : null,
                    child: activity['actorAvatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(activity['message'] ?? ''),
                  subtitle: Text(activity['createdAt'] ?? ''),
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
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.hintColor,
          indicatorColor: theme.primaryColor,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pendingConfirmation),
            Tab(text: l10n.inProgress),
            Tab(text: l10n.resolved),
          ],
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
                return _buildReportCard(report, theme);
              },
            );
          },
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Padding(padding: const EdgeInsets.all(16), child: Text('Error: $error', style: TextStyle(color: theme.colorScheme.error))),
        ),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                report['imageUrl'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          if (report['imageUrl'] != null) const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'] ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  report['createdAt'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 8),
                if (report['assignedStaffName'] != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: report['assignedStaffAvatarUrl'] != null
                            ? NetworkImage(report['assignedStaffAvatarUrl'])
                            : null,
                        child: report['assignedStaffAvatarUrl'] == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        report['assignedStaffName'],
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(report['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              report['status'] ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getStatusColor(report['status']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'processed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
