import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/features/chat/providers/admin_conversations_provider.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/chat/admin_chat_detail_screen.dart';
import 'package:smartspace_admin/ui/screen/chat/widgets/conversation_item.dart';
import 'package:smartspace_admin/ui/screen/chat/widgets/position_filter_sheet.dart';

class AdminConversationsScreen extends ConsumerStatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  ConsumerState<AdminConversationsScreen> createState() => _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends ConsumerState<AdminConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    // Register presence 'list' so FCM push notifications are suppressed while viewing conversations
    chatRepository.enterPresence('list');

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    chatRepository.leavePresence('list');
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminConversationsProvider.notifier).loadOlder();
    }
  }

  void _openPositionFilter(BuildContext context, AdminConversationsState state) {
    PositionFilterSheet.show(
      context: context,
      positions: state.availablePositions,
      selectedIds: state.selectedPositionIds,
      onToggle: (id) => ref.read(adminConversationsProvider.notifier).togglePosition(id),
      onClear: () => ref.read(adminConversationsProvider.notifier).clearPositions(),
      onApply: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(adminConversationsProvider);
    final notifier = ref.read(adminConversationsProvider.notifier);

    final isDesktop = kIsWeb && MediaQuery.of(context).size.width >= 850;

    final filterTabs = [
      {'key': 'all', 'label': l10n.filterRoleAll},
      {'key': 'client', 'label': l10n.filterRoleClient},
      {'key': 'staff', 'label': l10n.filterRoleStaff},
      {'key': 'admin', 'label': l10n.filterRoleAdmin},
    ];

    Widget listPane = Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: notifier.onSearchQueryChanged,
            decoration: InputDecoration(
              hintText: l10n.searchConversationsPlaceholder,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        notifier.onSearchQueryChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Role Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: filterTabs.map((tab) {
              final isSelected = state.activeFilter == tab['key'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tab['label']!),
                  selected: isSelected,
                  onSelected: (_) => notifier.setFilter(tab['key']!),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  selectedColor: theme.colorScheme.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),

        // Position Filter right below the 4 tabs
        if (state.activeFilter == 'staff' || state.activeFilter == 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(
              children: [
                ActionChip(
                  avatar: Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: state.selectedPositionIds.isNotEmpty
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    state.selectedPositionIds.isEmpty
                        ? l10n.filterPosition
                        : '${l10n.filterPosition} (${state.selectedPositionIds.length})',
                    style: TextStyle(
                      color: state.selectedPositionIds.isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: state.selectedPositionIds.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => _openPositionFilter(context, state),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                if (state.selectedPositionIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: notifier.clearPositions,
                    child: Text(
                      l10n.clearFilters,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const Divider(height: 1),

        // Conversations List
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noConversations,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              l10n.noConversationsSub,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: notifier.refresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 76,
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                        itemBuilder: (context, index) {
                          if (index == state.conversations.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final conversation = state.conversations[index];
                          final isSelected = isDesktop && _selectedConversationId == conversation.id;

                          return AdminConversationItem(
                            conversation: conversation,
                            isSelected: isSelected,
                            onTap: () {
                              notifier.markAsReadLocally(conversation.id);
                              if (isDesktop) {
                                setState(() => _selectedConversationId = conversation.id);
                              } else {
                                context.push(RouterPath.chatDetailWithId(conversation.id));
                              }
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );

    Widget content;
    if (isDesktop) {
      content = Row(
        children: [
          SizedBox(
            width: 360,
            child: Material(
              color: theme.colorScheme.surface,
              child: listPane,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedConversationId != null
                ? AdminChatDetailScreen(
                    key: ValueKey(_selectedConversationId),
                    conversationId: _selectedConversationId!,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noConversationsSub,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );
    } else {
      content = listPane;
    }

    final mobileAppBar = AppBar(
      title: Text(
        l10n.conversations,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RouterPath.home);
          }
        },
      ),
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
    );

    return AppLayout(
      showAppBar: false,
      customAppBar: isDesktop ? null : mobileAppBar,
      child: content,
    );
  }
}

