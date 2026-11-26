import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/features/reports/models/feed_sort.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

class ReportFeedState {
  final List<ReportFeedItem> items;
  final int page;
  final bool hasMore;

  /// Tổng số phản ánh khớp bộ lọc hiện tại (mọi trang).
  final int totalElements;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  final FeedSort sort;
  final ReportStatus? statusFilter;
  final EReportSeverity? severityFilter;

  /// Khoảng ngày tạo; null = mọi thời gian.
  final ReportDateRange? dateRangeFilter;
  final String searchQuery;

  /// Đã chọn "Gần tôi" nhưng không lấy được vị trí → đã quay về "Mới nhất". UI báo cho người dùng.
  final bool nearbyUnavailable;

  const ReportFeedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.totalElements = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.sort = FeedSort.latest,
    this.statusFilter,
    this.severityFilter,
    this.dateRangeFilter,
    this.searchQuery = '',
    this.nearbyUnavailable = false,
  });

  /// Đang thu hẹp kết quả (sắp xếp không tính là lọc).
  bool get isFiltering =>
      statusFilter != null || severityFilter != null || dateRangeFilter != null || searchQuery.isNotEmpty;

  /// Các field nullable nhận function để có thể gán `null` (Tất cả) tường minh.
  ReportFeedState copyWith({
    List<ReportFeedItem>? items,
    int? page,
    bool? hasMore,
    int? totalElements,
    bool? isLoading,
    bool? isLoadingMore,
    String? Function()? error,
    FeedSort? sort,
    ReportStatus? Function()? statusFilter,
    EReportSeverity? Function()? severityFilter,
    ReportDateRange? Function()? dateRangeFilter,
    String? searchQuery,
    bool? nearbyUnavailable,
  }) =>
      ReportFeedState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        totalElements: totalElements ?? this.totalElements,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error != null ? error() : this.error,
        sort: sort ?? this.sort,
        statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
        severityFilter: severityFilter != null ? severityFilter() : this.severityFilter,
        dateRangeFilter: dateRangeFilter != null ? dateRangeFilter() : this.dateRangeFilter,
        searchQuery: searchQuery ?? this.searchQuery,
        nearbyUnavailable: nearbyUnavailable ?? this.nearbyUnavailable,
      );
}

class ReportFeedNotifier extends StateNotifier<ReportFeedState> {
  static const int _pageSize = 10;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  final ReportService _service;
  final Future<({double lat, double lng})?> Function() _getPosition;
  Timer? _debounce;

  /// Tăng mỗi lần tải lại trang 1 — response của lần tải cũ hơn bị bỏ qua.
  int _requestId = 0;
  double? _lat;
  double? _lng;

  ReportFeedNotifier(
    this._service, {
    Future<({double lat, double lng})?> Function()? getPosition,
  })  : _getPosition = getPosition ?? _deviceLocation,
        super(const ReportFeedState()) {
    refresh();
  }

  static Future<({double lat, double lng})?> _deviceLocation() async {
    final pos = await locationService.getCurrentPosition();
    return pos == null ? null : (lat: pos.latitude, lng: pos.longitude);
  }

  /// Kéo làm mới / thử lại: giữ nguyên sắp xếp, bộ lọc và từ khoá.
  Future<void> refresh() {
    _debounce?.cancel();
    return _loadFirstPage();
  }

  void setSort(FeedSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    _loadFirstPage(clearList: true);
  }

  void setStatus(ReportStatus? status) {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: () => status);
    _loadFirstPage(clearList: true);
  }

  void setSeverity(EReportSeverity? severity) {
    if (severity == state.severityFilter) return;
    state = state.copyWith(severityFilter: () => severity);
    _loadFirstPage(clearList: true);
  }

  /// Tìm theo tiêu đề / mô tả / địa chỉ, debounce để không gọi API mỗi phím gõ.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      final keyword = query.trim();
      if (keyword == state.searchQuery) return;
      state = state.copyWith(searchQuery: keyword);
      _loadFirstPage(clearList: true);
    });
  }

  /// Khoảng ngày tạo (null = mọi thời gian).
  void setDateRange(ReportDateRange? range) {
    if (range == state.dateRangeFilter) return;
    state = state.copyWith(dateRangeFilter: () => range);
    _loadFirstPage(clearList: true);
  }

  /// Bỏ trạng thái, mức độ, khoảng ngày và từ khoá; giữ cách sắp xếp.
  void clearFilters() {
    _debounce?.cancel();
    if (!state.isFiltering) return;
    state = state.copyWith(
      statusFilter: () => null,
      severityFilter: () => null,
      dateRangeFilter: () => null,
      searchQuery: '',
    );
    _loadFirstPage(clearList: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final requestId = _requestId;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _fetch(nextPage);
      if (!mounted || requestId != _requestId) return;
      if (!res.success || res.data == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }
      // Bỏ bản ghi trùng khi dữ liệu bị dịch trang (có phản ánh mới giữa 2 lần tải)
      final loadedIds = state.items.map((i) => i.report.id).toSet();
      state = state.copyWith(
        items: [...state.items, ...res.data!.items.where((i) => !loadedIds.contains(i.report.id))],
        page: nextPage,
        hasMore: nextPage < res.data!.totalPages,
        totalElements: res.data!.totalElements,
        isLoadingMore: false,
      );
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// [clearList] = true khi đổi sắp xếp/bộ lọc để không hiển thị dữ liệu của lựa chọn cũ trong lúc chờ.
  Future<void> _loadFirstPage({bool clearList = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(
      items: clearList ? const [] : null,
      isLoading: true,
      isLoadingMore: false,
      error: () => null,
      nearbyUnavailable: false,
    );
    try {
      if (state.sort == FeedSort.nearby) {
        final pos = await _getPosition();
        if (!mounted || requestId != _requestId) return;
        _lat = pos?.lat;
        _lng = pos?.lng;
        if (pos == null) {
          state = state.copyWith(sort: FeedSort.latest, items: const [], nearbyUnavailable: true);
        }
      }
      final res = await _fetch(1);
      if (!mounted || requestId != _requestId) return;
      if (!res.success || res.data == null) {
        state = state.copyWith(isLoading: false, error: () => res.message);
        return;
      }
      state = state.copyWith(
        items: res.data!.items,
        page: 1,
        hasMore: 1 < res.data!.totalPages,
        totalElements: res.data!.totalElements,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, error: () => e.toString());
    }
  }

  Future<ApiResponse<ReportFeedPage>> _fetch(int page) {
    final nearby = state.sort == FeedSort.nearby;
    return _service.getFeed(
      status: state.statusFilter?.name,
      severity: state.severityFilter,
      dateRange: state.dateRangeFilter,
      search: state.searchQuery,
      sort: state.sort,
      page: page,
      size: _pageSize,
      lat: nearby ? _lat : null,
      lng: nearby ? _lng : null,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final reportFeedProvider =
    StateNotifierProvider.autoDispose<ReportFeedNotifier, ReportFeedState>(
        (ref) => ReportFeedNotifier(reportService));
