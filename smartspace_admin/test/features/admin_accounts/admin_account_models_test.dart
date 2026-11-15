import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_admin/features/admin_accounts/application/admin_account_providers.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_list_response.dart';
import 'package:smartspace_admin/features/admin_accounts/models/admin_account_model.dart';

AdminAccountModel _admin(String id, {bool active = true, bool me = false}) =>
    AdminAccountModel(
      id: id,
      fullName: 'Admin $id',
      email: '$id@example.com',
      status: active ? 'active' : 'blocked',
      isCurrentUser: me,
    );

AdminAccountListState _state(List<AdminAccountModel> admins, {required int active}) =>
    AdminAccountListState(
      summary: AdminAccountSummary(
        total: admins.length,
        active: active,
        blocked: admins.length - active,
      ),
      admins: admins,
      currentPage: 1,
      totalPages: 1,
      totalElements: admins.length,
    );

void main() {
  group('AdminAccountListResponse.fromJson', () {
    test('parse summary, page và cờ currentUser từ backend', () {
      final res = AdminAccountListResponse.fromJson({
        'summary': {'total': 3, 'active': 2, 'blocked': 1},
        'admins': {
          'currentPage': 2,
          'pageSize': 10,
          'totalPages': 3,
          'totalElements': 25,
          'content': [
            {
              'id': 'a1',
              'fullName': 'Nguyễn Văn A',
              'email': 'a@example.com',
              'status': 'active',
              'createdAt': '2026-11-15T10:30:00',
              'currentUser': true,
            },
            {'id': 'a2', 'fullName': '', 'email': 'b@example.com', 'status': 'blocked'},
          ],
        },
      });

      expect(res.summary.total, 3);
      expect(res.summary.blocked, 1);
      expect(res.currentPage, 2);
      expect(res.totalPages, 3);
      expect(res.admins, hasLength(2));
      expect(res.admins.first.isCurrentUser, isTrue);
      expect(res.admins.first.isActive, isTrue);
      expect(res.admins.first.createdAt, DateTime(2026, 11, 15, 10, 30));
      expect(res.admins.last.isCurrentUser, isFalse);
      expect(res.admins.last.displayName, 'b@example.com', reason: 'không có tên → fallback email');
    });

    test('JSON thiếu trường không làm crash', () {
      final res = AdminAccountListResponse.fromJson({});

      expect(res.admins, isEmpty);
      expect(res.summary.total, 0);
      expect(res.currentPage, 1);
    });
  });

  group('AdminAccountListState.canToggle', () {
    test('không được tự khóa chính mình', () {
      final me = _admin('me', me: true);
      final state = _state([me, _admin('x')], active: 2);

      expect(state.canToggle(me), isFalse);
    });

    test('không được khóa admin hoạt động cuối cùng', () {
      final only = _admin('only');
      final state = _state([only, _admin('b', active: false)], active: 1);

      expect(state.canToggle(only), isFalse);
    });

    test('mở khóa luôn được phép kể cả khi chỉ còn 1 admin hoạt động', () {
      final blocked = _admin('b', active: false);
      final state = _state([_admin('me', me: true), blocked], active: 1);

      expect(state.canToggle(blocked), isTrue);
    });

    test('khóa admin khác khi còn nhiều admin hoạt động', () {
      final other = _admin('x');
      final state = _state([_admin('me', me: true), other], active: 2);

      expect(state.canToggle(other), isTrue);
    });
  });
}
