import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_admin/features/reports/application/report_list_providers.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

/// Mobile card-based view for the report list (replaces table on small screens).
class ReportCardView extends ConsumerWidget {
  const ReportCardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final listAsync = ref.watch(reportListProvider);

    return listAsync.when(
      data: (data) {
        if (data.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 44,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(l10n.noReportsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            ...data.items.map((r) => _ReportCard(report: r)),
            const SizedBox(height: 12),
            _MobilePaginationRow(
              currentPage: data.currentPage,
              totalPages: data.totalPages,
              totalElements: data.totalElements,
              onPrev: data.currentPage > 1
                  ? () => ref
                      .read(reportListProvider.notifier)
                      .setPage(data.currentPage - 1)
                  : null,
              onNext: data.hasNextPage
                  ? () => ref
                      .read(reportListProvider.notifier)
                      .setPage(data.currentPage + 1)
                  : null,
            ),
          ],
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 260,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => Center(
          child:
              Text('$e', style: TextStyle(color: theme.colorScheme.error))),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasImage = report.imageUrl != null &&
        (report.imageUrl as String).trim().isNotEmpty;
    final addressText = (report.address != null &&
            (report.address as String).trim().isNotEmpty)
        ? (report.address as String).trim()
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.1),
          ),
        ),
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              context.push(RouterPath.reportDetailWithId(report.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Image / Media Header ────────────────────────
              if (hasImage)
                Stack(
                  children: [
                    AppNetworkImage(
                      url: report.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorWidget: _buildImagePlaceholder(theme, isDark),
                    ),
                    // Gradient overlay to guarantee contrast over any photo
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Floating badges on top: Severity on left, Status on right
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (report.severity != null)
                            _buildSeverityBadge(
                              report.severity,
                              theme,
                              isDark,
                              l10n,
                              onImage: true,
                            ),
                          const Spacer(),
                          _buildStatusBadge(
                            report.status,
                            theme,
                            isDark,
                            l10n,
                            onImage: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // ── 2. Card Content Body ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // When NO image: Badges + Date row at top of body
                    if (!hasImage) ...[
                      Row(
                        children: [
                          if (report.severity != null) ...[
                            _buildSeverityBadge(
                              report.severity,
                              theme,
                              isDark,
                              l10n,
                              onImage: false,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildStatusBadge(
                            report.status,
                            theme,
                            isDark,
                            l10n,
                            onImage: false,
                          ),
                          const Spacer(),
                          if (report.createdAt != null)
                            _buildDateWidget(report.createdAt!, theme),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else if (report.createdAt != null) ...[
                      // When HAS image: Date row at top of body
                      _buildDateWidget(report.createdAt!, theme),
                      const SizedBox(height: 8),
                    ],

                    // Title
                    Text(
                      report.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Address row (if present)
                    if (addressText != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              addressText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Anonymous Alert Note
                    if (report.isAnonymous) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.anonymousUserNote,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Subtle Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: theme.dividerColor
                            .withValues(alpha: isDark ? 0.2 : 0.12),
                      ),
                    ),

                    // ── 3. Footer Row: Reporter & Staff in distinct columns ──
                    Row(
                      children: [
                        // Left: Reporter
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: report.isAnonymous
                                    ? theme.colorScheme.errorContainer
                                        .withValues(alpha: 0.4)
                                    : theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.4),
                                child: Icon(
                                  report.isAnonymous
                                      ? Icons.visibility_off_outlined
                                      : Icons.person_outline,
                                  size: 14,
                                  color: report.isAnonymous
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.reporter,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      report.userName ?? l10n.anonymousUser,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
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
                        ),

                        Container(
                          height: 24,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: theme.dividerColor.withValues(alpha: 0.15),
                        ),

                        // Right: Assigned Staff
                        Expanded(
                          child: Row(
                            children: [
                              if (report.assignedStaffName != null) ...[
                                if (report.assignedStaffAvatarUrl != null &&
                                    (report.assignedStaffAvatarUrl as String)
                                        .isNotEmpty)
                                  AppNetworkImage(
                                    url: report.assignedStaffAvatarUrl,
                                    width: 28,
                                    height: 28,
                                    isCircle: true,
                                    errorWidget: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: theme
                                          .colorScheme.secondaryContainer
                                          .withValues(alpha: 0.4),
                                      child: Icon(Icons.badge_outlined,
                                          size: 14,
                                          color: theme
                                              .colorScheme.secondary),
                                    ),
                                  )
                                else
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: theme
                                        .colorScheme.secondaryContainer
                                        .withValues(alpha: 0.4),
                                    child: Icon(Icons.badge_outlined,
                                        size: 14,
                                        color: theme
                                            .colorScheme.secondary),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.assignedTo,
                                        style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        report.assignedStaffName!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              theme.colorScheme.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  child: Icon(
                                    Icons.person_add_outlined,
                                    size: 14,
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.assignedTo,
                                        style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        l10n.unassignedStaff,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 36,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildDateWidget(DateTime dateTime, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 13,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String? status,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n, {
    bool onImage = false,
  }) {
    final color = _getStatusColor(status, isDark);
    final label = _getStatusLabel(status, l10n);

    if (onImage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.3),
          width: 1.2,
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
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(
    String? severity,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n, {
    bool onImage = false,
  }) {
    final (label, color) = _getSeverityInfo(severity, isDark, l10n);

    if (onImage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E2624).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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

  (String, Color) _getSeverityInfo(
    String? severity,
    bool isDark,
    AppLocalizations l10n,
  ) {
    switch (severity?.toLowerCase()) {
      case 'low':
        return (
          l10n.severityLow,
          isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32)
        );
      case 'medium':
        return (
          l10n.severityMedium,
          isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825)
        );
      case 'high':
        return (
          l10n.severityHigh,
          isDark ? const Color(0xFFFF7043) : const Color(0xFFFF5722)
        );
      case 'critical':
        return (
          l10n.severityCritical,
          isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828)
        );
      default:
        return (
          severity ?? '—',
          isDark ? Colors.grey[400]! : Colors.grey[600]!
        );
    }
  }
}

class _MobilePaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _MobilePaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$currentPage / $totalPages ($totalElements)',
          style: theme.textTheme.bodySmall,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
