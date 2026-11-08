import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/screen/chat/widgets/admin_chat_role_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminConversationInfoScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const AdminConversationInfoScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<AdminConversationInfoScreen> createState() =>
      _AdminConversationInfoScreenState();
}

class _AdminConversationInfoScreenState
    extends ConsumerState<AdminConversationInfoScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(conversationReportsProvider(widget.conversationId).notifier)
          .loadMore();
    }
  }

  Future<void> _makePhoneCall(
    BuildContext context,
    String? phone,
    AppLocalizations l10n,
  ) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPhoneNumber)),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotMakePhoneCall)),
        );
      }
    }
  }

  Future<void> _handleRefresh(BuildContext context, AppLocalizations l10n) async {
    final success = await ref
        .read(conversationReportsProvider(widget.conversationId).notifier)
        .refreshAndSyncLocalMessages();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.conversationRefreshed : l10n.conversationRefreshFailed,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(conversationReportsProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.conversationInfoTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            tooltip: l10n.resetFilter,
            icon: state.isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: state.isRefreshing
                ? null
                : () => _handleRefresh(context, l10n),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, theme, l10n, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConversationReportsState state,
  ) {
    if (state.isLoading && state.info == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.info == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(conversationReportsProvider(widget.conversationId).notifier)
                    .loadInitial(),
                child: Text(l10n.resetFilter),
              ),
            ],
          ),
        ),
      );
    }

    final info = state.info;
    if (info == null) {
      return const SizedBox.shrink();
    }

    return _buildContent(context, theme, l10n, info, state);
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConversationInfoModel info,
    ConversationReportsState state,
  ) {
    final isAnonymous = info.isAnonymous;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Header Card
          _buildProfileHeader(theme, l10n, info, isAnonymous),

          const SizedBox(height: 16),

          // 2. Action Buttons (Call / Video Call)
          _buildActionButtons(context, theme, l10n, info, isAnonymous),

          const SizedBox(height: 24),

          // 3. Section: Active Linked Reports
          if (state.reports.isNotEmpty) ...[
            _buildActiveReportsSection(context, theme, l10n, state),
            const SizedBox(height: 24),
          ],

          // 4. Conversation Status Notice (Footer)
          _buildStatusBanner(theme, l10n, info.canSendMessage),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    ThemeData theme,
    AppLocalizations l10n,
    ConversationInfoModel info,
    bool isAnonymous,
  ) {
    final displayName = isAnonymous
        ? l10n.anonymousPerson
        : (info.partnerName?.isNotEmpty == true
            ? info.partnerName!
            : l10n.otherUsers);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: isAnonymous
                  ? Icon(
                      Icons.person_outline_rounded,
                      size: 46,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : (info.partnerAvatarUrl != null &&
                          info.partnerAvatarUrl!.isNotEmpty)
                      ? Image.network(
                          info.partnerAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 46,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Center(
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Role & Position Badge
          AdminChatRoleBadge(
            role: info.partnerRole,
            position: info.partnerPosition,
            isCompact: false,
          ),

          // Anonymous privacy note
          if (isAnonymous) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.anonymousUserProtectionNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConversationInfoModel info,
    bool isAnonymous,
  ) {
    if (isAnonymous) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.anonymousUserProtectionNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRoundActionButton(
            theme: theme,
            icon: Icons.phone_rounded,
            label: l10n.callButtonLabel,
            color: Colors.green,
            onTap: () => _makePhoneCall(context, info.partnerPhone, l10n),
          ),
          _buildRoundActionButton(
            theme: theme,
            icon: Icons.videocam_rounded,
            label: l10n.videoCallButtonLabel,
            color: theme.colorScheme.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.videoCallComingSoon)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveReportsSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConversationReportsState state,
  ) {
    final reports = state.reports;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Count Badge
        Row(
          children: [
            Text(
              l10n.activeReportsSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${reports.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (reports.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.allReportsProcessed,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildReportCard(context, theme, l10n, report, isDark);
            },
          ),
          if (state.isLoadingMore) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    LinkedReportModel report,
    bool isDark,
  ) {
    final isRehandling = report.isRehandling;
    final rehandlingBgColor = isDark
        ? Colors.amber.shade900.withValues(alpha: 0.3)
        : Colors.orange.shade50;
    final rehandlingTextColor =
        isDark ? Colors.amber.shade300 : Colors.orange.shade800;

    final processingBgColor = isDark
        ? Colors.blue.shade900.withValues(alpha: 0.3)
        : Colors.blue.shade50;
    final processingTextColor =
        isDark ? Colors.blue.shade300 : Colors.blue.shade700;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRehandling
              ? (isDark ? Colors.amber.shade800 : Colors.orange.shade300)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push(RouterPath.reportDetailWithId(report.id));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (report.imageUrl != null &&
                            report.imageUrl!.isNotEmpty)
                        ? Image.network(
                            report.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.assignment_outlined,
                            color: theme.colorScheme.primary,
                            size: 26,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Report Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Status Badge: Rehandling or Processing
                          if (isRehandling)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: rehandlingBgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.amber.shade700
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.replay_rounded,
                                    size: 11,
                                    color: rehandlingTextColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.rehandlingBadge,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: rehandlingTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: processingBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.reportStatusProcessing,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: processingTextColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),

                          // Severity Badge
                          if (report.severity != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(report.severity!)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getSeverityLabel(l10n, report.severity!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _getSeverityColor(report.severity!),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  String _getSeverityLabel(AppLocalizations l10n, String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return l10n.severityCritical;
      case 'high':
        return l10n.severityHigh;
      case 'medium':
        return l10n.severityMedium;
      case 'low':
      default:
        return l10n.severityLow;
    }
  }

  Widget _buildStatusBanner(
    ThemeData theme,
    AppLocalizations l10n,
    bool canSendMessage,
  ) {
    final bgColor = canSendMessage
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final iconColor = canSendMessage
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final textColor = canSendMessage
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    final text = canSendMessage
        ? l10n.conversationActiveNotice
        : l10n.conversationClosedNotice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            canSendMessage ? Icons.info_outline_rounded : Icons.lock_outline_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
