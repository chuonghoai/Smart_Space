import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

class AdminConversationItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const AdminConversationItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  String _formatTime(BuildContext context, DateTime? time) {
    if (time == null) return '';
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != time.day)) {
      return l10n.yesterday;
    } else if (diff.inDays < 7) {
      return DateFormat('EEE', 'vi').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final displayName = conversation.isAnonymous
        ? l10n.anonymousUser
        : (conversation.partnerName ?? conversation.name ?? l10n.conversations);

    final avatarUrl = conversation.isAnonymous ? null : (conversation.partnerAvatarUrl ?? conversation.conversationAvatar);

    final hasUnread = conversation.unreadCount > 0;
    final timeStr = _formatTime(context, conversation.lastMessageTime ?? conversation.createdAt);

    Color roleColor;
    String roleLabel;
    final partnerRole = conversation.partnerRole?.toLowerCase();
    if (partnerRole == 'client') {
      roleColor = Colors.orange;
      roleLabel = l10n.filterRoleClient;
    } else if (partnerRole == 'staff') {
      roleColor = Colors.blue;
      final pos = conversation.partnerPosition;
      roleLabel = (pos != null && pos.isNotEmpty) ? '${l10n.filterRoleStaff} • $pos' : l10n.filterRoleStaff;
    } else if (partnerRole == 'admin') {
      roleColor = Colors.purple;
      roleLabel = l10n.filterRoleAdmin;
    } else {
      roleColor = theme.colorScheme.primary;
      roleLabel = '';
    }

    final containerColor = isSelected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : (hasUnread ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : Colors.transparent);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: containerColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppNetworkImage(
                  url: avatarUrl,
                  width: 48,
                  height: 48,
                  isCircle: true,
                  errorWidget: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      conversation.isAnonymous ? Icons.shield_outlined : Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                ),
                if (!conversation.canSendMessage)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 11,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasUnread
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (roleLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          conversation.lastMessageContent ?? l10n.noConversationsSub,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99 ? '99+' : conversation.unreadCount.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

