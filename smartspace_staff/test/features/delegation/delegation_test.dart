import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/features/delegation/repositories/delegation_repo.dart';
import 'package:smartspace_staff/features/delegation/services/delegation_service.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';

Map<String, dynamic> _delegationJson(String id, {String status = 'PENDING'}) => {
      'id': id,
      'status': status,
      'report_id': 'r-$id',
      'report_title': 'Report $id',
      'severity': 'low',
      'requester': {'id': 'u5', 'full_name': 'Requester'},
      'helper': {'id': 'u6', 'full_name': 'Helper', 'position_name': 'Kỹ thuật'},
      'expires_at': '2026-11-01T10:00:00',
    };

ApiResponse<DelegationPage<T>> _page<T>(List<T> items, {int page = 0, int totalPages = 1}) => ApiResponse(
      success: true,
      message: 'ok',
      data: DelegationPage(items: items, page: page, totalPages: totalPages),
    );

/// Repo giả: ghi lại tham số, trả response theo hàng đợi Completer để test điều khiển thứ tự.
class _FakeRepo implements DelegationRepo {
  final List<({DelegationBox box, int page})> listCalls = [];
  final List<({String? query, int page})> colleagueCalls = [];
  final List<Completer<ApiResponse<DelegationPage<DelegationModel>>>> pendingLists = [];
  final List<Completer<ApiResponse<DelegationPage<ColleagueModel>>>> pendingColleagues = [];

  @override
  Future<ApiResponse<DelegationPage<DelegationModel>>> list(DelegationBox box, {int page = 0, int size = 20}) {
    listCalls.add((box: box, page: page));
    final completer = Completer<ApiResponse<DelegationPage<DelegationModel>>>();
    pendingLists.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<DelegationPage<ColleagueModel>>> searchColleagues({String? query, int page = 0, int size = 20}) {
    colleagueCalls.add((query: query, page: page));
    final completer = Completer<ApiResponse<DelegationPage<ColleagueModel>>>();
    pendingColleagues.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Model', () {
    // Test Case ID: SMP-141
    // Description: Kiểm tra parse JSON sang DelegationModel với trạng thái, mức độ và thông tin người nhờ/được nhờ.
    test('DelegationModel.fromJson: trạng thái, mức độ, người nhờ/được nhờ', () {
      final d = DelegationModel.fromJson(_delegationJson('1', status: 'ACCEPTED'));
      expect(d.status, DelegationStatus.accepted);
      expect(d.status.isActive, isTrue);
      expect(d.severity, ReportSeverity.low);
      expect(d.requester.fullName, 'Requester');
      expect(d.helper.positionName, 'Kỹ thuật');
      expect(d.isRequester('u5'), isTrue);
      expect(d.isHelper('u5'), isFalse);
      expect(d.expiresAt, isNotNull);
    });

    // Test Case ID: SMP-142
    // Description: Kiểm tra DelegationStatus.parse trả về unknown khi gặp giá trị lạ hoặc null và isActive của completed là false.
    test('Trạng thái lạ → unknown, không crash', () {
      expect(DelegationStatus.parse('SOMETHING_NEW'), DelegationStatus.unknown);
      expect(DelegationStatus.parse(null), DelegationStatus.unknown);
      expect(DelegationStatus.completed.isActive, isFalse);
    });

    // Test Case ID: SMP-143
    // Description: Kiểm tra DelegationReportStateModel.fromJson đọc đúng canRequest, viewerRole và activeDelegation.
    test('DelegationReportStateModel: yêu cầu đang hoạt động và viewerRole', () {
      final withActive = DelegationReportStateModel.fromJson({
        'can_request': false,
        'reason_code': 'delegation.already_active',
        'viewer_role': 'HELPER',
        'active_delegation': _delegationJson('2'),
      });
      expect(withActive.canRequest, isFalse);
      expect(withActive.viewerRole, DelegationViewerRole.helper);
      expect(withActive.activeDelegation?.id, '2');
    });

    // Test Case ID: SMP-144
    // Description: Kiểm tra DelegationPage.fromJson đọc PageResponse dạng camelCase, tính hasMore và xử lý đầu vào null.
    test('DelegationPage đọc PageResponse (camelCase) và hasMore', () {
      final page = DelegationPage.fromJson(
        {'currentPage': 0, 'totalPages': 2, 'content': [_delegationJson('1')]},
        DelegationModel.fromJson,
      );
      expect(page.items.single.id, '1');
      expect(page.hasMore, isTrue);
      expect(DelegationPage.fromJson(null, DelegationModel.fromJson).items, isEmpty);
    });
  });

  group('Providers', () {
    late _FakeRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeRepo();
      container = ProviderContainer(overrides: [
        delegationServiceProvider.overrideWithValue(DelegationService(repo)),
      ]);
    });

    tearDown(() => container.dispose());

    // Test Case ID: SMP-145
    // Description: Kiểm tra delegationListProvider tải trang 0 theo box và nối thêm trang kế khi gọi loadMore.
    test('Danh sách: tải trang đầu theo hộp, cuộn thì nối trang kế', () async {
      final sub = container.listen(delegationListProvider(DelegationBox.sent), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(repo.listCalls.single, (box: DelegationBox.sent, page: 0));

      repo.pendingLists.last.complete(_page([DelegationModel.fromJson(_delegationJson('1'))], totalPages: 2));
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().items.map((d) => d.id), ['1']);
      expect(sub.read().hasMore, isTrue);

      final more = container.read(delegationListProvider(DelegationBox.sent).notifier).loadMore();
      repo.pendingLists.last.complete(_page([DelegationModel.fromJson(_delegationJson('2'))], page: 1, totalPages: 2));
      await more;
      expect(sub.read().items.map((d) => d.id), ['1', '2']);
      expect(sub.read().hasMore, isFalse);
    });

    // Test Case ID: SMP-146
    // Description: Kiểm tra delegationListProvider giữ items rỗng, tắt isLoading và lưu message lỗi khi API thất bại.
    test('Danh sách lỗi → giữ trạng thái rỗng kèm error để hiện nút thử lại', () async {
      final sub = container.listen(delegationListProvider(DelegationBox.received), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      repo.pendingLists.last.complete(ApiResponse(success: false, message: 'boom'));
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().items, isEmpty);
      expect(sub.read().error, 'boom');
      expect(sub.read().isLoading, isFalse);
    });

    // Test Case ID: SMP-147
    // Description: Kiểm tra colleagueSearchProvider debounce thao tác gõ liên tục và bỏ qua response cũ về sau.
    test('Tìm đồng nghiệp: debounce, và response của từ khoá cũ về sau bị bỏ', () async {
      final sub = container.listen(colleagueSearchProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      expect(repo.colleagueCalls.single.query, '');

      final notifier = container.read(colleagueSearchProvider.notifier);
      notifier.search('a');
      notifier.search('an');
      await Future<void>.delayed(ColleagueSearchNotifier.debounce + const Duration(milliseconds: 50));
      expect(repo.colleagueCalls.map((c) => c.query), ['', 'an'], reason: 'Gõ liên tục chỉ gọi API một lần');

      repo.pendingColleagues.last.complete(_page([const ColleagueModel(id: 'u7', fullName: 'An')]));
      repo.pendingColleagues.first.complete(_page([const ColleagueModel(id: 'u8', fullName: 'Stale')]));
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().items.map((c) => c.id), ['u7']);
    });
  });
}
