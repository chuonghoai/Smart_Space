import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/core/theme/app_theme.dart';
import 'package:smartspace_admin/features/account_lock/application/account_lock_providers.dart';
import 'package:smartspace_admin/features/account_lock/models/account_lock_request_model.dart';
import 'package:smartspace_admin/l10n/app_localizations.dart';
import 'package:smartspace_admin/ui/screen/admin_board/lock_requests/lock_requests_tab.dart';

AccountLockRequestModel _req(String id, String name, {bool canVote = true}) {
  final created = DateTime.now().subtract(const Duration(hours: 2));
  return AccountLockRequestModel(
    id: id,
    status: LockRequestStatus.pending,
    target: LockPerson(id: 'u-$id', fullName: name, email: '$id@example.com'),
    proposer: const LockPerson(id: 'ad2', fullName: 'Trần Minh Bảo', email: 'b@example.com'),
    reason: 'Lý do',
    approvals: 0,
    rejections: 0,
    requiredApprovals: 2,
    requiredRejections: 2,
    createdAt: created,
    expiresAt: created.add(const Duration(hours: 72)),
    canVote: canVote,
  );
}

final _awaiting = [_req('1', 'Lê Văn Hùng')];
final _pending = [..._awaiting, _req('2', 'Võ Thành Nam', canVote: false)];

class _FakeList extends LockRequestListNotifier {
  @override
  Future<LockRequestListState> build(LockRequestFilter filter) async => LockRequestListState(
        items: switch (filter) {
          LockRequestFilter.awaitingMine => _awaiting,
          LockRequestFilter.pending => _pending,
          LockRequestFilter.resolved => const [],
        },
        currentPage: 1,
        totalPages: 1,
      );
}

Future<void> _pump(WidgetTester tester, AccountLockPendingCount count, {Size size = const Size(1200, 900)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lockRequestListProvider.overrideWith(_FakeList.new),
        lockPendingCountProvider.overrideWith((ref) async => count),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const Scaffold(body: LockRequestsTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final someAwaiting = AccountLockPendingCount(
    pending: 2,
    awaitingMyVote: 1,
    resolved: 14,
    nextDeadlineAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
  );

  // Test Case ID: SMP-107
  // Description: Kiểm tra dòng tóm tắt và 3 thẻ đếm trên tab Yêu cầu khóa tài khoản hiển thị đúng số liệu.
  testWidgets('Finding trả lời câu hỏi của màn và 3 thẻ đếm hiển thị đúng số', (tester) async {
    await _pump(tester, someAwaiting);

    expect(find.text('1 đề xuất cần bạn biểu quyết · gần nhất: còn 5 giờ'), findsOneWidget);
    expect(find.text('Cần bạn'), findsOneWidget);
    expect(find.text('Đang chờ'), findsOneWidget);
    expect(find.text('Đã kết thúc'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  // Test Case ID: SMP-108
  // Description: Kiểm tra bộ lọc mặc định "Cần bạn" và chuyển sang danh sách "Đang chờ" khi nhấn thẻ tương ứng.
  testWidgets('Mặc định lọc "Cần bạn"; bấm thẻ "Đang chờ" → danh sách đổi theo', (tester) async {
    await _pump(tester, someAwaiting);

    expect(find.text('Lê Văn Hùng'), findsOneWidget);
    expect(find.text('Võ Thành Nam'), findsNothing);

    await tester.tap(find.text('Đang chờ'));
    await tester.pumpAndSettle();

    expect(find.text('Võ Thành Nam'), findsOneWidget);
  });

  // Test Case ID: SMP-109
  // Description: Kiểm tra tự động chuyển sang bộ lọc "Đang chờ" khi awaitingMyVote = 0 nhưng vẫn còn đề xuất đang chờ.
  testWidgets('Không có gì cần bạn nhưng còn đề xuất chờ → tự chuyển sang "Đang chờ"', (tester) async {
    await _pump(tester, const AccountLockPendingCount(pending: 2, awaitingMyVote: 0, resolved: 3));

    expect(find.text('Không có đề xuất nào cần bạn biểu quyết · 2 đề xuất đang chờ các quản trị viên khác'),
        findsOneWidget);
    expect(find.text('Võ Thành Nam'), findsOneWidget);
  });

  // Test Case ID: SMP-110
  // Description: Kiểm tra hiển thị thông báo trạng thái trống khi chọn bộ lọc "Đã kết thúc" không có dữ liệu.
  testWidgets('Bộ lọc trống → giữ khung và một câu', (tester) async {
    await _pump(tester, someAwaiting);

    await tester.tap(find.text('Đã kết thúc'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có đề xuất nào kết thúc'), findsOneWidget);
  });

  // Test Case ID: SMP-111
  // Description: Kiểm tra trên màn hình điện thoại (390x844), 3 thẻ đếm chuyển thành ChoiceChip kèm số và không lỗi layout.
  testWidgets('Điện thoại: thẻ đếm thành chip có số, không tràn', (tester) async {
    await _pump(tester, someAwaiting, size: const Size(390, 844));

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Cần bạn 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
