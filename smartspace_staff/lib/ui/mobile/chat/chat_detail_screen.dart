import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/features/chat/widgets/chat_audio_recorder_bar.dart';
import 'package:mobile_shared/features/chat/widgets/chat_call_bottom_sheet.dart';
import 'package:mobile_shared/features/chat/widgets/linked_report_picker_sheet.dart';
import 'package:mobile_shared/features/chat/widgets/typing_indicator_widget.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/providers/chat_detail_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';
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
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatDetailProvider(widget.conversationId).notifier).loadOlder();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(false);
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendMessage(text);
    _textController.clear();
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

    final isAnonymous = conv?.isAnonymous ?? false;
    final partnerRole = conv?.partnerRole ?? initialPartner?.role;
    final partnerPosition = conv?.partnerPosition ?? initialPartner?.position;
    final isClient = partnerRole?.toLowerCase() == 'client';
    final canCall = isClient ? !isAnonymous : true;

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
        actions: [
          if (canCall)
            IconButton(
              icon: const Icon(Icons.call_outlined),
              tooltip: l10n.callOptionsTitle,
              onPressed: () {
                final partnerPhone = conv?.partnerPhone;
                ChatCallBottomSheet.show(
                  context,
                  partnerName: displayName,
                  partnerPhone: partnerPhone,
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
            onPressed: () {
              context.push(RouterPath.conversationInfoWithId(widget.conversationId));
            },
          ),
        ],
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
          conversationMessages: state.messages,
          conversationId: widget.conversationId,
          onRetry: () => ref.read(chatDetailProvider(widget.conversationId).notifier).retryMessage(msg),
          onTapReport: (report) {
            context.push(RouterPath.reportDetailWithId(report.id));
          },
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
    return Column(
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
              top: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 1,
              ),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (_canSend)
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.primary,
                  ),
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
    );
  }
}
