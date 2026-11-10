import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_response.dart';
import '../data/news_repository.dart';
import '../models/news_model.dart';
import '../models/news_page.dart';

/// Trạng thái danh sách tin tức phân trang + bộ lọc (từ khoá, khoảng ngày tạo).
class NewsListState {
  final List<NewsModel> items;

  /// Đang tải trang đầu (mở màn hình / đổi bộ lọc / làm mới).
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;

  /// Trang cuối đã tải (bắt đầu từ 1); 0 = chưa tải trang nào.
  final int page;

  /// Tổng số tin khớp bộ lọc hiện tại.
  final int totalElements;

  /// Lỗi khi tải trang đầu.
  final String? error;

  /// Lỗi khi tải thêm; danh sách đã có vẫn giữ nguyên.
  final String? loadMoreError;

  /// Từ khoá đã áp dụng (sau debounce), đã trim.
  final String search;

  /// Khoảng ngày tạo (chỉ phần ngày, cả 2 đầu đều bao gồm); null = mọi thời gian.
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const NewsListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.totalElements = 0,
    this.error,
    this.loadMoreError,
    this.search = '',
    this.dateFrom,
    this.dateTo,
  });

  bool get isFiltering => search.isNotEmpty || dateFrom != null || dateTo != null;

  /// [error], [loadMoreError], [dateFrom], [dateTo] nhận function để có thể gán `null` tường minh.
  NewsListState copyWith({
    List<NewsModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    int? totalElements,
    String? Function()? error,
    String? Function()? loadMoreError,
    String? search,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
  }) {
    return NewsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      totalElements: totalElements ?? this.totalElements,
      error: error != null ? error() : this.error,
      loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
      search: search ?? this.search,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
    );
  }
}

class NewsListNotifier extends StateNotifier<NewsListState> {
  static const int pageSize = 10;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final NewsRepository _repository;
  Timer? _debounce;

  /// Tăng mỗi lần tải lại trang đầu; response của lần cũ về muộn thì bỏ qua.
  int _requestId = 0;

  NewsListNotifier(this._repository) : super(const NewsListState()) {
    refresh();
  }

  /// Tải lại trang đầu theo bộ lọc hiện tại.
  Future<void> refresh() async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, isLoadingMore: false, error: () => null, loadMoreError: () => null);

    try {
      final res = await _fetch(1);
      if (!mounted || requestId != _requestId) return;
      final page = res.data;
      if (res.success && page != null) {
        state = state.copyWith(
          items: page.items,
          isLoading: false,
          hasMore: page.hasMore,
          page: 1,
          totalElements: page.totalElements,
        );
      } else {
        state = state.copyWith(items: const [], isLoading: false, hasMore: false, error: () => res.message);
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(items: const [], isLoading: false, hasMore: false, error: () => e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final requestId = _requestId;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, loadMoreError: () => null);

    try {
      final res = await _fetch(nextPage);
      if (!mounted || requestId != _requestId) return;
      final page = res.data;
      if (res.success && page != null) {
        state = state.copyWith(
          items: [...state.items, ...page.items],
          isLoadingMore: false,
          hasMore: page.hasMore,
          page: nextPage,
          totalElements: page.totalElements,
        );
      } else {
        state = state.copyWith(isLoadingMore: false, loadMoreError: () => res.message);
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false, loadMoreError: () => e.toString());
    }
  }

  /// Tìm trong tiêu đề / nội dung, debounce để không gọi API mỗi phím gõ.
  void setSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final keyword = query.trim();
      if (!mounted || keyword == state.search) return;
      state = state.copyWith(search: keyword);
      refresh();
    });
  }

  /// Lọc theo ngày tạo; [start] / [end] chỉ lấy phần ngày, đảo lại nếu ngược. null = mọi thời gian.
  void setDateRange(DateTime? start, DateTime? end) {
    var from = start == null ? null : DateTime(start.year, start.month, start.day);
    var to = end == null ? null : DateTime(end.year, end.month, end.day);
    if (from != null && to != null && from.isAfter(to)) {
      final swap = from;
      from = to;
      to = swap;
    }
    if (from == state.dateFrom && to == state.dateTo) return;
    state = state.copyWith(dateFrom: () => from, dateTo: () => to);
    refresh();
  }

  void clearFilters() {
    _debounce?.cancel();
    if (!state.isFiltering) return;
    state = state.copyWith(search: '', dateFrom: () => null, dateTo: () => null);
    refresh();
  }

  Future<ApiResponse<NewsPage>> _fetch(int page) {
    return _repository.getNews(
      page: page,
      size: pageSize,
      search: state.search,
      from: state.dateFrom,
      to: state.dateTo,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Danh sách tin tức (màn hình Tin tức của Client / Staff / Admin).
final newsListProvider = StateNotifierProvider.autoDispose<NewsListNotifier, NewsListState>(
  (ref) => NewsListNotifier(newsRepository),
);

final newsDetailProvider =
    FutureProvider.autoDispose.family<NewsModel, String>((ref, id) async {
  final res = await newsRepository.getNewsDetail(id);
  if (res.success && res.data != null) {
    return res.data!;
  }
  throw Exception(res.message);
});

/// 5 tin mới nhất cho Home: chỉ tải đúng 5 tin, không phụ thuộc danh sách đầy đủ.
final latestNewsProvider =
    FutureProvider.autoDispose<List<NewsModel>>((ref) async {
  final res = await newsRepository.getNews(page: 1, size: 5);
  if (res.success && res.data != null) {
    return res.data!.items;
  }
  throw Exception(res.message);
});
