import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/routes/router_path.dart';
import 'package:smartspace_admin/ui/layout/app_layout.dart';
import 'package:smartspace_admin/ui/screen/news/widgets/news_card.dart';

/// Quản lý tin tức. Màn rộng: một hàng công cụ (tìm kiếm 320px, khoảng ngày, số tin + "Xoá bộ lọc" bên phải).
/// Màn hẹp: tìm kiếm + nút lịch trên một hàng, dòng meta bên dưới.
class AdminNewsListScreen extends ConsumerStatefulWidget {
  const AdminNewsListScreen({super.key});

  @override
  ConsumerState<AdminNewsListScreen> createState() => _AdminNewsListScreenState();
}

class _AdminNewsListScreenState extends ConsumerState<AdminNewsListScreen> {
  /// Số năm có thể lùi lại khi chọn khoảng ngày.
  static const int _yearsBack = 5;

  /// Từ bề rộng này thanh công cụ nằm trên một hàng.
  static const double _wideToolbarMinWidth = 600;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(newsListProvider.notifier).clearFilters();
  }

  Future<void> _pickDateRange(NewsListState state) async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final from = state.dateFrom;
    final to = state.dateTo;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - _yearsBack, 1, 1),
      lastDate: now,
      initialDateRange: from != null && to != null ? DateTimeRange(start: from, end: to) : null,
      builder: (context, child) => Theme(data: theme, child: child!),
    );
    if (range != null) {
      ref.read(newsListProvider.notifier).setDateRange(range.start, range.end);
    }
  }

  /// "12/3/2026" cho một ngày, "1/3/2026 – 15/3/2026" cho một khoảng; theo ngôn ngữ đang chọn.
  String? _rangeLabel(NewsListState state) {
    final from = state.dateFrom;
    final to = state.dateTo;
    if (from == null || to == null) return null;
    final format = DateFormat.yMd(Localizations.localeOf(context).toLanguageTag());
    return from == to ? format.format(from) : '${format.format(from)} – ${format.format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(newsListProvider);
    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= 850;
    final rangeLabel = _rangeLabel(state);

    final scrollView = CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.manageNews,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => context.push(RouterPath.createNews),
                  icon: const Icon(Icons.post_add, size: 18),
                  label: Text(l10n.createNewNews),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= _wideToolbarMinWidth
                ? _buildWideToolbar(state, l10n, theme, rangeLabel)
                : _buildNarrowToolbar(state, l10n, rangeLabel),
          ),
        ),
        // Đang tải lại theo bộ lọc mới nhưng vẫn giữ danh sách cũ
        SliverToBoxAdapter(
          child: SizedBox(
            height: 2,
            child: state.isLoading && state.items.isNotEmpty ? const LinearProgressIndicator() : null,
          ),
        ),
        ..._buildContent(state, l10n, theme, colorScheme, rangeLabel),
      ],
    );

    return AppLayout(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouterPath.createNews),
        icon: const Icon(Icons.add),
        label: Text(l10n.createNewNews),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      child: RefreshIndicator(
        onRefresh: ref.read(newsListProvider.notifier).refresh,
        child: isDesktop
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: scrollView,
                ),
              )
            : scrollView,
      ),
    );
  }

  /// Tổng số tin theo bộ lọc hiện tại kèm khoảng ngày; rỗng khi chưa có kết quả.
  String _summary(NewsListState state, AppLocalizations l10n, String? rangeLabel) {
    final hasResult = !(state.items.isEmpty && (state.isLoading || state.error != null));
    return hasResult ? [l10n.newsCount(state.totalElements), ?rangeLabel].join(' · ') : '';
  }

  Widget _buildSearchField(AppLocalizations l10n) {
    final notifier = ref.read(newsListProvider.notifier);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchController,
      builder: (context, value, _) => TextField(
        controller: _searchController,
        onChanged: notifier.setSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          hintText: l10n.searchNewsPlaceholder,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearch('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildWideToolbar(NewsListState state, AppLocalizations l10n, ThemeData theme, String? rangeLabel) {
    final colorScheme = theme.colorScheme;
    final active = rangeLabel != null;
    final summary = _summary(state, l10n, null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          SizedBox(width: 320, child: _buildSearchField(l10n)),
          const SizedBox(width: 8),
          // Nút trung tính; chỉ đổi sang nền primaryContainer khi đang lọc theo ngày
          OutlinedButton.icon(
            onPressed: () => _pickDateRange(state),
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(rangeLabel ?? l10n.selectDateRange),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: active ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
              backgroundColor: active ? colorScheme.primaryContainer : null,
              side: active ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          if (state.isFiltering) ...[
            const SizedBox(width: 4),
            TextButton(onPressed: _clearFilters, child: Text(l10n.clearFilters)),
          ],
        ],
      ),
    );
  }

  Widget _buildNarrowToolbar(NewsListState state, AppLocalizations l10n, String? rangeLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchField(l10n)),
              const SizedBox(width: 8),
              DateFilterIconButton(
                active: rangeLabel != null,
                tooltip: l10n.selectDateRange,
                semanticsValue: rangeLabel,
                onPressed: () => _pickDateRange(state),
              ),
            ],
          ),
          NewsListMetaRow(
            summary: _summary(state, l10n, rangeLabel),
            clearLabel: state.isFiltering ? l10n.clearFilters : null,
            onClear: _clearFilters,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(
    NewsListState state,
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    String? rangeLabel,
  ) {
    if (state.items.isEmpty) {
      if (state.isLoading) {
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                label: l10n.loading,
                liveRegion: true,
                child: ExcludeSemantics(
                  child: Column(
                    children: [for (var i = 0; i < 3; i++) NewsCardSkeleton(withImage: i == 0)],
                  ),
                ),
              ),
            ),
          ),
        ];
      }
      final Widget content;
      if (state.error != null) {
        content = _buildError(l10n, theme, colorScheme);
      } else if (state.isFiltering) {
        content = _buildNoMatch(state, l10n, theme, rangeLabel);
      } else {
        content = _buildEmptyState(l10n, theme, colorScheme);
      }
      return [SliverFillRemaining(hasScrollBody: false, child: content)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => NewsCard(news: state.items[index]),
            childCount: state.items.length,
          ),
        ),
      ),
      SliverToBoxAdapter(child: _buildFooter(state, l10n, theme)),
    ];
  }

  Widget _buildFooter(NewsListState state, AppLocalizations l10n, ThemeData theme) {
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final Widget child;
    if (state.isLoadingMore) {
      child = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (state.loadMoreError != null) {
      child = Column(
        children: [
          Text(l10n.loadMoreNewsFailed, style: muted),
          TextButton(onPressed: ref.read(newsListProvider.notifier).loadMore, child: Text(l10n.retry)),
        ],
      );
    } else if (!state.hasMore && state.page > 1) {
      // Chỉ nói "đã hết" khi đã cuộn qua nhiều trang; một trang thì số tin đã nêu ở trên
      child = Text(l10n.allNewsShown(state.totalElements), textAlign: TextAlign.center, style: muted);
    } else {
      child = const SizedBox.shrink();
    }
    // Chừa chỗ cho FAB để không che tin cuối
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: child,
    );
  }

  /// Lỗi tải trang đầu: một câu điềm tĩnh + "Thử lại", không hiện lỗi kỹ thuật.
  Widget _buildError(AppLocalizations l10n, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 24, color: colorScheme.error),
            const SizedBox(height: 8),
            Text(
              l10n.newsLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: ref.read(newsListProvider.notifier).refresh, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }

  /// Không có kết quả: nói rõ đang lọc theo gì, kèm "Xoá bộ lọc".
  Widget _buildNoMatch(NewsListState state, AppLocalizations l10n, ThemeData theme, String? rangeLabel) {
    final keyword = state.search;
    final String message;
    if (keyword.isNotEmpty && rangeLabel != null) {
      message = l10n.noNewsMatchingKeywordInRange(keyword, rangeLabel);
    } else if (keyword.isNotEmpty) {
      message = l10n.noNewsMatchingKeyword(keyword);
    } else {
      message = l10n.noNewsInRange(rangeLabel ?? '');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: _clearFilters, child: Text(l10n.clearFilters)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyNewsTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                l10n.emptyNewsDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(RouterPath.createNews),
              icon: const Icon(Icons.add),
              label: Text(l10n.createNewNews),
            ),
          ],
        ),
      ),
    );
  }
}
