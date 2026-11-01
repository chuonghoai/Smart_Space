import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartspace_admin/features/map/application/map_providers.dart';
import 'package:smartspace_admin/features/map/models/admin_map_reports_result.dart';
import 'package:smartspace_admin/features/map/models/map_report_model.dart';
import 'package:smartspace_admin/features/map/services/map_service.dart';
import 'package:smartspace_admin/features/reports/models/report_filter_model.dart';
import 'package:smartspace_admin/ui/screen/map/widgets/map_cluster_sheet.dart';

/// Service giả: mỗi lần gọi trả về một Completer để test điều khiển thứ tự response.
class _FakeMapService extends MapService {
  final List<({String? status, MapBounds? bounds, String? timeframe})> calls = [];
  final List<Completer<ApiResponse<AdminMapReportsResult>>> pending = [];

  @override
  Future<ApiResponse<AdminMapReportsResult>> getMapReports({
    String? status,
    String? severity,
    String? assigneeId,
    DateTime? from,
    DateTime? to,
    String? timeframe,
    MapBounds? bounds,
    int limit = 500,
  }) {
    calls.add((status: status, bounds: bounds, timeframe: timeframe));
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    test('tải lần đầu: gọi service với bounding box mở rộng', () async {
      final notifier = container.read(mapReportsProvider.notifier);
      final future = notifier.loadForViewport(viewport);

      expect(service.calls, hasLength(1));
      final call = service.calls.single;
      expect(call.status, isNull);
      expect(call.bounds, isNotNull);
      expect(call.bounds!.contains(viewport), isTrue);

      service.pending.single.complete(_ok(['r1', 'r2']));
      await future;

      final state = container.read(mapReportsProvider);
      expect(state.reports.map((r) => r.id), ['r1', 'r2']);
      expect(state.isLoading, isFalse);
    });

    test('đổi filter: kích hoạt tải lại', () async {
      container.read(mapReportsProvider);
      final notifier = container.read(mapReportsProvider.notifier);

      final f1 = notifier.loadForViewport(viewport);
      service.pending[0].complete(_ok(['r1']));
      await f1;

      container.read(mapFilterProvider.notifier).state = const ReportFilter(status: 'pending');

      expect(service.calls, hasLength(2));
      expect(service.calls.last.status, 'pending');

      service.pending[1].complete(_ok(['r2']));
      await pumpEventQueue();

      expect(container.read(mapReportsProvider).reports.map((r) => r.id), ['r2']);
    });
  });
}
