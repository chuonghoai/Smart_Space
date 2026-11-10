import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/features/chat/widgets/chat_audio_recorder_bar.dart';
import 'package:mobile_shared/features/chat/widgets/linked_report_picker_sheet.dart';
import 'package:mobile_shared/features/chat/widgets/typing_indicator_widget.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/shared/image/app_network_image.dart';

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
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _canSend) {
      setState(() => _canSend = hasText);
    }
    if (hasText) {
      ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(false);
        }
      });
    } else {
      _typingTimer?.cancel();
      ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatDetailProvider(widget.conversationId).notifier).loadOlder();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(false);
    _textController.clear();
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendMessage(text);
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo}) async {
    try {
      final picker = ImagePicker();
      final XFile? file;
      if (isVideo) {
        file = await picker.pickVideo(source: source);
      } else {
        file = await picker.pickImage(source: source, imageQuality: 85);
      }
      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        ref.read(chatDetailProvider(widget.conversationId).notifier).sendMediaMessage(
              bytes: bytes,
              fileName: file.name,
              isVideo: isVideo,
              localPath: file.path,
            );
      }
    } catch (e) {
      debugPrint('[PickMedia] Error: $e');
    }
  }

  void _showMoreOptionsSheet() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(chatDetailProvider(widget.conversationId));
    final isAnonymous = state.conversation?.isAnonymous ?? false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.image_outlined, color: theme.colorScheme.primary, size: 22),
                  ),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMedia(ImageSource.gallery, isVideo: false);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.videocam_outlined, color: theme.colorScheme.tertiary, size: 22),
                  ),
                  title: Text(l10n.chooseVideo),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMedia(ImageSource.gallery, isVideo: true);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: theme.colorScheme.secondary, size: 22),
                  ),
                  title: Text(l10n.takePhoto),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMedia(ImageSource.camera, isVideo: false);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.assignment_outlined, color: theme.colorScheme.error, size: 22),
                  ),
                  title: Text(l10n.attachReport),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final selected = await LinkedReportPickerSheet.show(
                      context: context,
                      conversationId: widget.conversationId,
                      isAnonymous: isAnonymous,
                    );
                    if (selected != null && mounted) {
                      ref.read(chatDetailProvider(widget.conversationId).notifier).sendReportMessage(selected);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
            icon: const Icon(Icons.call_outlined),
            tooltip: l10n.callOptionsTitle,
            onPressed: () {
              final phone = conversation?.partnerPhone;
              ChatCallBottomSheet.show(
                context,
                partnerName: partnerName,
                partnerPhone: phone,
                titleText: l10n.callOptionsTitle,
                cellularCallTitle: l10n.cellularCall,
                cellularCallDesc: l10n.cellularCallDesc,
                freeCallTitle: l10n.freeCall,
                freeCallDesc: l10n.featureUnderDevelopment,
                comingSoonText: l10n.comingSoon,
                phoneNotAvailableText: l10n.phoneNotAvailable,
                freeCallComingSoonText: l10n.freeCallComingSoon,
              );
            },
          ),
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
                            key: ValueKey(message.id ?? message.tempId ?? index.toString()),
                            message: message,
                            isMe: isMe,
                            conversationMessages: state.messages,
                            conversationId: widget.conversationId,
                            onRetry: () {
                              ref
                                  .read(chatDetailProvider(widget.conversationId).notifier)
                                  .retryMessage(message);
                            },
                            onTapReport: (report) {
                              context.push(RouterPath.reportDetailWithId(report.id));
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isPartnerTyping)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: TypingIndicatorWidget(
                        partnerName: partnerName,
                        typingText: l10n.typingText,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _showMoreOptionsSheet,
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 26,
                          ),
                        ),
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
                        const SizedBox(width: 4),
                        if (_canSend)
                          IconButton.filled(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send_rounded, size: 20),
                          )
                        else
                          ChatAudioRecorderButton(
                            onRecordingComplete: ({
                              required Uint8List bytes,
                              required String fileName,
                              required int durationSeconds,
                              required String localPath,
                            }) {
                              ref.read(chatDetailProvider(widget.conversationId).notifier).sendAudioMessage(
                                    bytes: bytes,
                                    fileName: fileName,
                                    durationSeconds: durationSeconds,
                                    localPath: localPath,
                                  );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

