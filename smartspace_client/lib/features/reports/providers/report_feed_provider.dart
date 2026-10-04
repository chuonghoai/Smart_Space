import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_shared/util/location_service.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

enum FeedTab { latest, nearby }

class ReportFeedState {
  final List<ReportFeedItem> items;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final ReportStatus? statusFilter;
  final FeedTab tab;

  const ReportFeedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.statusFilter,
    this.tab = FeedTab.latest,
  });

  /// [statusFilter] uses a function so `null` (All) can be set explicitly.
  ReportFeedState copyWith({
    List<ReportFeedItem>? items,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? Function()? error,
    ReportStatus? Function()? statusFilter,
    FeedTab? tab,
  }) =>
      ReportFeedState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error != null ? error() : this.error,
        statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
        tab: tab ?? this.tab,
      );
}

class ReportFeedNotifier extends StateNotifier<ReportFeedState> {
  final ReportService _service;
  static const _pageSize = 10;
  double? _lat;
  double? _lng;

  ReportFeedNotifier(this._service) : super(const ReportFeedState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: () => null);
    if (state.tab == FeedTab.nearby) {
      final pos = await locationService.getCurrentPosition();
      _lat = pos?.latitude;
      _lng = pos?.longitude;
      if (pos == null) state = state.copyWith(tab: FeedTab.latest);
    }
    await _load(1);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.page + 1);
  }

  void setFilter(ReportStatus? status) {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: () => status);
    refresh();
  }

  void setTab(FeedTab tab) {
    if (tab == state.tab) return;
    state = state.copyWith(tab: tab);
    refresh();
  }

  Future<void> _load(int page) async {
    final nearby = state.tab == FeedTab.nearby;
    try {
      final res = await _service.getFeed(
        status: state.statusFilter?.name,
        page: page,
        size: _pageSize,
        lat: nearby ? _lat : null,
        lng: nearby ? _lng : null,
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        state = state.copyWith(isLoading: false, isLoadingMore: false, error: () => res.message);
        return;
      }
      final items = [...(page == 1 ? <ReportFeedItem>[] : state.items), ...res.data!.items];
      // ponytail: "Gần tôi" sorts only loaded items client-side; move to a geo-paged backend query when the dataset grows.
      if (nearby) {
        items.sort((a, b) => (a.report.distanceInMeters ?? double.infinity)
            .compareTo(b.report.distanceInMeters ?? double.infinity));
      }
      state = state.copyWith(
        items: items,
        page: page,
        hasMore: page < res.data!.totalPages,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: () => e.toString());
    }
  }
}

final reportFeedProvider =
    StateNotifierProvider.autoDispose<ReportFeedNotifier, ReportFeedState>(
        (ref) => ReportFeedNotifier(reportService));
