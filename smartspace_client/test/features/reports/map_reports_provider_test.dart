import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_client/features/reports/models/map_bounds.dart';
import 'package:smartspace_client/features/reports/models/map_reports_result.dart';
import 'package:smartspace_client/features/reports/models/report_model.dart';
import 'package:smartspace_client/features/reports/providers/map_reports_provider.dart';
import 'package:smartspace_client/features/reports/repositories/report_repo.dart';
import 'package:smartspace_client/features/reports/services/report_service.dart';

/// Repo giả: mỗi lần gọi trả về một Completer để test điều khiển thứ tự response.
class _FakeReportRepo implements ReportRepo {
  final List<MapBounds> requestedBounds = [];
  final List<Completer<ApiResponse<MapReportsResult>>> pending = [];

  @override
  Future<ApiResponse<MapReportsResult>> getReportsInBounds(MapBounds bounds, {int limit = 300}) {
    requestedBounds.add(bounds);
    final completer = Completer<ApiResponse<MapReportsResult>>();
    pending.add(completer);
    return completer.future;
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
      status: ReportStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );

ApiResponse<MapReportsResult> _ok(List<String> ids, {bool truncated = false}) => ApiResponse(
      success: true,
      message: 'ok',
      data: MapReportsResult(reports: ids.map(_report).toList(), truncated: truncated),
    );

void main() {
  const viewport = MapBounds(minLat: 10.7, maxLat: 10.9, minLng: 106.6, maxLng: 106.8);
  const insideViewport = MapBounds(minLat: 10.75, maxLat: 10.85, minLng: 106.65, maxLng: 106.75);

  late _FakeReportRepo repo;
  late DateTime now;
  late MapReportsNotifier notifier;

  setUp(() {
    repo = _FakeReportRepo();
    now = DateTime(2026, 1, 1, 12);
    notifier = MapReportsNotifier(ReportService(reportRepo: repo), now: () => now);
  });

  tearDown(() => notifier.dispose());

  test('tải khung rộng hơn màn hình theo prefetchFactor', () async {
    final future = notifier.loadForViewport(viewport);
    expect(notifier.state.isLoading, isTrue);
    expect(repo.requestedBounds.single, viewport.expandBy(MapReportsNotifier.prefetchFactor));

    repo.pending.single.complete(_ok(['a', 'b']));
    await future;

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.reports.map((r) => r.id), ['a', 'b']);
  });

  test('khung mới nằm trong vùng đã tải và còn mới → không gọi lại API', () async {
    final future = notifier.loadForViewport(viewport);
    repo.pending.single.complete(_ok(['a']));
    await future;

    await notifier.loadForViewport(insideViewport);
    expect(repo.requestedBounds, hasLength(1));
  });

  test('dữ liệu quá hạn freshness → gọi lại API', () async {
    final future = notifier.loadForViewport(viewport);
    repo.pending.single.complete(_ok(['a']));
    await future;

    now = now.add(MapReportsNotifier.freshness + const Duration(seconds: 1));
    unawaited(notifier.loadForViewport(insideViewport));
    expect(repo.requestedBounds, hasLength(2));
  });

  test('truncated: khung khác phải tải lại, nhưng cùng khung thì không lặp request', () async {
    final future = notifier.loadForViewport(viewport);
    repo.pending.single.complete(_ok(['a'], truncated: true));
    await future;

    // Map idle lặp lại với đúng khung cũ → không gọi lại (tránh vòng lặp vô hạn)
    await notifier.loadForViewport(viewport);
    expect(repo.requestedBounds, hasLength(1));

    // Zoom vào (khung khác) → còn report bị cắt bớt nên phải tải lại
    unawaited(notifier.loadForViewport(insideViewport));
    expect(repo.requestedBounds, hasLength(2));
  });

  test('response của request cũ về sau request mới thì bị bỏ', () async {
    final first = notifier.loadForViewport(viewport);
    final second = notifier.loadForViewport(insideViewport, force: true);

    repo.pending[1].complete(_ok(['new']));
    await second;
    repo.pending[0].complete(_ok(['stale']));
    await first;

    expect(notifier.state.reports.map((r) => r.id), ['new']);
  });

  test('lỗi: giữ dữ liệu cũ, lưu error, và cho phép thử lại cùng khung', () async {
    final first = notifier.loadForViewport(viewport);
    repo.pending.single.complete(_ok(['a']));
    await first;

    final second = notifier.loadForViewport(insideViewport, force: true);
    repo.pending[1].complete(ApiResponse(success: false, message: 'boom'));
    await second;

    expect(notifier.state.reports.map((r) => r.id), ['a']);
    expect(notifier.state.error, 'boom');
    expect(notifier.state.isLoading, isFalse);

    unawaited(notifier.loadForViewport(insideViewport));
    expect(repo.requestedBounds, hasLength(3));
  });

  test('refresh: tải lại khung gần nhất, bỏ qua cache', () async {
    final first = notifier.loadForViewport(viewport);
    repo.pending.single.complete(_ok(['a']));
    await first;

    unawaited(notifier.refresh());
    expect(repo.requestedBounds, hasLength(2));
  });

  test('bỏ report không có toạ độ (0,0)', () async {
    final future = notifier.loadForViewport(viewport);
    repo.pending.single.complete(ApiResponse(
      success: true,
      message: 'ok',
      data: MapReportsResult(
        reports: [_report('a'), _report('zero').copyWith(latitude: 0, longitude: 0)],
        truncated: false,
      ),
    ));
    await future;

    expect(notifier.state.reports.map((r) => r.id), ['a']);
  });
}
