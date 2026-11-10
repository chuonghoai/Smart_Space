import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/features/chat/data/chat_repository.dart';
import 'package:mobile_shared/features/chat/services/chat_ws_service.dart';
import 'package:mobile_shared/features/chat/widgets/conversation_options_sheet.dart';
import 'package:smartspace_client/features/chat/providers/client_conversations_provider.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/routes/router_path.dart';
import 'package:smartspace_client/ui/mobile/chat/widgets/client_conversation_item.dart';

class ClientConversationsScreen extends ConsumerStatefulWidget {
  const ClientConversationsScreen({super.key});

  @override
  ConsumerState<ClientConversationsScreen> createState() => _ClientConversationsScreenState();
}

class _ClientConversationsScreenState extends ConsumerState<ClientConversationsScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _heartbeatTimer;
  bool _isInListPresence = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _enterListPresence();
    _searchController.text = ref.read(clientConversationsProvider).searchQuery;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _leaveListPresence();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterListPresence();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _leaveListPresence();
    }
  }

  void _enterListPresence() {
    if (_isInListPresence) return;
    _isInListPresence = true;
    chatRepository.enterPresence('list');
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _isInListPresence) {
        chatRepository.heartbeatPresence('list');
      }
    });
  }

  void _leaveListPresence() {
    if (!_isInListPresence) return;
    _isInListPresence = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    chatRepository.leavePresence('list');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(clientConversationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(clientConversationsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.conversations,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => ref.read(clientConversationsProvider.notifier).search(val),
                decoration: InputDecoration(
                  hintText: l10n.searchConversationsPlaceholder,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(clientConversationsProvider.notifier).search('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Conversations List or State
          Expanded(
            child: _buildBody(context, theme, l10n, state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ClientConversationsState state,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                l10n.errorLoadMessages,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(clientConversationsProvider.notifier).loadInitial(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noConversations,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noConversationsSub,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_searchController.text.trim().isEmpty && state.searchQuery.isNotEmpty) {
          ref.read(clientConversationsProvider.notifier).search('');
        } else {
          await ref.read(clientConversationsProvider.notifier).refresh();
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.conversations.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final conv = state.conversations[index];
          final displayName = conv.isAnonymous
              ? l10n.anonymousPerson
              : (conv.partnerName?.isNotEmpty == true
                  ? conv.partnerName!
                  : (conv.name?.isNotEmpty == true
                      ? conv.name!
                      : (conv.partnerRole?.toLowerCase() == 'admin'
                          ? l10n.managementBoard
                          : l10n.supportStaff)));

          return ClientConversationItem(
            conversation: conv,
            onTap: () {
              ref.read(clientConversationsProvider.notifier).markAsReadLocally(conv.id);
              context.push(RouterPath.chatDetailWithId(conv.id));
            },
            onLongPress: () {
              ConversationOptionsSheet.show(
                context: context,
                conversation: conv,
                partnerDisplayName: displayName,
                onMarkAsRead: () {
                  chatWsService.sendMarkAsRead(conv.id);
                  if (conv.identifiedConversationId != null &&
                      conv.identifiedConversationId != conv.id) {
                    chatWsService.sendMarkAsRead(conv.identifiedConversationId!);
                  }
                  if (conv.anonymousConversationId != null &&
                      conv.anonymousConversationId != conv.id) {
                    chatWsService.sendMarkAsRead(conv.anonymousConversationId!);
                  }
                  ref.read(clientConversationsProvider.notifier).markAsReadLocally(conv.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

