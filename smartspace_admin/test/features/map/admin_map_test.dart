import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/admin_map_reports_result.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/features/map/services/map_service.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/map_cluster_sheet.dart';

/// Service giả: mỗi lần gọi trả về một Completer để test điều khiển thứ tự response.
class _FakeMapService extends MapService {
  final List<({String? status, MapBounds? bounds})> calls = [];
  final List<Completer<ApiResponse<AdminMapReportsResult>>> pending = [];

  @override
  Future<ApiResponse<AdminMapReportsResult>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    MapBounds? bounds,
    int limit = 500,
  }) {
    calls.add((status: status, bounds: bounds));
    final completer = Completer<ApiResponse<AdminMapReportsResult>>();
    pending.add(completer);
    return completer.future;
  }
}

MapReportModel _report(String id, {String status = 'processing', DateTime? createdAt}) =>
    MapReportModel(
      id: id,
      title: id,
      status: status,
      latitude: 10.8,
      longitude: 106.7,
      createdAt: createdAt,
    );

ApiResponse<AdminMapReportsResult> _ok(List<String> ids, {bool truncated = false}) => ApiResponse(
      success: true,
      message: 'ok',
      data: AdminMapReportsResult(reports: ids.map(_report).toList(), truncated: truncated),
    );

void main() {
  group('AdminMapReportsResult.fromJson', () {
    test('parse reports và truncated', () {
      final result = AdminMapReportsResult.fromJson({
        'reports': [
          {'id': 'a', 'title': 'A', 'status': 'PENDING', 'latitude': 1, 'longitude': 2},
        ],
        'truncated': true,
      });
      expect(result.reports.single.id, 'a');
      expect(result.reports.single.isPending, isTrue);
      expect(result.truncated, isTrue);
    });

    test('thiếu trường → rỗng, không truncated', () {
      final result = AdminMapReportsResult.fromJson({});
      expect(result.reports, isEmpty);
      expect(result.truncated, isFalse);
    });
  });

  test('MapClusterSheet.sortForCluster: chờ xử lý trước, rồi mới nhất trước', () {
    final sorted = MapClusterSheet.sortForCluster([
      _report('done-new', status: 'processed', createdAt: DateTime(2026, 3, 1)),
      _report('pending-old', status: 'pending', createdAt: DateTime(2026, 1, 1)),
      _report('no-date', status: 'processing'),
      _report('pending-new', status: 'pending', createdAt: DateTime(2026, 2, 1)),
      _report('done-old', status: 'processed', createdAt: DateTime(2026, 1, 15)),
    ]);
    expect(
      sorted.map((r) => r.id),
      ['pending-new', 'pending-old', 'done-new', 'done-old', 'no-date'],
    );
  });

  group('MapReportsNotifier', () {
    const viewport = MapBounds(minLat: 10.7, maxLat: 10.9, minLng: 106.6, maxLng: 106.8);

    late _FakeMapService service;
    late ProviderContainer container;

    setUp(() {
      service = _FakeMapService();
      container = ProviderContainer(overrides: [
        mapReportsProvider.overrideWith(() => MapReportsNotifier(service: service)),
      ]);
    });

    tearDown(() => container.dispose());

    MapReportsNotifier notifier() => container.read(mapReportsProvider.notifier);

    test('gửi khung mở rộng kèm bộ lọc hiện tại', () async {
      container.read(mapFilterProvider.notifier).state =
          const ReportFilter(size: 500, status: 'pending');
      final future = notifier().loadForViewport(viewport);

      expect(service.calls.single.status, 'pending');
      expect(service.calls.single.bounds, viewport.expandBy(1.5));

      service.pending.single.complete(_ok(['a'], truncated: true));
      await future;
      final state = container.read(mapReportsProvider);
      expect(state.reports.map((r) => r.id), ['a']);
      expect(state.truncated, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('đang tải lại vẫn giữ dữ liệu cũ (bản đồ không bị dựng lại)', () async {
      final first = notifier().loadForViewport(viewport);
      service.pending.single.complete(_ok(['a']));
      await first;

      unawaited(notifier().refresh());
      final state = container.read(mapReportsProvider);
      expect(state.isLoading, isTrue);
      expect(state.reports.map((r) => r.id), ['a']);
    });

    test('đổi bộ lọc → tải lại ngay khung đang xem với bộ lọc mới', () async {
      container.read(mapReportsProvider); // khởi tạo notifier để lắng nghe bộ lọc
      final first = notifier().loadForViewport(viewport);
      service.pending.single.complete(_ok(['a']));
      await first;

      container.read(mapFilterProvider.notifier).state =
          const ReportFilter(size: 500, status: 'rejected');

      expect(service.calls, hasLength(2));
      expect(service.calls.last.status, 'rejected');
      expect(service.calls.last.bounds, viewport.expandBy(1.5));
    });

    test('lỗi: giữ dữ liệu cũ và lưu error', () async {
      final first = notifier().loadForViewport(viewport);
      service.pending.single.complete(_ok(['a']));
      await first;

      final second = notifier().refresh();
      service.pending.last.complete(ApiResponse(success: false, message: 'boom'));
      await second;

      final state = container.read(mapReportsProvider);
      expect(state.reports.map((r) => r.id), ['a']);
      expect(state.error, 'boom');
      expect(state.isLoading, isFalse);
    });

    test('response của request cũ về sau request mới thì bị bỏ', () async {
      final first = notifier().loadForViewport(viewport);
      final second = notifier().loadForViewport(viewport, force: true);

      service.pending[1].complete(_ok(['new']));
      await second;
      service.pending[0].complete(_ok(['stale']));
      await first;

      expect(container.read(mapReportsProvider).reports.map((r) => r.id), ['new']);
    });
  });
}
