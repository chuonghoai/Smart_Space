import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/chat/widgets/client_chat_role_badge.dart';
import 'package:smartspace_client/ui/shared/image/app_network_image.dart';

class ClientConversationItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ClientConversationItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0 && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('dd/MM HH:mm').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final conv = conversation;
    final hasUnread = conv.unreadCount > 0;
    final isLocked = !conv.canSendMessage;

    final displayName = conv.isAnonymous
        ? l10n.anonymousPerson
        : (conv.partnerName?.isNotEmpty == true
            ? conv.partnerName!
            : (conv.name?.isNotEmpty == true
                ? conv.name!
                : (conv.partnerRole?.toLowerCase() == 'admin'
                    ? l10n.managementBoard
                    : l10n.supportStaff)));

    final timeStr = _formatTime(conv.lastMessageTime ?? conv.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hasUnread
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(theme, conv, isLocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLocked) ...[
                          Icon(
                            Icons.lock_rounded,
                            size: 15,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
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
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ClientChatRoleBadge(
                          role: conv.partnerRole,
                          isCompact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastMessageContent ?? '',
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
                              conv.unreadCount > 99 ? '99+' : conv.unreadCount.toString(),
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
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, ConversationModel conv, bool isLocked) {
    Widget avatarWidget;

    if (conv.isAnonymous) {
      avatarWidget = CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
      );
    } else if (conv.partnerAvatarUrl != null && conv.partnerAvatarUrl!.isNotEmpty) {
      avatarWidget = AppNetworkImage(
        url: conv.partnerAvatarUrl!,
        width: 48,
        height: 48,
        isCircle: true,
        errorWidget: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            (conv.partnerName?.isNotEmpty == true ? conv.partnerName![0] : 'S').toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 18,
            ),
          ),
        ),
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          (conv.partnerName?.isNotEmpty == true ? conv.partnerName![0] : 'S').toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
            fontSize: 18,
          ),
        ),
      );
    }

    if (!isLocked) return avatarWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

