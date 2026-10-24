import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/features/users/models/user_detail_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/users/user_shared_widgets.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';

/// Mở chi tiết người dùng: Dialog (màn rộng) hoặc bottom sheet (màn hẹp).
void showUserDetail(BuildContext context, String userId) {
  final router = GoRouter.of(context);
  final isWide = MediaQuery.sizeOf(context).width >= 640;

  void openReport(BuildContext overlayContext, String reportId) {
    Navigator.of(overlayContext).pop();
    router.push(RouterPath.reportDetailWithId(reportId));
  }

  if (isWide) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(dialogContext)!.userDetailTitle,
                        style: Theme.of(dialogContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(dialogContext)!.closeAction,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: UserDetailContent(
                    userId: userId,
                    onReportTap: (id) => openReport(dialogContext, id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (sheetContext, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              UserDetailContent(
                userId: userId,
                onReportTap: (id) => openReport(sheetContext, id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nội dung chi tiết người dùng — dùng chung cho Web và Mobile.
class UserDetailContent extends ConsumerWidget {
  final String userId;
  final ValueChanged<String> onReportTap;

  const UserDetailContent({
    super.key,
    required this.userId,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(userDetailProvider(userId));

    return detailAsync.when(
      data: (user) => _UserDetailBody(user: user, onReportTap: onReportTap),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => UserErrorState(
        error: error,
        onRetry: () => ref.invalidate(userDetailProvider(userId)),
      ),
    );
  }
}

class _UserDetailBody extends StatelessWidget {
  final UserDetailModel user;
  final ValueChanged<String> onReportTap;

  const _UserDetailBody({required this.user, required this.onReportTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            PersonAvatar(
              avatarUrl: user.avatarUrl,
              name: user.fullName,
              radius: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName.isEmpty ? user.email : user.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isBlocked) ...[
                        const SizedBox(width: 8),
                        const UserBlockedChip(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  SelectableText(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Thông tin cá nhân
        _InfoRow(
          icon: Icons.phone_outlined,
          label: l10n.phoneNumber,
          value: _orNotProvided(l10n, user.phoneNumber),
        ),
        _InfoRow(
          icon: Icons.wc_outlined,
          label: l10n.gender,
          value: _genderLabel(l10n, user.gender),
        ),
        _InfoRow(
          icon: Icons.cake_outlined,
          label: l10n.dateOfBirth,
          value: user.dateOfBirth == null
              ? l10n.notProvided
              : formatUserDate(user.dateOfBirth),
        ),
        _InfoRow(
          icon: Icons.translate_outlined,
          label: l10n.language,
          value: _languageLabel(l10n, user.language),
        ),
        _InfoRow(
          icon: Icons.event_outlined,
          label: l10n.joinedDate,
          value: formatUserDate(user.createdAt),
        ),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Hoạt động phản ánh
        Text(
          l10n.reportActivity,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          l10n.anonymousReportsExcluded,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _ReportStatsRow(stats: user.reportStats),
        const SizedBox(height: 20),

        Text(
          l10n.recentReports,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (user.recentReports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.noPublicReports,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final report in user.recentReports)
            _RecentReportTile(
              report: report,
              onTap: () => onReportTap(report.id),
            ),
      ],
    );
  }

  static String _orNotProvided(AppLocalizations l10n, String? value) =>
      (value == null || value.trim().isEmpty) ? l10n.notProvided : value;

  static String _genderLabel(AppLocalizations l10n, String? gender) =>
      switch (gender) {
        'male' => l10n.genderMale,
        'female' => l10n.genderFemale,
        'other' => l10n.genderOther,
        _ => l10n.notProvided,
      };

  static String _languageLabel(AppLocalizations l10n, String? language) =>
      switch (language) {
        'vi' => l10n.vietnamese,
        'en' => l10n.english,
        _ => l10n.notProvided,
      };
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Màu + nhãn trạng thái phản ánh theo semantic token.
(Color, String) reportStatusStyle(
  BuildContext context,
  AppLocalizations l10n,
  String? status,
) {
  final theme = Theme.of(context);
  final semantic = AppSemanticColors.of(context);
  return switch (status) {
    'pending' => (semantic.warning, l10n.reportStatusPending),
    'processing' => (theme.colorScheme.primary, l10n.reportStatusProcessing),
    'processed' => (semantic.success, l10n.reportStatusProcessed),
    'rejected' => (theme.colorScheme.error, l10n.reportStatusRejected),
    _ => (theme.colorScheme.onSurfaceVariant, l10n.reportStatusUnknown),
  };
}

class _ReportStatsRow extends StatelessWidget {
  final UserReportStats stats;
  const _ReportStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final entries = [
      ('pending', stats.pending),
      ('processing', stats.processing),
      ('processed', stats.processed),
      ('rejected', stats.rejected),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: stats.total,
              label: l10n.totalReports,
              color: theme.colorScheme.onSurface,
              emphasize: true,
            ),
          ),
          for (final (status, count) in entries)
            Expanded(
              child: switch (reportStatusStyle(context, l10n, status)) {
                (final color, final label) => _StatCell(
                  value: count,
                  label: label,
                  color: color,
                ),
              },
            ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final bool emphasize;

  const _StatCell({
    required this.value,
    required this.label,
    required this.color,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style:
              (emphasize
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  final UserRecentReport report;
  final VoidCallback onTap;

  const _RecentReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final (statusColor, statusLabel) = reportStatusStyle(
      context,
      l10n,
      report.status,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatUserDate(report.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
