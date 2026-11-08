import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ParticipantModel? partner;

  const AdminChatDetailScreen({
    super.key,
    required this.conversationId,
    this.partner,
  });

  @override
  ConsumerState<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends ConsumerState<AdminChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _canSend) {
        setState(() => _canSend = hasText);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatDetailProvider(widget.conversationId).notifier).loadOlder();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendMessage(text);
  }

  Future<void> _handlePhoneCall(String? phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneNotAvailable)),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cannotLaunchPhone)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(chatDetailProvider(widget.conversationId));
    final conversation = state.conversation;

    final isAnonymous = conversation?.isAnonymous ?? false;
    final partnerName = isAnonymous
        ? l10n.anonymousUser
        : (conversation?.partnerName ?? widget.partner?.name ?? l10n.conversations);

    final avatarUrl = isAnonymous
        ? null
        : (conversation?.partnerAvatarUrl ?? widget.partner?.avatarUrl);

    final partnerRole = conversation?.partnerRole?.toLowerCase() ?? widget.partner?.role.toLowerCase();
    final isClient = partnerRole == 'client';
    final canSendMessage = state.canSendMessage;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AppNetworkImage(
              url: avatarUrl,
              width: 38,
              height: 38,
              isCircle: true,
              errorWidget: CircleAvatar(
                radius: 19,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  isAnonymous ? Icons.shield_outlined : Icons.person,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partnerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (partnerRole != null)
                    Text(
                      isClient
                          ? l10n.filterRoleClient
                          : (partnerRole == 'staff'
                              ? (conversation?.partnerPosition != null
                                  ? '${l10n.filterRoleStaff} • ${conversation!.partnerPosition}'
                                  : l10n.filterRoleStaff)
                              : l10n.filterRoleAdmin),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: l10n.conversationInfoTitle,
            onPressed: () {
              context.push(RouterPath.conversationInfoWithId(widget.conversationId));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noConversations,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final message = state.messages[index];
                          final isMe = message.senderId == state.currentUserId;

                          return ChatMessageBubble(
                            message: message,
                            isMe: isMe,
                            onRetry: () {
                              ref
                                  .read(chatDetailProvider(widget.conversationId).notifier)
                                  .retryMessage(message);
                            },
                          );
                        },
                      ),
          ),
          // Input bar or Restriction Banner
          if (isClient && !canSendMessage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.cannotMessageClientMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!canSendMessage)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.conversationLockedNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.messageInputPlaceholder,
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _canSend ? _sendMessage : null,
                      icon: const Icon(Icons.send_rounded, size: 20),
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

