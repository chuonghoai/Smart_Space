import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/account_lock/models/account_lock_request_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_request_widgets.dart';

const _id = 'req-1';

AccountLockRequestModel _request({
  LockRequestStatus status = LockRequestStatus.pending,
  bool canVote = false,
  LockVoteBlockedReason? blocked,
  bool canCancel = false,
  DateTime? resolvedAt,
}) {
  final created = DateTime.now().subtract(const Duration(hours: 2));
  return AccountLockRequestModel(
    id: _id,
    status: status,
    target: const LockPerson(id: 'u1', fullName: 'Nguyễn Văn A', email: 'a@example.com'),
    proposer: const LockPerson(id: 'ad1', fullName: 'Admin Một', email: 'ad1@example.com'),
    reason: 'Đăng nhiều phản ánh sai sự thật và spam liên tục.',
    approvals: 1,
    rejections: 0,
    requiredApprovals: 2,
    requiredRejections: 2,
    createdAt: created,
    expiresAt: created.add(const Duration(hours: 72)),
    resolvedAt: resolvedAt,
    canVote: canVote,
    voteBlockedReason: blocked,
    canCancel: canCancel,
    evidences: const [
      LockEvidence(id: 'e1', isImage: false, reportId: 'r1', reportTitle: 'Báo cáo giả', reportStatus: 'rejected'),
    ],
    votes: [
      LockVote(
        voter: const LockPerson(id: 'ad2', fullName: 'Admin Hai', email: 'ad2@example.com'),
        approve: true,
        comment: 'Bằng chứng rõ ràng',
        createdAt: created.add(const Duration(minutes: 30)),
      ),
    ],
  );
}

/// Thay thao tác ghi bằng kết quả cố định (không gọi API).
class _FakeActions extends AccountLockActions {
  final String? voteError;
  int voteCalls = 0;

  _FakeActions(super.ref, {this.voteError});

  @override
  Future<String?> vote(AccountLockRequestModel request, {required bool approve, String? comment}) async {
    voteCalls++;
    return voteError;
  }
}

Future<_FakeActions> _pump(
  WidgetTester tester,
  AccountLockRequestModel request, {
  ThemeData? theme,
  String? voteError,
}) async {
  late _FakeActions actions;
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lockRequestDetailProvider(_id).overrideWith((ref) async => request),
        accountLockActionsProvider.overrideWith((ref) => actions = _FakeActions(ref, voteError: voteError)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const Scaffold(
          body: SingleChildScrollView(child: LockRequestDetailPanel(requestId: _id)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Khởi tạo provider (lazy) để test có thể đọc số lần gọi
  ProviderScope.containerOf(tester.element(find.byType(LockRequestDetailPanel))).read(accountLockActionsProvider);
  return actions;
}

void main() {
  testWidgets('Hiển thị đối tượng, phiếu bầu (ghế + số), lý do, bằng chứng và phiếu đã bỏ', (tester) async {
    await _pump(tester, _request(canVote: true));

    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Phiếu bầu'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget, reason: 'bảo lãnh 1/2');
    expect(find.text('0/2'), findsOneWidget, reason: 'từ chối 0/2');
    expect(find.textContaining('còn '), findsOneWidget, reason: 'đồng hồ biểu quyết');
    expect(find.text('Đăng nhiều phản ánh sai sự thật và spam liên tục.'), findsOneWidget);
    expect(find.text('Bằng chứng · 0 ảnh · 1 phản ánh'), findsOneWidget);
    expect(find.text('Báo cáo giả'), findsOneWidget);
    expect(find.text('“Bằng chứng rõ ràng”'), findsOneWidget);
  });

  testWidgets('Được bỏ phiếu → nút Bảo lãnh và Từ chối nằm ngay trong phiếu bầu', (tester) async {
    await _pump(tester, _request(canVote: true));

    expect(find.widgetWithText(FilledButton, 'Bảo lãnh'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Từ chối'), findsOneWidget);
    expect(find.byTooltip('Thao tác khác'), findsNothing, reason: 'không phải người đề xuất');
  });

  testWidgets('Người đề xuất → lý do không bỏ phiếu, Huỷ đề xuất nằm trong menu ⋮', (tester) async {
    await _pump(tester, _request(blocked: LockVoteBlockedReason.proposer, canCancel: true));

    expect(find.widgetWithText(FilledButton, 'Bảo lãnh'), findsNothing);
    expect(find.text('Bạn là người đề xuất nên không thể bỏ phiếu'), findsOneWidget);

    await tester.tap(find.byTooltip('Thao tác khác'));
    await tester.pumpAndSettle();
    expect(find.text('Huỷ đề xuất'), findsOneWidget);
  });

  testWidgets('Đã thông qua → kết quả bằng chữ thay cho đồng hồ, không có nút thao tác', (tester) async {
    await _pump(tester, _request(
      status: LockRequestStatus.approved,
      blocked: LockVoteBlockedReason.closed,
      resolvedAt: DateTime(2026, 11, 16, 9, 30),
    ));

    expect(find.text('Tài khoản đã bị khoá lúc 09:30 - 16/11/2026'), findsOneWidget);
    expect(find.text('Đề xuất đã kết thúc biểu quyết'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Bảo lãnh'), findsNothing);
  });

  testWidgets('Bỏ phiếu lỗi → lỗi hiện NGAY TRONG dialog, dialog vẫn mở', (tester) async {
    final actions = await _pump(tester, _request(canVote: true), voteError: 'Bạn đã bỏ phiếu cho đề xuất này');

    await tester.tap(find.widgetWithText(FilledButton, 'Bảo lãnh'));
    await tester.pumpAndSettle();
    expect(find.text('Bảo lãnh đề xuất khoá?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget, reason: 'ô nhận xét');

    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Bảo lãnh')));
    await tester.pumpAndSettle();

    expect(actions.voteCalls, 1);
    expect(find.text('Bảo lãnh đề xuất khoá?'), findsOneWidget, reason: 'dialog chưa đóng');
    expect(find.text('Bạn đã bỏ phiếu cho đề xuất này'), findsOneWidget);
  });

  testWidgets('Bỏ phiếu thành công → dialog đóng', (tester) async {
    final actions = await _pump(tester, _request(canVote: true));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Từ chối'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Từ chối')));
    await tester.pumpAndSettle();

    expect(actions.voteCalls, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Render được ở Dark mode', (tester) async {
    await _pump(tester, _request(canVote: true), theme: AppTheme.darkTheme);

    expect(find.text('Phiếu bầu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
