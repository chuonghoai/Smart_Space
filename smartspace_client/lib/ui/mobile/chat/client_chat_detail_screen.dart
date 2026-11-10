import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_shared/features/chat/models/conversation_model.dart';
import 'package:mobile_shared/features/chat/providers/chat_detail_provider.dart';
import 'package:mobile_shared/features/chat/widgets/chat_audio_recorder_bar.dart';
import 'package:mobile_shared/features/chat/widgets/chat_call_bottom_sheet.dart';
import 'package:mobile_shared/features/chat/widgets/chat_message_bubble.dart';
import 'package:mobile_shared/features/chat/widgets/linked_report_picker_sheet.dart';
import 'package:mobile_shared/features/chat/widgets/typing_indicator_widget.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/chat/widgets/client_chat_role_badge.dart';
import 'package:smartspace_client/ui/shared/image/app_network_image.dart';

class ClientChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ParticipantModel? initialPartner;

  const ClientChatDetailScreen({
    super.key,
    required this.conversationId,
    this.initialPartner,
  });

  @override
  ConsumerState<ClientChatDetailScreen> createState() =>
      _ClientChatDetailScreenState();
}

class _ClientChatDetailScreenState
    extends ConsumerState<ClientChatDetailScreen> {
  late final PageController _pageController;
  int _selectedTabIndex = 0;
  bool _tabInitialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showContextExplanationSheet({
    required BuildContext context,
    required bool isAnonymous,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isAnonymous
                        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
                        : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAnonymous ? Icons.shield_outlined : Icons.person_outline_rounded,
                    size: 30,
                    color: isAnonymous ? theme.colorScheme.secondary : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAnonymous ? l10n.contextAnonymous : l10n.contextIdentified,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAnonymous
                        ? l10n.contextAnonymousExplanation
                        : l10n.contextIdentifiedExplanation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.contextExplanationGotIt),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _switchTab(int index, String? targetConvId) {
    if (_selectedTabIndex == index) {
      _showContextExplanationSheet(
        context: context,
        isAnonymous: index == 1,
      );
      return;
    }
    setState(() {
      _selectedTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (targetConvId != null) {
      ref.read(chatDetailProvider(targetConvId).notifier).markAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final baseState = ref.watch(chatDetailProvider(widget.conversationId));
    final conv = baseState.conversation;

    final hasBothContexts = conv != null &&
        conv.hasIdentifiedContext &&
        conv.hasAnonymousContext &&
        conv.identifiedConversationId != null &&
        conv.anonymousConversationId != null;

    final identConvId = conv?.identifiedConversationId;
    final anonConvId = conv?.anonymousConversationId;

    if (hasBothContexts && !_tabInitialized) {
      _tabInitialized = true;
      if (widget.conversationId == anonConvId ||
          (widget.conversationId != identConvId &&
              conv.lastMessageContext == 'ANONYMOUS')) {
        _selectedTabIndex = 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(1);
          }
        });
      }
    }

    final initialPartner = widget.initialPartner;
    final displayName = conv?.isAnonymous == true && !hasBothContexts
        ? l10n.anonymousPerson
        : (conv?.partnerName?.isNotEmpty == true
            ? conv!.partnerName!
            : (conv?.name?.isNotEmpty == true
                ? conv!.name!
                : (initialPartner?.name.isNotEmpty == true
                    ? initialPartner!.name
                    : (conv?.partnerRole?.toLowerCase() == 'admin'
                        ? l10n.managementBoard
                        : l10n.supportStaff))));

    final partnerRole = conv?.partnerRole ?? initialPartner?.role;
    final activeConvId = hasBothContexts
        ? (_selectedTabIndex == 1 ? anonConvId! : identConvId!)
        : widget.conversationId;

    final identUnread = conv?.identifiedUnreadCount ?? 0;
    final anonUnread = conv?.anonymousUnreadCount ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        scrolledUnderElevation: 1,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        titleSpacing: 0,
        title: Row(
          children: [
            _buildAppBarAvatar(theme, conv, hasBothContexts),
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
                      ClientChatRoleBadge(
                        role: partnerRole,
                        position: conv?.partnerPosition,
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
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: l10n.callOptionsTitle,
            onPressed: () {
              final activeState = ref.read(chatDetailProvider(activeConvId));
              final partnerPhone = activeState.conversation?.partnerPhone;
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
            tooltip: l10n.conversationInfoTitle,
            onPressed: () {
              context.push(RouterPath.conversationInfoWithId(activeConvId));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: hasBothContexts
            ? Column(
                children: [
                  _buildContextTabBar(
                    theme,
                    l10n,
                    identConvId!,
                    anonConvId!,
                    identUnread,
                    anonUnread,
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                        final targetId =
                            index == 1 ? anonConvId : identConvId;
                        ref
                            .read(chatDetailProvider(targetId).notifier)
                            .markAsRead();
                      },
                      children: [
                        _ContextChatPane(
                          key: ValueKey('ident_$identConvId'),
                          conversationId: identConvId,
                          isAnonymous: false,
                        ),
                        _ContextChatPane(
                          key: ValueKey('anon_$anonConvId'),
                          conversationId: anonConvId,
                          isAnonymous: true,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _ContextChatPane(
                key: ValueKey('single_${widget.conversationId}'),
                conversationId: widget.conversationId,
                isAnonymous: conv?.isAnonymous == true,
              ),
      ),
    );
  }

  Widget _buildAppBarAvatar(
    ThemeData theme,
    ConversationModel? conv,
    bool hasBothContexts,
  ) {
    if (conv?.isAnonymous == true && !hasBothContexts) {
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

    final avatarUrl =
        conv?.partnerAvatarUrl ?? widget.initialPartner?.avatarUrl;
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

  Widget _buildContextTabBar(
    ThemeData theme,
    AppLocalizations l10n,
    String identConvId,
    String anonConvId,
    int identUnread,
    int anonUnread,
  ) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildContextTabItem(
              theme: theme,
              title: l10n.contextIdentified,
              icon: Icons.person_outline_rounded,
              isSelected: _selectedTabIndex == 0,
              unreadCount: identUnread,
              onTap: () => _switchTab(0, identConvId),
            ),
          ),
          Expanded(
            child: _buildContextTabItem(
              theme: theme,
              title: l10n.contextAnonymous,
              icon: Icons.shield_outlined,
              isSelected: _selectedTabIndex == 1,
              unreadCount: anonUnread,
              onTap: () => _switchTab(1, anonConvId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextTabItem({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required bool isSelected,
    required int unreadCount,
    required VoidCallback onTap,
  }) {
    final activeBg = theme.colorScheme.surface;
    final activeFg = theme.colorScheme.primary;
    final inactiveFg = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.25 : 0.06,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeFg : inactiveFg,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeFg : inactiveFg,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: activeFg,
                ),
              ],
              if (unreadCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextChatPane extends ConsumerStatefulWidget {
  final String conversationId;
  final bool isAnonymous;

  const _ContextChatPane({
    super.key,
    required this.conversationId,
    required this.isAnonymous,
  });

  @override
  ConsumerState<_ContextChatPane> createState() => _ContextChatPaneState();
}

class _ContextChatPaneState extends ConsumerState<_ContextChatPane>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;
  bool _isAudioMode = false;
  Timer? _typingTimer;

  @override
  bool get wantKeepAlive => true;

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
      ref
          .read(chatDetailProvider(widget.conversationId).notifier)
          .loadOlder();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    ref.read(chatDetailProvider(widget.conversationId).notifier).sendTyping(false);
    ref
        .read(chatDetailProvider(widget.conversationId).notifier)
        .sendMessage(text);
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
                      isAnonymous: widget.isAnonymous,
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
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(chatDetailProvider(widget.conversationId));

    return Column(
      children: [
        if (widget.isAnonymous) _buildPrivacyBanner(theme, l10n),
        Expanded(
          child: _buildMessagesList(context, theme, l10n, state),
        ),
        _buildBottomArea(theme, l10n, state),
      ],
    );
  }

  Widget _buildPrivacyBanner(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 17,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.anonymousProtectionBanner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(l10n.errorLoadMessages),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref
                  .read(chatDetailProvider(widget.conversationId).notifier)
                  .loadInitial(),
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
          onRetry: () => ref
              .read(chatDetailProvider(widget.conversationId).notifier)
              .retryMessage(msg),
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
  ) {
    if (!state.canSendMessage) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            Icon(
              Icons.lock_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.chatDisabledNotice,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isPartnerTyping)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: TypingIndicatorWidget(
              partnerName: state.conversation?.partnerName,
              typingText: l10n.typingText,
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isAudioMode
              ? ChatAudioRecorderBar(
                  key: const ValueKey('audio_bar'),
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
                  onClose: () {
                    setState(() => _isAudioMode = false);
                  },
                )
              : Container(
                  key: const ValueKey('text_bar'),
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
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
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
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
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
                        IconButton(
                          icon: Icon(
                            Icons.mic_none_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() => _isAudioMode = true);
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
