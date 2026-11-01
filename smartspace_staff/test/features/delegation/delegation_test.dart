import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/api/api_response.dart';
import 'package:smartspace_staff/features/delegation/models/delegation_model.dart';
import 'package:smartspace_staff/features/delegation/providers/delegation_providers.dart';
import 'package:smartspace_staff/features/delegation/repositories/delegation_repo.dart';
import 'package:smartspace_staff/features/delegation/services/delegation_service.dart';
import 'package:smartspace_staff/features/reports/models/report_model.dart';
import 'package:smartspace_staff/features/wallet/models/staff_wallet_transaction_model.dart';

Map<String, dynamic> _delegationJson(String id, {String status = 'PENDING'}) => {
      'id': id,
      'status': status,
      'report_id': 'r-$id',
      'report_title': 'Report $id',
      'severity': 'low',
      'requester': {'id': 'u5', 'full_name': 'Requester'},
      'helper': {'id': 'u6', 'full_name': 'Helper', 'position_name': 'Kỹ thuật'},
      'rate_percent': 50,
      'commission_amount': 20000,
      'bonus_amount': 10000,
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
    test('DelegationModel.fromJson: trạng thái, mức độ, người nhờ/được nhờ, tổng tiền người làm giùm', () {
      final d = DelegationModel.fromJson(_delegationJson('1', status: 'ACCEPTED'));
      expect(d.status, DelegationStatus.accepted);
      expect(d.status.isActive, isTrue);
      expect(d.severity, ReportSeverity.low);
      expect(d.requester.fullName, 'Requester');
      expect(d.helper.positionName, 'Kỹ thuật');
      expect(d.helperTotal, 30000);
      expect(d.isRequester('u5'), isTrue);
      expect(d.isHelper('u5'), isFalse);
      expect(d.expiresAt, isNotNull);
    });

    test('Trạng thái lạ → unknown, không crash', () {
      expect(DelegationStatus.parse('SOMETHING_NEW'), DelegationStatus.unknown);
      expect(DelegationStatus.parse(null), DelegationStatus.unknown);
      expect(DelegationStatus.completed.isActive, isFalse);
    });

    test('DelegationReportStateModel: thiếu tiền và yêu cầu đang hoạt động', () {
      final state = DelegationReportStateModel.fromJson({
        'can_request': false,
        'reason_code': 'delegation.insufficient_balance',
        'commission_amount': 20000,
        'rate_percent': 50,
        'bonus_amount': 10000,
        'balance': 3000,
        'active_delegation': null,
      });
      expect(state.canRequest, isFalse);
      expect(state.isInsufficientBalance, isTrue);
      expect(state.activeDelegation, isNull);

      final withActive = DelegationReportStateModel.fromJson({
        'can_request': false,
        'reason_code': 'delegation.already_active',
        'active_delegation': _delegationJson('2'),
      });
      expect(withActive.isInsufficientBalance, isFalse);
      expect(withActive.activeDelegation?.id, '2');
    });

    test('Khung hoa hồng theo người đang xem: người làm giùm cộng bonus, người nhờ ẩn hoa hồng', () {
      DelegationReportStateModel state(String role, {Map<String, dynamic>? active, Map<String, dynamic>? completed}) =>
          DelegationReportStateModel.fromJson({
            'can_request': false,
            'viewer_role': role,
            'active_delegation': active,
            'completed_delegation': completed,
          });

      // Đang làm giùm: người làm giùm thấy bonus sắp nhận; người nhờ không còn thấy hoa hồng của task
      final helperDoing = state('HELPER', active: _delegationJson('1', status: 'ACCEPTED'));
      expect(helperDoing.viewerRole, DelegationViewerRole.helper);
      expect(helperDoing.upcomingBonusForViewer, 10000);
      expect(helperDoing.hidesViewerCommission, isFalse);
      expect(state('REQUESTER', active: _delegationJson('1', status: 'ACCEPTED')).hidesViewerCommission, isTrue);

      // Đang chờ trả lời: người nhờ vẫn là người được giao → vẫn thấy hoa hồng của mình
      final requesterWaiting = state('REQUESTER', active: _delegationJson('1'));
      expect(requesterWaiting.hidesViewerCommission, isFalse);
      expect(requesterWaiting.upcomingBonusForViewer, isNull);

      // Đã hoàn tất: người làm giùm thấy bonus đã nhận, người nhờ thấy bonus đã trả
      final helperDone = state('HELPER', completed: _delegationJson('2', status: 'COMPLETED'));
      expect(helperDone.bonusReceivedByViewer?.bonusAmount, 10000);
      expect(helperDone.bonusPaidByViewer, isNull);
      expect(helperDone.upcomingBonusForViewer, isNull);
      final requesterDone = state('REQUESTER', completed: _delegationJson('2', status: 'COMPLETED'));
      expect(requesterDone.bonusPaidByViewer?.helper.fullName, 'Helper');
      expect(requesterDone.hidesViewerCommission, isTrue);

      // Không tham gia → giữ nguyên khung hoa hồng cũ
      final outsider = DelegationReportStateModel.fromJson({'can_request': false});
      expect(outsider.viewerRole, isNull);
      expect(outsider.hidesViewerCommission, isFalse);
      expect(outsider.upcomingBonusForViewer, isNull);
      expect(outsider.bonusReceivedByViewer, isNull);
    });

    test('DelegationPage đọc PageResponse (camelCase) và hasMore', () {
      final page = DelegationPage.fromJson(
        {'currentPage': 0, 'totalPages': 2, 'content': [_delegationJson('1')]},
        DelegationModel.fromJson,
      );
      expect(page.items.single.id, '1');
      expect(page.hasMore, isTrue);
      expect(DelegationPage.fromJson(null, DelegationModel.fromJson).items, isEmpty);
    });

    test('Giao dịch ví nhờ làm giùm hiển thị đúng chiều tiền', () {
      StaffWalletTransactionModel tx(String type) => StaffWalletTransactionModel(
            id: type, type: type, amount: 1, balanceAfter: 1, title: type, createdAt: DateTime(2026));
      expect(tx('DELEGATION_BONUS').isIncome, isTrue);
      expect(tx('DELEGATION_HOLD').isHold, isTrue);
      expect(tx('DELEGATION_REFUND').isRefund, isTrue);
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

    test('Danh sách lỗi → giữ trạng thái rỗng kèm error để hiện nút thử lại', () async {
      final sub = container.listen(delegationListProvider(DelegationBox.received), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      repo.pendingLists.last.complete(ApiResponse(success: false, message: 'boom'));
      await Future<void>.delayed(Duration.zero);
      expect(sub.read().items, isEmpty);
      expect(sub.read().error, 'boom');
      expect(sub.read().isLoading, isFalse);
    });

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
