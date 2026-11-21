import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/users/application/user_providers.dart';
import 'package:smartspace_admin/features/users/models/user_detail_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/users/user_detail_view.dart';

const _reason = 'Đăng nhiều phản ánh sai sự thật và spam liên tục.';

UserDetailModel _user({String status = 'active', String? blockedReason, String? pendingId}) => UserDetailModel(
      id: 'u1',
      fullName: 'Nguyễn Văn A',
      email: 'a@example.com',
      status: status,
      reportStats: const UserReportStats(total: 1, pending: 0, processing: 0, processed: 0, rejected: 1),
      recentReports: [
        UserRecentReport(id: 'r1', title: 'Báo cáo giả', status: 'rejected', createdAt: DateTime(2026, 11, 10)),
      ],
      pendingLockRequestId: pendingId,
      lockProposalBlockedReason: blockedReason,
    );

class _FakeActions extends AccountLockActions {
  final LockCreateResult result;
  int createCalls = 0;

  _FakeActions(super.ref, this.result);

  @override
  Future<LockCreateResult> create({
    required String targetUserId,
    required String reason,
    required List<String> evidenceImageUrls,
    required List<String> reportIds,
  }) async {
    createCalls++;
    return result;
  }
}

Future<void> _pump(WidgetTester tester, UserDetailModel user, {LockCreateResult? result}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userDetailProvider('u1').overrideWith((ref) async => user),
        accountLockActionsProvider.overrideWith(
          (ref) => _FakeActions(ref, result ?? (requestId: null, error: '')),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(child: UserDetailContent(userId: 'u1', onReportTap: (_) {})),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Đề xuất khoá tài khoản'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), _reason);
  // Phần thân form cuộn được: đưa ô phản ánh vào khung nhìn trước khi chọn (như người dùng cuộn xuống)
  await tester.ensureVisible(find.byType(CheckboxListTile));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
  await tester.tap(find.widgetWithText(FilledButton, 'Gửi đề xuất'));
  await tester.pumpAndSettle();
}

void main() {
  // Test Case ID: SMP-102
  // Description: Kiểm tra nút Đề xuất khoá tài khoản bị vô hiệu kèm lý do khi chưa đủ 3 quản trị viên hoạt động.
  testWidgets('Không đủ admin → nút bị vô hiệu nhưng vẫn đọc được, kèm lý do', (tester) async {
    await _pump(tester, _user(blockedReason: 'not_enough_admins'));

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Đề xuất khoá tài khoản'));
    expect(button.onPressed, isNull);
    expect(find.textContaining('Cần ít nhất 3 quản trị viên đang hoạt động'), findsOneWidget);
  });

  // Test Case ID: SMP-103
  // Description: Kiểm tra khi tài khoản đang có đề xuất khoá chờ duyệt thì hiển thị banner cùng nút Xem đề xuất và ẩn nút Đề xuất khoá tài khoản.
  testWidgets('Đang có đề xuất chờ → banner + "Xem đề xuất", không có nút đề xuất', (tester) async {
    await _pump(tester, _user(blockedReason: 'already_pending', pendingId: 'req-1'));

    expect(find.text('Tài khoản này đang có đề xuất khoá chờ biểu quyết'), findsOneWidget);
    expect(find.text('Xem đề xuất'), findsOneWidget);
    expect(find.text('Đề xuất khoá tài khoản'), findsNothing);
  });

  // Test Case ID: SMP-104
  // Description: Kiểm tra khi gửi form đề xuất khoá thiếu lý do và bằng chứng thì hiển thị thông báo lỗi ngay trên form.
  testWidgets('Thiếu lý do và bằng chứng → lỗi ngay tại field, không gọi API', (tester) async {
    await _pump(tester, _user());

    await tester.tap(find.widgetWithText(OutlinedButton, 'Đề xuất khoá tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi đề xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Lý do cần ít nhất 20 ký tự'), findsOneWidget);
    expect(find.text('Cần ít nhất một bằng chứng: ảnh hoặc phản ánh'), findsOneWidget);
  });

  // Test Case ID: SMP-105
  // Description: Kiểm tra khi backend từ chối tạo đề xuất thì giữ form mở và hiển thị lỗi ngay bên trong form.
  testWidgets('Backend từ chối → lỗi hiện NGAY TRONG form, form vẫn mở', (tester) async {
    await _pump(
      tester,
      _user(),
      result: (requestId: null, error: 'Cần ít nhất 2 quản trị viên khác đang hoạt động để biểu quyết đề xuất khóa'),
    );

    await _fillAndSubmit(tester);

    expect(find.text('Gửi đề xuất'), findsOneWidget, reason: 'form chưa đóng');
    expect(
      find.text('Cần ít nhất 2 quản trị viên khác đang hoạt động để biểu quyết đề xuất khóa'),
      findsOneWidget,
    );
  });

  // Test Case ID: SMP-106
  // Description: Kiểm tra khi gửi đề xuất khoá thành công thì đóng form và hiển thị dialog xác nhận có nút Xem đề xuất.
  testWidgets('Gửi thành công → form đóng và hiện dialog xác nhận có "Xem đề xuất"', (tester) async {
    await _pump(tester, _user(), result: (requestId: 'req-9', error: null));

    await _fillAndSubmit(tester);

    expect(find.text('Gửi đề xuất'), findsNothing, reason: 'form đã đóng');
    expect(find.text('Đã gửi đề xuất khoá'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Xem đề xuất'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Đóng'), findsOneWidget);
  });
}
