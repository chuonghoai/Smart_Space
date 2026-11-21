import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/reports/providers/staff_map_reports_provider.dart';
import 'package:smartspace_staff/features/reports/repositories/report_repo.dart';
import 'package:smartspace_staff/features/reports/services/report_service.dart';
import 'package:smartspace_staff/ui/mobile/map/map_cluster_sheet.dart';
import 'package:smartspace_staff/ui/mobile/map/map_controller.dart';
import 'package:smartspace_staff/ui/shared/utils/open_in_google_maps.dart';

/// Repo giả: ghi lại tham số và trả response theo hàng đợi.
class _FakeReportRepo implements ReportRepo {
  final List<({String status, int limit})> calls = [];
  final List<Completer<ApiResponse<List<ReportModel>>>> pending = [];

  @override
  Future<ApiResponse<List<ReportModel>>> getStaffAssignedReports({
    String status = 'all',
    bool overdueOnly = false,
    int page = 0,
    int limit = 10,
  }) {
    calls.add((status: status, limit: limit));
    final completer = Completer<ApiResponse<List<ReportModel>>>();
    pending.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReportModel _report(
  String id, {
  ReportSeverity severity = ReportSeverity.low,
  ReportStatus status = ReportStatus.processing,
  bool? isReviewResolved,
  double lat = 10.8,
  double lng = 106.7,
  double? distance,
  DateTime? createdAt,
}) =>
    ReportModel(
      id: id,
      title: id,
      description: '',
      imageUrl: '',
      latitude: lat,
      longitude: lng,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      severity: severity,
      isReviewResolved: isReviewResolved,
      distanceInMeters: distance,
    );

ApiResponse<List<ReportModel>> _ok(List<ReportModel> reports) =>
    ApiResponse(success: true, message: 'ok', data: reports);

void main() {
  group('ReportModel getters', () {
    // Test Case ID: SMP-149
    // Description: Kiểm tra getter isDangerous của ReportModel chỉ trả về true khi severity là high hoặc critical.
    test('isDangerous: chỉ high / critical', () {
      expect(_report('a', severity: ReportSeverity.critical).isDangerous, isTrue);
      expect(_report('b', severity: ReportSeverity.high).isDangerous, isTrue);
      expect(_report('c', severity: ReportSeverity.medium).isDangerous, isFalse);
      expect(_report('d', severity: ReportSeverity.unknown).isDangerous, isFalse);
    });

    // Test Case ID: SMP-150
    // Description: Kiểm tra getter needsRehandling chỉ trả về true khi status là processing và isReviewResolved là false.
    test('needsRehandling: đang xử lý và bị đánh giá chưa thoả đáng', () {
      expect(_report('a', isReviewResolved: false).needsRehandling, isTrue);
      expect(_report('b', isReviewResolved: null).needsRehandling, isFalse);
      expect(
        _report('c', status: ReportStatus.processed, isReviewResolved: false).needsRehandling,
        isFalse,
      );
    });
  });

  // Test Case ID: SMP-151
  // Description: Kiểm tra MapState.getFilteredReports lọc tách biệt 2 nhóm Nguy hiểm và Thông thường không chồng lấn.
  test('MapState.getFilteredReports: 2 nhóm Nguy hiểm / Thông thường không chồng nhau', () {
    final reports = [
      _report('danger', severity: ReportSeverity.high),
      _report('normal', severity: ReportSeverity.medium),
      _report('unrated', severity: ReportSeverity.unknown),
    ];
    expect(const MapState().getFilteredReports(reports).map((r) => r.id),
        ['danger', 'normal', 'unrated']);
    expect(const MapState(showNormal: false).getFilteredReports(reports).map((r) => r.id),
        ['danger']);
    expect(const MapState(showDangerous: false).getFilteredReports(reports).map((r) => r.id),
        ['normal', 'unrated']);
  });

  group('MapState.getFilteredReports theo chip trạng thái', () {
    final reports = [
      _report('danger', severity: ReportSeverity.high),
      _report('danger-rehandling', severity: ReportSeverity.critical, isReviewResolved: false),
      _report('normal-rehandling', severity: ReportSeverity.low, isReviewResolved: false),
      _report('normal', severity: ReportSeverity.low),
    ];

    List<String> ids(MapState state) => state.getFilteredReports(reports).map((r) => r.id).toList();

    // Test Case ID: SMP-152
    // Description: Kiểm tra MapState mặc định dùng statusFilter = all và giữ lại mọi report kể cả việc cần xử lý lại.
    test('mặc định Tất cả: mọi việc đang xử lý, kể cả xử lý lại', () {
      expect(const MapState().statusFilter, StaffMapStatusFilter.all);
      expect(ids(const MapState()), ['danger', 'danger-rehandling', 'normal-rehandling', 'normal']);
    });

    // Test Case ID: SMP-153
    // Description: Kiểm tra khi statusFilter là processing thì loại bỏ các report cần xử lý lại.
    test('Đang xử lý: bỏ việc cần xử lý lại', () {
      expect(ids(const MapState(statusFilter: StaffMapStatusFilter.processing)), ['danger', 'normal']);
    });

    // Test Case ID: SMP-154
    // Description: Kiểm tra khi statusFilter là rehandling thì chỉ giữ các report bị đánh giá chưa thoả đáng.
    test('Xử lý lại: chỉ việc bị đánh giá chưa thoả đáng', () {
      expect(ids(const MapState(statusFilter: StaffMapStatusFilter.rehandling)),
          ['danger-rehandling', 'normal-rehandling']);
    });

    // Test Case ID: SMP-155
    // Description: Kiểm tra bộ lọc chip trạng thái (rehandling) kết hợp đồng thời với bộ lọc mức độ (showDangerous = false).
    test('chip trạng thái kết hợp với nút mức độ', () {
      expect(
        ids(const MapState(statusFilter: StaffMapStatusFilter.rehandling, showDangerous: false)),
        ['normal-rehandling'],
      );
    });

    // Test Case ID: SMP-156
    // Description: Kiểm tra MapController.setStatusFilter cập nhật statusFilter nhưng giữ nguyên trạng thái showDangerous đã bật/tắt.
    test('MapController.setStatusFilter giữ nguyên nút mức độ', () {
      final controller = MapController()..toggleDangerous();
      controller.setStatusFilter(StaffMapStatusFilter.rehandling);
      expect(controller.state.statusFilter, StaffMapStatusFilter.rehandling);
      expect(controller.state.showDangerous, isFalse);
      controller.dispose();
    });
  });

  // Test Case ID: SMP-157
  // Description: Kiểm tra googleMapsDirectionsUri tạo đúng HTTPS URL chỉ đường của Google Maps tới toạ độ truyền vào.
  test('googleMapsDirectionsUri: URL chỉ đường chính thức tới toạ độ report', () {
    final uri = googleMapsDirectionsUri(10.8231, 106.6297);
    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters, {'api': '1', 'destination': '10.8231,106.6297'});
  });

  group('MapClusterSheet.sortForCluster', () {
    // Test Case ID: SMP-158
    // Description: Kiểm tra MapClusterSheet.sortForCluster ưu tiên sắp xếp theo khoảng cách tăng dần khi mọi report đều có distance.
    test('có khoảng cách → gần nhất trước', () {
      final sorted = MapClusterSheet.sortForCluster([
        _report('far', distance: 900, severity: ReportSeverity.critical),
        _report('near', distance: 50),
        _report('mid', distance: 300),
      ]);
      expect(sorted.map((r) => r.id), ['near', 'mid', 'far']);
    });

    // Test Case ID: SMP-159
    // Description: Kiểm tra MapClusterSheet.sortForCluster khi thiếu khoảng cách GPS sẽ xếp theo mức độ nguy hiểm rồi mới nhất trước.
    test('không có GPS → nguy hiểm nhất trước, rồi mới nhất trước', () {
      final sorted = MapClusterSheet.sortForCluster([
        _report('low', severity: ReportSeverity.low),
        _report('high-old', severity: ReportSeverity.high, createdAt: DateTime(2026, 1, 1)),
        _report('high-new', severity: ReportSeverity.high, createdAt: DateTime(2026, 2, 1)),
        _report('critical', severity: ReportSeverity.critical),
      ]);
      expect(sorted.map((r) => r.id), ['critical', 'high-new', 'high-old', 'low']);
    });
  });

  group('StaffMapReportsNotifier', () {
    late _FakeReportRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeReportRepo();
      container = ProviderContainer(overrides: [
        staffMapReportsProvider.overrideWith(
          () => StaffMapReportsNotifier(service: ReportService(reportRepo: repo)),
        ),
      ]);
      // Giữ provider autoDispose sống trong suốt test
      container.listen(staffMapReportsProvider, (_, _) {}, fireImmediately: true);
    });

    tearDown(() => container.dispose());

    // Test Case ID: SMP-160
    // Description: Kiểm tra StaffMapReportsNotifier gọi API status='processing' với limit=100 và lọc bỏ report toạ độ (0, 0).
    test('lấy việc đang xử lý, độc lập với Home, limit 100; bỏ report không có toạ độ', () async {
      expect(repo.calls.single, (status: 'processing', limit: StaffMapReportsNotifier.limit));

      repo.pending.single.complete(_ok([_report('a'), _report('zero', lat: 0, lng: 0)]));
      final data = await container.read(staffMapReportsProvider.future);
      expect(data.reports.map((r) => r.id), ['a']);
      expect(data.truncated, isFalse);
    });

    // Test Case ID: SMP-161
    // Description: Kiểm tra StaffMapReportsNotifier đặt truncated = true khi API trả về số lượng report bằng limit (100).
    test('trả đủ limit → truncated', () async {
      repo.pending.single.complete(_ok([
        for (var i = 0; i < StaffMapReportsNotifier.limit; i++) _report('r$i'),
      ]));
      final data = await container.read(staffMapReportsProvider.future);
      expect(data.truncated, isTrue);
    });

    // Test Case ID: SMP-162
    // Description: Kiểm tra StaffMapReportsNotifier.refresh khi gặp lỗi vẫn giữ nguyên dữ liệu reports trước đó cùng trạng thái lỗi.
    test('refresh lỗi vẫn giữ dữ liệu cũ (bản đồ không bị trống)', () async {
      repo.pending.single.complete(_ok([_report('a')]));
      await container.read(staffMapReportsProvider.future);

      final refresh = container.read(staffMapReportsProvider.notifier).refresh();
      expect(container.read(staffMapReportsProvider).isLoading, isTrue);
      expect(container.read(staffMapReportsProvider).valueOrNull?.reports.single.id, 'a');

      repo.pending.last.complete(ApiResponse(success: false, message: 'boom'));
      await refresh;

      final state = container.read(staffMapReportsProvider);
      expect(state.hasError, isTrue);
      expect(state.valueOrNull?.reports.single.id, 'a');
    });
  });
}
