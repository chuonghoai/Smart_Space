import 'package:flutter_test/flutter_test.dart';
import 'package:smartspace_admin/features/account_lock/models/account_lock_request_model.dart';

void main() {
  group('AccountLockRequestModel.fromJson', () {
    // Test Case ID: SMP-062
    // Description: Kiểm tra parse JSON đầy đủ cho AccountLockRequestModel gồm phiếu, bằng chứng và quyền thao tác.
    test('parse đầy đủ chi tiết: phiếu, bằng chứng, quyền thao tác', () {
      final model = AccountLockRequestModel.fromJson({
        'id': 'req-1',
        'status': 'pending',
        'target': {'id': 'u1', 'fullName': '', 'email': 'u1@example.com', 'status': 'active'},
        'proposer': {'id': 'a1', 'fullName': 'Admin A', 'email': 'a@example.com'},
        'reason': 'Spam liên tục',
        'approvals': 1,
        'rejections': 0,
        'requiredApprovals': 2,
        'requiredRejections': 2,
        'createdAt': '2026-11-15T10:00:00',
        'expiresAt': '2026-11-18T10:00:00',
        'myVote': 'approve',
        'mine': false,
        'canVote': false,
        'voteBlockedReason': 'already_voted',
        'canCancel': false,
        'evidences': [
          {'id': 'e1', 'type': 'image', 'imageUrl': 'https://x/a.jpg'},
          {'id': 'e2', 'type': 'report', 'reportId': 'r1', 'reportTitle': 'Báo sai', 'reportStatus': 'pending'},
        ],
        'votes': [
          {
            'voter': {'id': 'a2', 'fullName': 'Admin B', 'email': 'b@example.com'},
            'decision': 'approve',
            'comment': 'Đồng ý',
            'createdAt': '2026-11-15T11:00:00',
          },
        ],
      });

      expect(model.status, LockRequestStatus.pending);
      expect(model.target.displayName, 'u1@example.com', reason: 'không có tên → email');
      expect(model.myVoteApprove, isTrue);
      expect(model.voteBlockedReason, LockVoteBlockedReason.alreadyVoted);
      expect(model.awaitsMyVote, isFalse);
      expect(model.evidences.first.isImage, isTrue);
      expect(model.evidences.last.reportId, 'r1');
      expect(model.votes.single.approve, isTrue);
      expect(model.expiresAt, DateTime(2026, 11, 18, 10));
    });

    // Test Case ID: SMP-063
    // Description: Kiểm tra parse JSON tối giản thiếu bằng chứng/phiếu và status không xác định vẫn an toàn và fallback về pending.
    test('bản tóm tắt (danh sách) không có bằng chứng/phiếu và trạng thái lạ không làm crash', () {
      final model = AccountLockRequestModel.fromJson({
        'id': 'req-2',
        'status': 'something_new',
        'canVote': true,
      });

      expect(model.status, LockRequestStatus.pending);
      expect(model.evidences, isEmpty);
      expect(model.votes, isEmpty);
      expect(model.myVoteApprove, isNull);
      expect(model.voteBlockedReason, isNull);
      expect(model.awaitsMyVote, isTrue);
      expect(model.requiredApprovals, 2);
    });
  });

  // Test Case ID: SMP-064
  // Description: Kiểm tra thuộc tính LockRequestStatus.isResolved trả về false cho pending và true cho các trạng thái đã kết thúc.
  test('LockRequestStatus.isResolved', () {
    expect(LockRequestStatus.pending.isResolved, isFalse);
    for (final s in [
      LockRequestStatus.approved,
      LockRequestStatus.rejected,
      LockRequestStatus.cancelled,
      LockRequestStatus.expired,
    ]) {
      expect(s.isResolved, isTrue);
    }
  });
}
