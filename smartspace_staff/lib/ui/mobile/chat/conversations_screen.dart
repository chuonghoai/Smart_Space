import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartspace_staff/features/chat/models/conversation_model.dart';
import 'package:smartspace_staff/features/chat/providers/conversations_provider.dart';
import 'package:smartspace_staff/l10n/app_localizations.dart';
import 'package:smartspace_staff/routes/router_path.dart';
import 'package:smartspace_staff/ui/mobile/chat/widgets/chat_role_badge.dart';
import 'package:smartspace_staff/ui/mobile/chat/widgets/conversation_item.dart';
import 'package:smartspace_staff/ui/shared/image/app_network_image.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(conversationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.conversations,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildFilterTabs(theme, l10n, state.activeFilter),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, l10n),
          Expanded(
            child: _buildBody(context, theme, l10n, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    ThemeData theme,
    AppLocalizations l10n,
    String activeFilter,
  ) {
    final filters = [
      {'key': 'all', 'label': l10n.filterAll},
      {'key': 'client', 'label': l10n.filterClient},
      {'key': 'staff', 'label': l10n.filterStaff},
      {'key': 'admin', 'label': l10n.filterAdmin},
    ];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final isSelected = activeFilter == item['key'];

          return InkWell(
            onTap: () {
              ref.read(conversationsProvider.notifier).setFilter(item['key']!);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  item['label']!,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {});
            ref.read(conversationsProvider.notifier).setSearchQuery(val);
          },
          decoration: InputDecoration(
            hintText: l10n.searchConversations,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      ref.read(conversationsProvider.notifier).setSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ConversationsState state,
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
                l10n.errorLoadConversations,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final hasSearch = state.searchQuery.trim().isNotEmpty;

    // Search empty state
    if (hasSearch &&
        state.conversations.isEmpty &&
        state.searchedUsers.isEmpty &&
        !state.isSearchingUsers) {
      return RefreshIndicator(
        onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.noUsersFound,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default empty state
    if (!hasSearch && state.conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                    l10n.emptyConversations,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      l10n.emptyConversationsDesc,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final convList = state.conversations;
    final userList = state.searchedUsers;

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Section header for conversations when searched users also exist
          if (hasSearch && convList.isNotEmpty && userList.isNotEmpty)
            _buildSectionHeader(theme, l10n.conversations),

          // Conversation Items
          ...convList.map((conv) => Column(
                key: ValueKey(conv.id),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConversationItem(
                    conversation: conv,
                    isSlidingOut: state.slidingOutId == conv.id,
                    isSlidingIn: state.slidingInId == conv.id,
                    isPulsing: state.pulseHighlightId == conv.id,
                    onTap: () {
                      ref.read(conversationsProvider.notifier).markConversationRead(conv.id);
                      context.push(RouterPath.chatDetailWithId(conv.id));
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 76,
                    endIndent: 16,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ],
              )),

          // Loading more indicator for conversations
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // Other Users Section (from DB search, no conversation yet)
          if (userList.isNotEmpty) ...[
            _buildSectionHeader(theme, l10n.otherUsers),
            ...userList.map((user) => Column(
                  key: ValueKey('user_${user.userId}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUserItem(context, theme, l10n, user),
                    Divider(
                      height: 1,
                      indent: 76,
                      endIndent: 16,
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ],
                )),
          ],

          // Searching users indicator
          if (state.isSearchingUsers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildUserItem(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    ParticipantModel user,
  ) {
    return InkWell(
      onTap: () {
        context.push('/conversations/new_${user.userId}', extra: user);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildUserAvatar(theme, user),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ChatRoleBadge(
                    role: user.role,
                    position: user.position,
                    isCompact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme, ParticipantModel user) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return AppNetworkImage(
        url: user.avatarUrl,
        width: 44,
        height: 44,
        isCircle: true,
        errorWidget: CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
