import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/feed_sort.dart';
import 'package:smartspace_client/features/reports/models/my_reports_page_model.dart';
import 'package:smartspace_client/features/reports/models/report_date_range.dart';
import 'package:smartspace_client/features/reports/models/report_feed_model.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/my_reports_provider.dart';
import 'package:smartspace_client/features/reports/providers/report_feed_provider.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

/// Tham số của một lần gọi danh sách (Bảng tin hoặc Phản ánh của tôi).
class _Call {
  final String? status;
  final EReportSeverity? severity;
  final ReportDateRange? dateRange;
  final String? search;
  final FeedSort? sort;
  final int page;
  final double? lat;
  final double? lng;

  _Call({
    this.status,
    this.severity,
    this.dateRange,
    this.search,
    this.sort,
    required this.page,
    this.lat,
    this.lng,
  });
}

/// Repo giả: mỗi lần gọi trả về một Completer để test điều khiển thứ tự response.
class _FakeReportRepo implements ReportRepo {
  final List<_Call> feedCalls = [];
  final List<Completer<ApiResponse<ReportFeedPage>>> feedPending = [];
  final List<_Call> myCalls = [];
  final List<Completer<ApiResponse<MyReportsPage>>> myPending = [];

  @override
  Future<ApiResponse<ReportFeedPage>> getFeed({
    String? status,
    EReportSeverity? severity,
    ReportDateRange? dateRange,
    String? search,
    FeedSort sort = FeedSort.latest,
    int page = 1,
    int size = 10,
    double? lat,
    double? lng,
  }) {
    feedCalls.add(_Call(
      status: status,
      severity: severity,
      dateRange: dateRange,
      search: search,
      sort: sort,
      page: page,
      lat: lat,
      lng: lng,
    ));
    final completer = Completer<ApiResponse<ReportFeedPage>>();
    feedPending.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<MyReportsPage>> getMyReports({
    String? status,
    EReportSeverity? severity,
    ReportDateRange? dateRange,
    String? search,
    int page = 1,
    int size = 20,
  }) {
    myCalls.add(_Call(status: status, severity: severity, dateRange: dateRange, search: search, page: page));
    final completer = Completer<ApiResponse<MyReportsPage>>();
    myPending.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<MyReportsSummary>> getMyReportsSummary() async =>
      ApiResponse(success: true, message: 'ok', data: const MyReportsSummary(total: 3));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ApiResponse<ReportFeedPage> _feedPage({int total = 0, int totalPages = 1}) => ApiResponse(
      success: true,
      message: 'ok',
      data: ReportFeedPage(items: const [], totalPages: totalPages, totalElements: total),
    );

ApiResponse<MyReportsPage> _myPage({int total = 0}) => ApiResponse(
      success: true,
      message: 'ok',
      data: MyReportsPage(items: const [], totalPages: 1, totalElements: total),
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  group('ReportDateRange', () {
    test('bỏ giờ, đảo đầu-cuối nếu ngược, định dạng yyyy-MM-dd cho API', () {
      final range = ReportDateRange(start: DateTime(2026, 3, 15, 18, 30), end: DateTime(2026, 3, 1, 7));
      expect(range.fromQuery, '2026-03-01');
      expect(range.toQuery, '2026-03-15');
      expect(range.isSingleDay, isFalse);
    });

    test('một ngày cụ thể: start trùng end', () {
      final day = ReportDateRange(start: DateTime(2026, 1, 9, 23, 59), end: DateTime(2026, 1, 9));
      expect(day.isSingleDay, isTrue);
      expect(day.fromQuery, day.toQuery);
      expect(day, ReportDateRange(start: DateTime(2026, 1, 9), end: DateTime(2026, 1, 9)));
    });
  });

  group('ReportFeedNotifier', () {
    late _FakeReportRepo repo;

    setUp(() => repo = _FakeReportRepo());

    ReportFeedNotifier build({({double lat, double lng})? position = (lat: 10.77, lng: 106.69)}) =>
        ReportFeedNotifier(ReportService(reportRepo: repo), getPosition: () async => position);

    test('đổi mức độ → tải lại trang 1 với severity, xoá danh sách cũ', () async {
      final notifier = build();
      await _flush();
      repo.feedPending.last.complete(_feedPage(total: 12));
      await _flush();

      notifier.setSeverity(EReportSeverity.high);
      await _flush();

      expect(repo.feedCalls.last.severity, EReportSeverity.high);
      expect(repo.feedCalls.last.page, 1);
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.isFiltering, isTrue);
    });

    test('response cũ về sau response mới thì bị bỏ qua', () async {
      final notifier = build();
      await _flush();
      final firstRequest = repo.feedPending.last;

      notifier.setStatus(ReportStatus.processing);
      await _flush();
      repo.feedPending.last.complete(_feedPage(total: 5));
      await _flush();
      firstRequest.complete(_feedPage(total: 99));
      await _flush();

      expect(notifier.state.totalElements, 5);
      expect(notifier.state.statusFilter, ReportStatus.processing);
    });

    test('"Gần tôi" gửi sort=nearby kèm toạ độ để backend sắp xếp theo khoảng cách', () async {
      final notifier = build();
      await _flush();

      notifier.setSort(FeedSort.nearby);
      await _flush();

      final call = repo.feedCalls.last;
      expect(call.sort, FeedSort.nearby);
      expect(call.lat, 10.77);
      expect(call.lng, 106.69);
    });

    test('"Gần tôi" không có vị trí → quay về Mới nhất và báo nearbyUnavailable', () async {
      final notifier = build(position: null);
      await _flush();

      notifier.setSort(FeedSort.nearby);
      await _flush();

      expect(notifier.state.sort, FeedSort.latest);
      expect(notifier.state.nearbyUnavailable, isTrue);
      expect(repo.feedCalls.last.sort, FeedSort.latest);
      expect(repo.feedCalls.last.lat, isNull);
    });

    test('kéo làm mới giữ nguyên sắp xếp, trạng thái và mức độ', () async {
      final notifier = build();
      await _flush();
      notifier
        ..setSort(FeedSort.nearby)
        ..setStatus(ReportStatus.pending)
        ..setSeverity(EReportSeverity.critical);
      await _flush();

      unawaited(notifier.refresh());
      await _flush();

      final call = repo.feedCalls.last;
      expect(call.sort, FeedSort.nearby);
      expect(call.status, ReportStatus.pending.name);
      expect(call.severity, EReportSeverity.critical);
    });

    test('Xoá lọc bỏ trạng thái, mức độ, từ khoá nhưng giữ sắp xếp', () async {
      final notifier = build();
      await _flush();
      notifier
        ..setSort(FeedSort.nearby)
        ..setStatus(ReportStatus.processed)
        ..setSeverity(EReportSeverity.low)
        ..search('đèn');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.feedCalls.last.search, 'đèn');

      notifier.clearFilters();
      await _flush();

      final call = repo.feedCalls.last;
      expect(call.status, isNull);
      expect(call.severity, isNull);
      expect(call.search, isEmpty);
      expect(call.sort, FeedSort.nearby);
      expect(notifier.state.isFiltering, isFalse);
    });
  });

  group('Lọc theo ngày', () {
    late _FakeReportRepo repo;
    final march = ReportDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 15));

    setUp(() => repo = _FakeReportRepo());

    test('Bảng tin: chọn ngày → tải trang 1 với dateRange; làm mới giữ; Xoá lọc bỏ', () async {
      final notifier = ReportFeedNotifier(ReportService(reportRepo: repo), getPosition: () async => null);
      await _flush();

      notifier.setDateRange(march);
      await _flush();
      expect(repo.feedCalls.last.dateRange, march);
      expect(repo.feedCalls.last.page, 1);
      expect(notifier.state.isFiltering, isTrue);

      unawaited(notifier.refresh());
      await _flush();
      expect(repo.feedCalls.last.dateRange, march);

      notifier.clearFilters();
      await _flush();
      expect(repo.feedCalls.last.dateRange, isNull);
      expect(notifier.state.dateRangeFilter, isNull);
    });

    test('Phản ánh của tôi: chọn lại đúng khoảng ngày cũ không gọi API thêm', () async {
      final notifier = MyReportsNotifier(ReportService(reportRepo: repo));
      await _flush();
      notifier.setDateRange(march);
      await _flush();
      final callsAfterFirstPick = repo.myCalls.length;
      expect(repo.myCalls.last.dateRange, march);

      notifier.setDateRange(ReportDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 15)));
      await _flush();
      expect(repo.myCalls.length, callsAfterFirstPick);

      notifier.setDateRange(null);
      await _flush();
      expect(repo.myCalls.last.dateRange, isNull);
    });
  });

  group('MyReportsNotifier', () {
    late _FakeReportRepo repo;

    setUp(() => repo = _FakeReportRepo());

    test('lọc mức độ gửi severity; làm mới giữ cả trạng thái và mức độ', () async {
      final notifier = MyReportsNotifier(ReportService(reportRepo: repo));
      await _flush();
      repo.myPending.last.complete(_myPage(total: 3));
      await _flush();

      notifier
        ..setFilter('rehandling')
        ..setSeverity(EReportSeverity.medium);
      await _flush();
      expect(repo.myCalls.last.severity, EReportSeverity.medium);
      expect(repo.myCalls.last.status, 'rehandling');

      unawaited(notifier.refresh());
      await _flush();
      expect(repo.myCalls.last.severity, EReportSeverity.medium);
      expect(repo.myCalls.last.status, 'rehandling');
      expect(repo.myCalls.last.page, 1);
    });

    test('Xoá lọc trả về toàn bộ phản ánh', () async {
      final notifier = MyReportsNotifier(ReportService(reportRepo: repo));
      await _flush();
      notifier.setSeverity(EReportSeverity.high);
      await _flush();

      notifier.clearFilters();
      await _flush();

      expect(repo.myCalls.last.severity, isNull);
      expect(repo.myCalls.last.status, isNull);
      expect(notifier.state.isFiltering, isFalse);
    });
  });
}
