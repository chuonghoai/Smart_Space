import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_date_range.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/models/report_statistics_model.dart';
import 'package:smartspace_staff/features/reports/models/staff_report_sort.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';
import 'package:smartspace_staff/ui/mobile/reports/all_reports_controller.dart';

typedef _Call = ({
  String status,
  ReportSeverity? severity,
  String? search,
  ReportDateRange? dateRange,
  StaffReportSort sort,
  int page,
  int limit,
});

/// Repo giả: ghi lại tham số; mỗi lần gọi trả về một Completer để test tự quyết thứ tự response.
class _FakeReportRepo implements ReportRepo {
  final List<_Call> calls = [];
  final List<Completer<ApiResponse<List<ReportModel>>>> pending = [];
  int statsCalls = 0;

  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({
    String status = 'all',
    ReportSeverity? severity,
    String? search,
    ReportDateRange? dateRange,
    StaffReportSort sort = StaffReportSort.latest,
    int page = 0,
    int limit = 10,
  }) {
    calls.add((
      status: status,
      severity: severity,
      search: search,
      dateRange: dateRange,
      sort: sort,
      page: page,
      limit: limit,
    ));
    final completer = Completer<ApiResponse<List<ReportModel>>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<ReportStatisticsModel>> getStaffStatistics() async {
    statsCalls++;
    return ApiResponse(
      success: true,
      message: 'ok',
      data: ReportStatisticsModel(total: 3, byStatus: {'processing': 2, 'resolved': 1, 'rehandling': 1}),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReportModel _report(String id) => ReportModel(
      id: id,
      title: id,
      description: '',
      imageUrl: '',
      latitude: 10.8,
      longitude: 106.7,
      status: ReportStatus.processing,
      createdAt: DateTime(2026, 1, 1),
    );

ApiResponse<List<ReportModel>> _ok(List<ReportModel> reports) =>
    ApiResponse(success: true, message: 'ok', data: reports);

List<ReportModel> _page(String prefix, int count) => [for (var i = 0; i < count; i++) _report('$prefix$i')];

void main() {
  late _FakeReportRepo repo;
  late AllReportsController controller;

  AllReportsController create({String initialFilter = 'all'}) {
    repo = _FakeReportRepo();
    return AllReportsController(service: ReportService(reportRepo: repo), initialFilter: initialFilter);
  }

  /// Trả response cho lần gọi thứ [index] và chờ controller xử lý xong.
  Future<void> respond(int index, List<ReportModel> reports) async {
    repo.pending[index].complete(_ok(reports));
    await pumpEventQueue();
  }

  tearDown(() => controller.dispose());

  test('Mở màn hình: dùng initialFilter, các bộ lọc khác mặc định, tải số đếm', () async {
    controller = create(initialFilter: 'rehandling');
    await respond(0, [_report('a')]);

    final call = repo.calls.single;
    expect(call.status, 'rehandling');
    expect(call.severity, isNull);
    expect(call.search, '');
    expect(call.dateRange, isNull);
    expect(call.sort, StaffReportSort.latest);
    expect(call.page, 0);
    expect(repo.statsCalls, 1);
    expect(controller.state.reports.map((r) => r.id), ['a']);
    expect(controller.state.stats?.total, 3);
    expect(controller.state.isFiltering, isTrue);
  });

  test('Đổi mức độ / khoảng ngày / sắp xếp: tải lại trang đầu, không tải lại số đếm', () async {
    controller = create();
    await respond(0, [_report('a')]);
    final range = ReportDateRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 15));

    controller.setSeverity(ReportSeverity.high);
    await respond(1, []);
    controller.setDateRange(range);
    await respond(2, []);
    controller.setSort(StaffReportSort.severity);
    await respond(3, []);

    final last = repo.calls.last;
    expect(last.severity, ReportSeverity.high);
    expect(last.dateRange, range);
    expect(last.sort, StaffReportSort.severity);
    expect(last.page, 0);
    expect(repo.statsCalls, 1);
    expect(controller.state.stats?.total, 3, reason: 'Giữ số đếm cũ khi không tải lại');
  });

  test('Chọn lại đúng giá trị đang chọn thì không gọi API', () async {
    controller = create();
    await respond(0, []);

    controller.setFilter('all');
    controller.setSeverity(null);
    controller.setSort(StaffReportSort.latest);

    expect(repo.calls, hasLength(1));
  });

  testWidgets('Tìm kiếm: debounce, chỉ gọi 1 lần với từ khoá cuối đã trim', (tester) async {
    controller = create();
    repo.pending[0].complete(_ok([]));
    await tester.pump();

    controller.setSearch('đè');
    await tester.pump(const Duration(milliseconds: 100));
    controller.setSearch('  đèn đường ');
    await tester.pump(const Duration(milliseconds: 299));
    expect(repo.calls, hasLength(1), reason: 'Chưa hết thời gian debounce');

    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.calls, hasLength(2));
    expect(repo.calls.last.search, 'đèn đường');
    expect(controller.state.search, 'đèn đường');
    repo.pending[1].complete(_ok([]));
    await tester.pump();
  });

  test('Response của bộ lọc cũ về muộn bị bỏ qua', () async {
    controller = create();
    controller.setSeverity(ReportSeverity.critical); // lần gọi đầu chưa trả về

    await respond(1, [_report('new')]);
    await respond(0, [_report('old')]);

    expect(controller.state.reports.map((r) => r.id), ['new']);
    expect(controller.state.isLoading, isFalse);
  });

  test('Tải thêm: giữ bộ lọc, sang trang kế, nối vào danh sách', () async {
    controller = create();
    await respond(0, _page('a', 20));
    controller.setSeverity(ReportSeverity.medium);
    await respond(1, _page('b', 20));

    controller.loadMore();
    await respond(2, _page('c', 5));

    final call = repo.calls.last;
    expect(call.page, 1);
    expect(call.severity, ReportSeverity.medium);
    expect(controller.state.reports, hasLength(25));
    expect(controller.state.hasMore, isFalse);
  });

  test('Trang tải thêm của bộ lọc cũ không bị nối vào danh sách mới', () async {
    controller = create();
    await respond(0, _page('a', 20));

    controller.loadMore(); // lần gọi 1, chưa trả về
    controller.setSeverity(ReportSeverity.low); // lần gọi 2
    await respond(2, [_report('fresh')]);
    await respond(1, _page('stale', 20));

    expect(controller.state.reports.map((r) => r.id), ['fresh']);
  });

  test('Xoá lọc: về mặc định nhưng giữ thứ tự sắp xếp; đổi sắp xếp không tính là đang lọc', () async {
    controller = create(initialFilter: 'processing');
    await respond(0, []);
    controller.setSeverity(ReportSeverity.high);
    await respond(1, []);
    controller.setSort(StaffReportSort.oldest);
    await respond(2, []);

    controller.clearFilters();
    await respond(3, []);

    final call = repo.calls.last;
    expect(call.status, 'all');
    expect(call.severity, isNull);
    expect(call.dateRange, isNull);
    expect(call.search, '');
    expect(call.sort, StaffReportSort.oldest);
    expect(controller.state.isFiltering, isFalse);

    controller.clearFilters();
    expect(repo.calls, hasLength(4), reason: 'Không lọc gì thì không gọi lại API');
  });
}
