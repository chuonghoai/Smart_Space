import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/core/theme/app_semantic_colors.dart';
import 'package:mobile_shared/features/call/models/call_models.dart';
import 'package:mobile_shared/features/call/providers/call_controller.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/widgets/chat_call_bottom_sheet.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_request_form.dart';
import 'package:smartspace_admin/features/users/models/user_detail_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/users/user_shared_widgets.dart';
import 'package:smartspace_admin/ui/shared/image/person_avatar.dart';
import 'package:smartspace_admin/ui/shared/report_status/report_status_style.dart';

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

class _UserDetailBody extends ConsumerStatefulWidget {
  final UserDetailModel user;
  final ValueChanged<String> onReportTap;

  const _UserDetailBody({required this.user, required this.onReportTap});

  @override
  ConsumerState<_UserDetailBody> createState() => _UserDetailBodyState();
}

class _UserDetailBodyState extends ConsumerState<_UserDetailBody> {
  CommunicationEligibilityModel? _eligibility;
  bool _eligibilityLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  Future<void> _loadEligibility() async {
    try {
      final res = await chatRepository.checkCommunicationEligibility(
        targetUserId: widget.user.id,
        isAnonymous: false,
      );
      if (!mounted) return;
      setState(() {
        _eligibility = res.data;
        _eligibilityLoaded = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _eligibilityLoaded = true);
      }
    }
  }

  Future<CommunicationEligibilityModel?> _ensureEligibility() async {
    if (_eligibilityLoaded) return _eligibility;
    await _loadEligibility();
    return _eligibility;
  }

  Future<void> _openCallSheet(BuildContext context, UserDetailModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final eligibility = await _ensureEligibility();
    if (!mounted) return;

    final phone = user.phoneNumber?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final canFreeCall = eligibility?.canVoiceCall ?? false;
    final displayName = user.fullName.isEmpty ? user.email : user.fullName;

    await ChatCallBottomSheet.show(
      context,
      partnerName: displayName,
      partnerPhone: hasPhone ? phone : null,
      canCellularCall: hasPhone,
      canFreeCall: canFreeCall,
      freeCallDisabledReason:
          eligibility?.reasonMessage ?? l10n.cannotMessageClientMessage,
      titleText: l10n.callOptionsTitle,
      cellularCallTitle: l10n.cellularCall,
      cellularCallDesc: l10n.cellularCallDesc,
      freeCallTitle: l10n.freeCall,
      freeCallDesc: l10n.callFreeVoiceDesc,
      phoneNotAvailableText: l10n.phoneNotAvailable,
      onFreeCallTap: () {
        ref.read(callControllerProvider.notifier).startCall(
              targetUserId: user.id,
              isAnonymous: false,
              peerName: displayName,
              peerAvatar: user.avatarUrl,
              peerRole: 'client',
            );
      },
    );
  }

  Future<void> _handleStartChat(BuildContext context, UserDetailModel user) async {
    final l10n = AppLocalizations.of(context)!;
    final eligibility = await _ensureEligibility();
    if (!mounted) return;

    if (eligibility?.canMessage == true) {
      try {
        final convRes = await chatRepository.createOrGetConversation(
          participantIds: [user.id],
          isAnonymous: false,
        );
        if (!mounted) return;
        if (convRes.success && convRes.data != null) {
          final router = GoRouter.of(context);
          final displayName = user.fullName.isEmpty ? user.email : user.fullName;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          router.push(
            RouterPath.chatDetailWithId(convRes.data!.id),
            extra: ParticipantModel(
              userId: user.id,
              name: displayName,
              avatarUrl: user.avatarUrl,
              role: 'client',
            ),
          );
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.info_outline_rounded, color: Theme.of(ctx).colorScheme.primary, size: 28),
        title: Text(l10n.cannotMessageClientTitle),
        content: Text(l10n.cannotMessageClientMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.closeAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = widget.user;
    final onReportTap = widget.onReportTap;

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
        const SizedBox(height: 16),

        // Action buttons: Nhắn tin & Gọi điện
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(l10n.chatWithUser),
                onPressed: () => _handleStartChat(context, user),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: Text(l10n.callUser),
                onPressed: () => _openCallSheet(context, user),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Khóa / mở khóa (khóa chỉ qua biểu quyết của Hội đồng quản trị)
        _AccountLockSection(user: user),
        const SizedBox(height: 16),

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

/// Trạng thái khóa của người dùng:
/// - Có đề xuất chờ biểu quyết → banner + "Xem đề xuất".
/// - Đã bị khóa → "Mở khoá tài khoản" (một admin, bắt buộc lý do).
/// - Đang hoạt động → "Đề xuất khoá tài khoản".
class _AccountLockSection extends StatelessWidget {
  final UserDetailModel user;

  const _AccountLockSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pendingId = user.pendingLockRequestId;

    if (pendingId != null) {
      final warning = AppSemanticColors.of(context).warning;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.how_to_vote_outlined, size: 20, color: warning),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.lockPendingBanner, style: theme.textTheme.bodySmall)),
            TextButton(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.of(context).pop(); // đóng dialog / bottom sheet chi tiết
                router.push(RouterPath.adminBoardLockRequests(pendingId));
              },
              child: Text(l10n.viewLockProposal),
            ),
          ],
        ),
      );
    }

    if (user.isBlocked) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.lock_open, size: 18),
        label: Text(l10n.unlockAccount),
        onPressed: () => showUnlockUserDialog(context, user),
      );
    }

    if (!user.isActive) return const SizedBox.shrink();

    // Không đủ điều kiện → nút vẫn đọc được và nói rõ vì sao (không để admin điền form rồi mới bị từ chối)
    final blockedText = switch (user.lockProposalBlockedReason) {
      'not_enough_admins' => l10n.lockBlockedNotEnoughAdmins(kLockRequiredApprovals + 1),
      'not_active' => l10n.lockBlockedNotActive,
      _ => null,
    };
    final enabled = blockedText == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline, size: 18),
          label: Text(l10n.proposeLockAction),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.error,
            disabledForegroundColor: cs.onSurfaceVariant,
            side: BorderSide(color: enabled ? cs.error.withValues(alpha: 0.6) : theme.dividerColor),
          ),
          onPressed: enabled ? () => showLockRequestForm(context, user) : null,
        ),
        if (blockedText != null) ...[
          const SizedBox(height: 6),
          Text(blockedText, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ],
    );
  }
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
