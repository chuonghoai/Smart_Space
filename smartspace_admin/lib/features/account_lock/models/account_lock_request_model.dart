/// Đề xuất khóa tài khoản người dùng (biểu quyết của Hội đồng quản trị).
enum LockRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
  expired;

  static LockRequestStatus parse(String? raw) => LockRequestStatus.values
      .firstWhere((s) => s.name == raw, orElse: () => LockRequestStatus.pending);

  bool get isResolved => this != LockRequestStatus.pending;
}

/// Lý do không được bỏ phiếu (do backend tính).
enum LockVoteBlockedReason { proposer, alreadyVoted, closed }

class LockPerson {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? status;

  const LockPerson({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.status,
  });

  factory LockPerson.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return LockPerson(
      id: j['id'] as String? ?? '',
      fullName: j['fullName'] as String? ?? '',
      email: j['email'] as String? ?? '',
      avatarUrl: j['avatarUrl'] as String?,
      status: j['status'] as String?,
    );
  }

  String get displayName => fullName.trim().isNotEmpty ? fullName.trim() : email;
}

class LockEvidence {
  final String id;
  final bool isImage;
  final String? imageUrl;
  final String? reportId;
  final String? reportTitle;
  final String? reportStatus;
  final DateTime? reportCreatedAt;

  const LockEvidence({
    required this.id,
    required this.isImage,
    this.imageUrl,
    this.reportId,
    this.reportTitle,
    this.reportStatus,
    this.reportCreatedAt,
  });

  factory LockEvidence.fromJson(Map<String, dynamic> json) {
    return LockEvidence(
      id: json['id'] as String? ?? '',
      isImage: json['type'] == 'image',
      imageUrl: json['imageUrl'] as String?,
      reportId: json['reportId'] as String?,
      reportTitle: json['reportTitle'] as String?,
      reportStatus: json['reportStatus'] as String?,
      reportCreatedAt: DateTime.tryParse(json['reportCreatedAt']?.toString() ?? ''),
    );
  }
}

class LockVote {
  final LockPerson voter;
  final bool approve;
  final String? comment;
  final DateTime? createdAt;

  const LockVote({
    required this.voter,
    required this.approve,
    this.comment,
    this.createdAt,
  });

  factory LockVote.fromJson(Map<String, dynamic> json) {
    return LockVote(
      voter: LockPerson.fromJson(json['voter'] as Map<String, dynamic>?),
      approve: json['decision'] == 'approve',
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class AccountLockRequestModel {
  final String id;
  final LockRequestStatus status;
  final LockPerson target;
  final LockPerson proposer;
  final String reason;
  final int approvals;
  final int rejections;
  final int requiredApprovals;
  final int requiredRejections;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? resolvedAt;

  /// Phiếu của admin đang xem: true = bảo lãnh, false = từ chối, null = chưa bỏ phiếu.
  final bool? myVoteApprove;
  final bool isMine;
  final bool canVote;
  final LockVoteBlockedReason? voteBlockedReason;
  final bool canCancel;

  /// Chỉ có ở API chi tiết (danh sách trả về rỗng).
  final List<LockEvidence> evidences;
  final List<LockVote> votes;

  const AccountLockRequestModel({
    required this.id,
    required this.status,
    required this.target,
    required this.proposer,
    required this.reason,
    required this.approvals,
    required this.rejections,
    required this.requiredApprovals,
    required this.requiredRejections,
    this.createdAt,
    this.expiresAt,
    this.resolvedAt,
    this.myVoteApprove,
    this.isMine = false,
    this.canVote = false,
    this.voteBlockedReason,
    this.canCancel = false,
    this.evidences = const [],
    this.votes = const [],
  });

  factory AccountLockRequestModel.fromJson(Map<String, dynamic> json) {
    final myVote = json['myVote'] as String?;
    return AccountLockRequestModel(
      id: json['id'] as String? ?? '',
      status: LockRequestStatus.parse(json['status'] as String?),
      target: LockPerson.fromJson(json['target'] as Map<String, dynamic>?),
      proposer: LockPerson.fromJson(json['proposer'] as Map<String, dynamic>?),
      reason: json['reason'] as String? ?? '',
      approvals: (json['approvals'] as num?)?.toInt() ?? 0,
      rejections: (json['rejections'] as num?)?.toInt() ?? 0,
      requiredApprovals: (json['requiredApprovals'] as num?)?.toInt() ?? 2,
      requiredRejections: (json['requiredRejections'] as num?)?.toInt() ?? 2,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(json['resolvedAt']?.toString() ?? ''),
      myVoteApprove: myVote == null ? null : myVote == 'approve',
      isMine: json['mine'] as bool? ?? false,
      canVote: json['canVote'] as bool? ?? false,
      voteBlockedReason: switch (json['voteBlockedReason']) {
        'proposer' => LockVoteBlockedReason.proposer,
        'already_voted' => LockVoteBlockedReason.alreadyVoted,
        'closed' => LockVoteBlockedReason.closed,
        _ => null,
      },
      canCancel: json['canCancel'] as bool? ?? false,
      evidences: (json['evidences'] as List<dynamic>? ?? const [])
          .map((e) => LockEvidence.fromJson(e as Map<String, dynamic>))
          .toList(),
      votes: (json['votes'] as List<dynamic>? ?? const [])
          .map((e) => LockVote.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Còn chờ và cần admin đang xem bỏ phiếu.
  bool get awaitsMyVote => status == LockRequestStatus.pending && canVote;
}

class AccountLockRequestPage {
  final List<AccountLockRequestModel> items;
  final int currentPage;
  final int totalPages;
  final int totalElements;

  const AccountLockRequestPage({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
  });

  factory AccountLockRequestPage.fromJson(Map<String, dynamic> json) {
    return AccountLockRequestPage(
      items: (json['content'] as List<dynamic>? ?? const [])
          .map((e) => AccountLockRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccountLockPendingCount {
  final int pending;
  final int awaitingMyVote;
  final int resolved;

  /// Hạn gần nhất trong các đề xuất admin đang xem còn phải bỏ phiếu.
  final DateTime? nextDeadlineAt;

  const AccountLockPendingCount({
    required this.pending,
    required this.awaitingMyVote,
    this.resolved = 0,
    this.nextDeadlineAt,
  });

  factory AccountLockPendingCount.fromJson(Map<String, dynamic> json) {
    return AccountLockPendingCount(
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      awaitingMyVote: (json['awaitingMyVote'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      nextDeadlineAt: DateTime.tryParse(json['nextDeadlineAt']?.toString() ?? ''),
    );
  }
}
