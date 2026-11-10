import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/mobile_shared.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/l10n/app_localizations.dart';
import 'package:smartspace_client/ui/mobile/news/widgets/news_card.dart';
import 'package:smartspace_client/ui/components/report_filters/report_date_range_filter_chip.dart';
import 'package:smartspace_client/ui/components/report_filters/report_filter_bar.dart';

/// Tin tức: tìm kiếm + nút lịch trên một hàng, dòng meta (số tin, khoảng ngày, "Xoá bộ lọc"),
/// danh sách tải thêm khi cuộn.
class ClientNewsListScreen extends ConsumerStatefulWidget {
  const ClientNewsListScreen({super.key});

  @override
  ConsumerState<ClientNewsListScreen> createState() => _ClientNewsListScreenState();
}

class _ClientNewsListScreenState extends ConsumerState<ClientNewsListScreen> {
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

  static ReportDateRange? _rangeOf(NewsListState state) {
    final from = state.dateFrom;
    final to = state.dateTo;
    return from == null || to == null ? null : ReportDateRange(start: from, end: to);
  }

  String _formatRange(ReportDateRange range) =>
      ReportDateRangeFilterChip.format(range, Localizations.localeOf(context).toLanguageTag());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(newsListProvider);
    final notifier = ref.read(newsListProvider.notifier);
    final range = _rangeOf(state);
    final rangeLabel = range == null ? null : _formatRange(range);
    final hasResult = !(state.items.isEmpty && (state.isLoading || state.error != null));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.news),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ReportFilterBar(
              searchController: _searchController,
              searchHint: l10n.searchNewsPlaceholder,
              onSearchChanged: notifier.setSearch,
              isFiltering: state.isFiltering,
              onClearFilters: notifier.clearFilters,
              chips: const [],
              trailing: DateFilterIconButton(
                active: range != null,
                tooltip: l10n.filterByDate,
                semanticsValue: rangeLabel,
                onPressed: () => ReportDateRangeFilterChip.openOptions(
                  context,
                  value: range,
                  onChanged: (picked) => notifier.setDateRange(picked?.start, picked?.end),
                ),
              ),
            ),
          ),
          // Luôn giữ chỗ để danh sách không nhảy khi số tin về
          NewsListMetaRow(
            summary: hasResult
                ? [l10n.newsCount(state.totalElements), ?rangeLabel].join(' · ')
                : '',
            clearLabel: state.isFiltering ? l10n.clearFilters : null,
            onClear: _clearFilters,
          ),
          // Đang tải lại theo bộ lọc mới nhưng vẫn giữ danh sách cũ
          SizedBox(
            height: 2,
            child: state.isLoading && state.items.isNotEmpty ? const LinearProgressIndicator() : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: notifier.refresh,
              child: _buildBody(state, l10n, theme, rangeLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NewsListState state, AppLocalizations l10n, ThemeData theme, String? rangeLabel) {
    if (state.items.isEmpty) {
      if (state.isLoading) {
        return NewsListSkeleton(semanticsLabel: l10n.loading, padding: const EdgeInsets.fromLTRB(16, 4, 16, 16));
      }
      final Widget content;
      if (state.error != null) {
        content = _buildError(l10n, theme);
      } else if (state.isFiltering) {
        content = _buildNoMatch(state, l10n, theme, rangeLabel);
      } else {
        content = _buildEmptyState(l10n, theme, theme.colorScheme);
      }
      // Cuộn được để vẫn kéo xuống làm mới khi danh sách trống
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [SliverFillRemaining(hasScrollBody: false, child: content)],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: state.items.length + 1,
      itemBuilder: (context, index) {
        if (index == state.items.length) return _buildFooter(state, l10n, theme);
        return NewsCard(news: state.items[index]);
      },
    );
  }

  Widget _buildFooter(NewsListState state, AppLocalizations l10n, ThemeData theme) {
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (state.loadMoreError != null) {
      return Column(
        children: [
          Text(l10n.loadMoreNewsFailed, style: muted),
          TextButton(onPressed: ref.read(newsListProvider.notifier).loadMore, child: Text(l10n.retry)),
        ],
      );
    }
    // Chỉ nói "đã hết" khi đã cuộn qua nhiều trang; một trang thì dòng meta đã nêu tổng số
    if (!state.hasMore && state.page > 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.allNewsShown(state.totalElements), textAlign: TextAlign.center, style: muted),
      );
    }
    return const SizedBox.shrink();
  }

  /// Lỗi tải trang đầu: một câu điềm tĩnh + "Thử lại", không hiện lỗi kỹ thuật.
  Widget _buildError(AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 24, color: colorScheme.error),
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
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.newspaper_outlined,
                size: 44,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyNewsTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                l10n.emptyNewsDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
