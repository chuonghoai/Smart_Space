// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/home/home_controller.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/layout/app_layout.dart';
import 'package:geolocator/geolocator.dart';

class MobileHomeScreen extends ConsumerWidget {
  const MobileHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    return AppLayout(
      child: state.isLoading && state.user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: controller.manualRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.gpsError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_off,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.gpsError,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Greeting Area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage:
                              state.user?.avatarUrl != null &&
                                  state.user!.avatarUrl.isNotEmpty
                              ? NetworkImage(state.user!.avatarUrl)
                              : null,
                          child:
                              state.user?.avatarUrl == null ||
                                  state.user!.avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.welcomeBack},',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                state.user?.fullname ?? l10n.user,
                                style: theme.textTheme.titleLarge?.copyWith(
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
                    const SizedBox(height: 24),

                    // Quick Access Section
                    _buildQuickAccessButtonRow(context, theme, l10n),
                    const SizedBox(height: 24),

                    // Dashboard Section
                    Text(
                      l10n.myWorkDashboard,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (state.isLoading && state.statistics == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildStatisticsGrid(context, state.statistics, l10n),

                    const SizedBox(height: 24),

                    // Assigned Reports Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.needsYourAttention,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(
                              Uri(
                                path: RouterPath.allReports,
                                queryParameters: {'filter': 'all'},
                              ).toString(),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.filterAll),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context,
                            controller,
                            state,
                            'all',
                            l10n.filterAll,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            controller,
                            state,
                            'pending',
                            l10n.reportStatusPending,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            controller,
                            state,
                            'processing',
                            l10n.reportStatusProcessing,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context,
                            controller,
                            state,
                            'resolved',
                            l10n.reportStatusProcessed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (state.isLoading && state.assignedReports.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else if (state.assignedReports.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noReportsYet,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      _buildAssignedReportsList(
                        context,
                        state.assignedReports,
                        state.gpsError == null ? state.currentPosition : null,
                      ),

                    // Bottom spacing
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    HomeController controller,
    HomeState state,
    String value,
    String label,
  ) {
    final isSelected = state.filterStatus == value;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.setFilter(value);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatisticsGrid(
    BuildContext context,
    ReportStatisticsModel? stats,
    AppLocalizations l10n,
  ) {
    if (stats == null) return const SizedBox();

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: l10n.totalAssigned,
          count: stats.total,
          icon: Icons.assignment_outlined,
          color: Colors.blue,
          onTap: () => context.push(
            Uri(
              path: RouterPath.allReports,
              queryParameters: {'filter': 'all'},
            ).toString(),
          ),
        ),
        _StatCard(
          title: l10n.reportStatusPending,
          count: stats.pending,
          icon: Icons.hourglass_empty,
          color: Colors.orange,
          onTap: () => context.push(
            Uri(
              path: RouterPath.allReports,
              queryParameters: {'filter': 'pending'},
            ).toString(),
          ),
        ),
        _StatCard(
          title: l10n.reportStatusProcessing,
          count: stats.processing,
          icon: Icons.autorenew,
          color: Colors.purple,
          onTap: () => context.push(
            Uri(
              path: RouterPath.allReports,
              queryParameters: {'filter': 'processing'},
            ).toString(),
          ),
        ),
        _StatCard(
          title: l10n.reportStatusProcessed,
          count: stats.resolved,
          icon: Icons.task_alt,
          color: Colors.green,
          onTap: () => context.push(
            Uri(
              path: RouterPath.allReports,
              queryParameters: {'filter': 'resolved'},
            ).toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedReportsList(
    BuildContext context,
    List<ReportModel> reports,
    Position? currentPosition,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index];
        return _ReportListItem(report: report, userPosition: currentPosition);
      },
    );
  }

  Widget _buildQuickAccessButtonRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickAccessItem(
          context,
          theme,
          Icons.map_outlined,
          l10n.quickAccessMap,
          () {
            context.push(RouterPath.map);
          },
        ),
        const SizedBox(width: 8),
        _buildQuickAccessItem(
          context,
          theme,
          Icons.newspaper_outlined,
          l10n.quickAccessNews,
          () {
            /* TODO */
          },
        ),
        const SizedBox(width: 8),
        _buildQuickAccessItem(
          context,
          theme,
          Icons.settings_outlined,
          l10n.quickAccessSettings,
          () {
            /* TODO */
          },
        ),
        const SizedBox(width: 8),
        _buildQuickAccessItem(
          context,
          theme,
          Icons.menu_book_outlined,
          l10n.quickAccessGuide,
          () {
            /* TODO */
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? color.shade900.withOpacity(0.3) : color.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? color.shade700 : color.shade200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? color.shade100 : color.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 20,
                    color: isDark ? color.shade300 : color.shade700,
                  ),
                ],
              ),
              Text(
                count.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: isDark ? color.shade50 : color.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final ReportModel report;
  final Position? userPosition;

  const _ReportListItem({required this.report, this.userPosition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Status text mapping
    String statusText = l10n.reportStatusUnknown;
    Color statusColor = Colors.grey;

    switch (report.status) {
      case ReportStatus.pending:
        statusText = l10n.reportStatusPending;
        statusColor = Colors.orange;
        break;
      case ReportStatus.processing:
        statusText = l10n.reportStatusProcessing;
        statusColor = Colors.purple;
        break;
      case ReportStatus.processed:
        statusText = l10n.reportStatusProcessed;
        statusColor = Colors.green;
        break;
      case ReportStatus.rejected:
        statusText = l10n.reportStatusRejected;
        statusColor = Colors.red;
        break;
      default:
        statusText = l10n.reportStatusUnknown;
        statusColor = Colors.grey;
        break;
    }

    // Format date string simply for UI
    final displayDate = report.assignedAt ?? report.createdAt;
    final dateStr =
        '${displayDate.day.toString().padLeft(2, '0')}/${displayDate.month.toString().padLeft(2, '0')}/${displayDate.year} ${displayDate.hour.toString().padLeft(2, '0')}:${displayDate.minute.toString().padLeft(2, '0')}';

    final isNew =
        report.assignedAt != null &&
        DateTime.now().difference(report.assignedAt!) <
            const Duration(hours: 24);

    String? distanceStr;
    if (userPosition != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        userPosition!.latitude,
        userPosition!.longitude,
        report.latitude,
        report.longitude,
      );
      if (distanceInMeters < 1000) {
        distanceStr = '${distanceInMeters.toStringAsFixed(0)} m';
      } else {
        distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    return InkWell(
      onTap: () {
        context.push(RouterPath.reportDetail.replaceFirst(':id', report.id));
      },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
                image: report.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(report.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: report.imageUrl.isEmpty ? const Icon(Icons.image) : null,
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.newLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (distanceStr != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.distanceAway(distanceStr),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
