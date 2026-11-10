import 'package:flutter/material.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/l10n/generated/shared_localizations.dart';

class ConversationOptionsSheet extends StatelessWidget {
  final ConversationModel conversation;
  final String partnerDisplayName;
  final VoidCallback onMarkAsRead;

  const ConversationOptionsSheet({
    super.key,
    required this.conversation,
    required this.partnerDisplayName,
    required this.onMarkAsRead,
  });

  static Future<void> show({
    required BuildContext context,
    required ConversationModel conversation,
    required String partnerDisplayName,
    required VoidCallback onMarkAsRead,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConversationOptionsSheet(
        conversation: conversation,
        partnerDisplayName: partnerDisplayName,
        onMarkAsRead: () {
          Navigator.pop(ctx);
          onMarkAsRead();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sharedL10n = SharedLocalizations.of(context);
    final markAsReadText = sharedL10n?.markAsRead ?? 'Đánh dấu đã đọc';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      partnerDisplayName.isNotEmpty
                          ? partnerDisplayName[0].toUpperCase()
                          : 'C',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      partnerDisplayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.done_all_rounded,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                markAsReadText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onMarkAsRead,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

