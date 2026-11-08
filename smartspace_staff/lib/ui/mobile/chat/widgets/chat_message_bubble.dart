import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartspace_staff/features/chat/models/chat_message_model.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onRetry;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.content,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    final bubbleBg = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final timeColor = isMe
        ? theme.colorScheme.onPrimary.withOpacity(0.7)
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.6);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && message.isFailed)
            IconButton(
              icon: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 20),
              tooltip: l10n.sendMessageFailed,
              onPressed: onRetry,
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 10,
                          color: timeColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        if (message.isSending)
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: timeColor,
                            ),
                          )
                        else if (!message.isFailed)
                          Icon(Icons.done_all_rounded, size: 12, color: timeColor),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
