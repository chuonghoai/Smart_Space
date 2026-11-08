import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/chat/widgets/chat_role_badge.dart';
import 'package:smartspace_staff/ui/shared/image/app_network_image.dart';

class ConversationItem extends StatefulWidget {
  final ConversationModel conversation;
  final bool isSlidingOut;
  final bool isSlidingIn;
  final bool isPulsing;
  final VoidCallback onTap;

  const ConversationItem({
    super.key,
    required this.conversation,
    this.isSlidingOut = false,
    this.isSlidingIn = false,
    this.isPulsing = false,
    required this.onTap,
  });

  @override
  State<ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<ConversationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.isSlidingIn) {
      _slideAnimation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward();
    } else {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInCubic));
    }
  }

  @override
  void didUpdateWidget(ConversationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSlidingOut && widget.isSlidingOut) {
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInCubic));
      _animController.forward(from: 0.0);
    } else if (!oldWidget.isSlidingIn && widget.isSlidingIn) {
      _slideAnimation = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatTime(BuildContext context, DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0 && now.day == time.day) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 2 && now.day - time.day == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return DateFormat('E', 'vi').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final conv = widget.conversation;
    final hasUnread = conv.unreadCount > 0;

    final displayName = conv.isAnonymous
        ? l10n.anonymousPerson
        : (conv.partnerName?.isNotEmpty == true
            ? conv.partnerName!
            : (conv.name?.isNotEmpty == true ? conv.name! : l10n.conversations));

    final timeStr = _formatTime(context, conv.lastMessageTime ?? conv.createdAt);

    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: widget.isPulsing
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : (hasUnread
                ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.2)
                : Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  _buildAvatar(theme, conv),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            ChatRoleBadge(
                              role: conv.partnerRole,
                              position: conv.partnerPosition,
                              isCompact: true,
                            ),
                            if (conv.reportTitle != null && conv.reportTitle!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '• ${conv.reportTitle}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.lastMessageContent?.isNotEmpty == true
                                    ? conv.lastMessageContent!
                                    : l10n.emptyMessages,
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
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 11,
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
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, ConversationModel conv) {
    if (conv.isAnonymous) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 26,
        ),
      );
    }

    if (conv.partnerAvatarUrl != null && conv.partnerAvatarUrl!.isNotEmpty) {
      return AppNetworkImage(
        url: conv.partnerAvatarUrl,
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
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        (conv.partnerName?.isNotEmpty == true ? conv.partnerName![0] : 'S').toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
