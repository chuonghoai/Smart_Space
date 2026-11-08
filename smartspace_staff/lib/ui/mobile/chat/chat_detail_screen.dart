import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/providers/chat_detail_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/ui/mobile/chat/widgets/chat_message_bubble.dart';
import 'package:smartspace_staff/ui/mobile/chat/widgets/chat_role_badge.dart';
import 'package:smartspace_staff/ui/shared/image/app_network_image.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ParticipantModel? initialPartner;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.initialPartner,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() {
        _canSend = hasText;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatDetailProvider(widget.conversationId).notifier).loadOlder();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatDetailProvider(widget.conversationId).notifier).sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(chatDetailProvider(widget.conversationId));
    final conv = state.conversation;

    final initialPartner = widget.initialPartner;
    final displayName = conv?.isAnonymous == true
        ? l10n.anonymousPerson
        : (conv?.partnerName?.isNotEmpty == true
            ? conv!.partnerName!
            : (conv?.name?.isNotEmpty == true
                ? conv!.name!
                : (initialPartner?.name.isNotEmpty == true
                    ? initialPartner!.name
                    : l10n.conversations)));

    final partnerRole = conv?.partnerRole ?? initialPartner?.role;
    final partnerPosition = conv?.partnerPosition ?? initialPartner?.position;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAppBarAvatar(theme, conv),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChatRoleBadge(
                        role: partnerRole,
                        position: partnerPosition,
                        isCompact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _buildMessagesList(context, theme, l10n, state),
            ),

            // Bottom Input or Locked Banner
            _buildBottomArea(theme, l10n, state, displayName),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAvatar(ThemeData theme, ConversationModel? conv) {
    if (conv?.isAnonymous == true) {
      return CircleAvatar(
        radius: 19,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      );
    }

    final avatarUrl = conv?.partnerAvatarUrl ?? widget.initialPartner?.avatarUrl;
    final name = (conv?.partnerName?.isNotEmpty == true
            ? conv!.partnerName
            : widget.initialPartner?.name) ??
        '';

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return AppNetworkImage(
        url: avatarUrl,
        width: 38,
        height: 38,
        isCircle: true,
        errorWidget: CircleAvatar(
          radius: 19,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            (name.isNotEmpty ? name[0] : 'S').toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 19,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        (name.isNotEmpty ? name[0] : 'S').toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ChatDetailState state,
  ) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(l10n.errorLoadMessages),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(chatDetailProvider(widget.conversationId).notifier).loadInitial(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.emptyMessages,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msg = state.messages[index];
        final isMe = msg.senderId == state.currentUserId;

        return ChatMessageBubble(
          key: ValueKey(msg.id ?? msg.tempId ?? index.toString()),
          message: msg,
          isMe: isMe,
          onRetry: () => ref.read(chatDetailProvider(widget.conversationId).notifier).retryMessage(msg),
        );
      },
    );
  }

  Widget _buildBottomArea(
    ThemeData theme,
    AppLocalizations l10n,
    ChatDetailState state,
    String partnerName,
  ) {
    // If messaging is locked (e.g. report completed)
    if (!state.canSendMessage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.chatDisabledNotice(partnerName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal active messaging input
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: l10n.chatInputHint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _canSend ? _sendMessage : null,
            icon: Icon(
              Icons.send_rounded,
              color: _canSend
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
