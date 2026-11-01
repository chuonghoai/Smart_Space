import 'package:smartspace_staff/features/reports/models/report_model.dart';

/// Vòng đời yêu cầu nhờ làm giùm — khớp `EDelegationStatus` của backend.
enum DelegationStatus {
  pending,
  accepted,
  declined,
  cancelled,
  expired,
  completed,
  revoked,
  unknown;

  static DelegationStatus parse(String? raw) => DelegationStatus.values.firstWhere(
        (s) => s.name == raw?.toLowerCase(),
        orElse: () => DelegationStatus.unknown,
      );

  /// Đang chiếm task (chặn nhờ thêm).
  bool get isActive => this == pending || this == accepted;
}

/// Vai trò của staff đang xem trong yêu cầu nhờ làm giùm của report (backend tính từ JWT).
enum DelegationViewerRole {
  requester,
  helper;

  static DelegationViewerRole? parse(String? raw) => switch (raw?.toUpperCase()) {
        'REQUESTER' => requester,
        'HELPER' => helper,
        _ => null,
      };
}

/// Hộp danh sách: yêu cầu mình nhận được (được nhờ) hoặc mình đã gửi (đi nhờ).
enum DelegationBox { received, sent }

/// Đồng nghiệp (chỉ thông tin hiển thị).
class ColleagueModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? positionName;

  const ColleagueModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.positionName,
  });

  factory ColleagueModel.fromJson(Map<String, dynamic> json) => ColleagueModel(
        id: json['id']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? '',
        avatarUrl: _nonEmpty(json['avatar_url']),
        positionName: _nonEmpty(json['position_name']),
      );
}

class DelegationModel {
  final String id;
  final DelegationStatus status;
  final String reportId;
  final String reportTitle;
  final String? reportImageUrl;
  final String? reportAddress;
  final ReportSeverity severity;
  final ColleagueModel requester;
  final ColleagueModel helper;
  final double ratePercent;
  final double commissionAmount;
  final double bonusAmount;
  final String? note;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const DelegationModel({
    required this.id,
    required this.status,
    required this.reportId,
    required this.reportTitle,
    this.reportImageUrl,
    this.reportAddress,
    required this.severity,
    required this.requester,
    required this.helper,
    required this.ratePercent,
    required this.commissionAmount,
    required this.bonusAmount,
    this.note,
    this.expiresAt,
    this.createdAt,
  });

  /// Tổng người làm giùm nhận khi hoàn tất.
  double get helperTotal => commissionAmount + bonusAmount;

  bool isRequester(String? staffId) => staffId != null && requester.id == staffId;
  bool isHelper(String? staffId) => staffId != null && helper.id == staffId;

  factory DelegationModel.fromJson(Map<String, dynamic> json) => DelegationModel(
        id: json['id']?.toString() ?? '',
        status: DelegationStatus.parse(json['status']?.toString()),
        reportId: json['report_id']?.toString() ?? '',
        reportTitle: json['report_title']?.toString() ?? '',
        reportImageUrl: _nonEmpty(json['report_image_url']),
        reportAddress: _nonEmpty(json['report_address']),
        severity: ReportModel.mapSeverity(json['severity']?.toString()),
        requester: ColleagueModel.fromJson(_map(json['requester'])),
        helper: ColleagueModel.fromJson(_map(json['helper'])),
        ratePercent: _double(json['rate_percent']),
        commissionAmount: _double(json['commission_amount']),
        bonusAmount: _double(json['bonus_amount']),
        note: _nonEmpty(json['note']),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

/// Trạng thái nhờ làm giùm của một report với staff đang xem.
class DelegationReportStateModel {
  final bool canRequest;
  final String? reasonCode;
  final String? reason;
  final double commissionAmount;
  final double ratePercent;
  final double bonusAmount;
  final double balance;
  final DelegationModel? activeDelegation;

  /// Yêu cầu đã hoàn tất mà staff tham gia (không đồng thời với [activeDelegation]).
  final DelegationModel? completedDelegation;
  final DelegationViewerRole? viewerRole;

  const DelegationReportStateModel({
    required this.canRequest,
    this.reasonCode,
    this.reason,
    required this.commissionAmount,
    required this.ratePercent,
    required this.bonusAmount,
    required this.balance,
    this.activeDelegation,
    this.completedDelegation,
    this.viewerRole,
  });

  /// Lý do duy nhất nên cho người dùng thấy (các lý do khác chỉ làm ẩn nút).
  bool get isInsufficientBalance => reasonCode == 'delegation.insufficient_balance';

  // Khung hoa hồng ở chi tiết report hiển thị theo người đang xem

  /// Bonus người làm giùm sẽ nhận thêm khi hoàn tất (yêu cầu đang chờ / đã nhận), null nếu không áp dụng.
  double? get upcomingBonusForViewer {
    final active = activeDelegation;
    if (viewerRole != DelegationViewerRole.helper || active == null || active.bonusAmount <= 0) return null;
    return active.bonusAmount;
  }

  /// Yêu cầu đã hoàn tất mà người đang xem là người làm giùm → cộng bonus vào số tiền đã nhận.
  DelegationModel? get bonusReceivedByViewer =>
      viewerRole == DelegationViewerRole.helper ? completedDelegation : null;

  /// Yêu cầu đã hoàn tất mà người đang xem là người nhờ → hiện bonus đã trả.
  DelegationModel? get bonusPaidByViewer =>
      viewerRole == DelegationViewerRole.requester ? completedDelegation : null;

  /// Task đã chuyển cho người làm giùm → hoa hồng không thuộc về người nhờ, ẩn khung hoa hồng.
  bool get hidesViewerCommission =>
      viewerRole == DelegationViewerRole.requester &&
      (activeDelegation?.status == DelegationStatus.accepted || completedDelegation != null);

  factory DelegationReportStateModel.fromJson(Map<String, dynamic> json) => DelegationReportStateModel(
        canRequest: json['can_request'] == true,
        reasonCode: _nonEmpty(json['reason_code']),
        reason: _nonEmpty(json['reason']),
        commissionAmount: _double(json['commission_amount']),
        ratePercent: _double(json['rate_percent']),
        bonusAmount: _double(json['bonus_amount']),
        balance: _double(json['balance']),
        activeDelegation: json['active_delegation'] is Map<String, dynamic>
            ? DelegationModel.fromJson(json['active_delegation'] as Map<String, dynamic>)
            : null,
        completedDelegation: json['completed_delegation'] is Map<String, dynamic>
            ? DelegationModel.fromJson(json['completed_delegation'] as Map<String, dynamic>)
            : null,
        viewerRole: DelegationViewerRole.parse(json['viewer_role']?.toString()),
      );
}

/// Một trang kết quả phân trang từ backend (`PageResponse`).
class DelegationPage<T> {
  final List<T> items;
  final int page;
  final int totalPages;

  const DelegationPage({required this.items, required this.page, required this.totalPages});

  bool get hasMore => page + 1 < totalPages;

  factory DelegationPage.fromJson(dynamic json, T Function(Map<String, dynamic>) itemFromJson) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final content = map['content'];
    return DelegationPage(
      items: content is List ? content.whereType<Map<String, dynamic>>().map(itemFromJson).toList() : <T>[],
      page: (map['currentPage'] as num?)?.toInt() ?? (map['current_page'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? (map['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

double _double(dynamic value) => (value as num?)?.toDouble() ?? 0.0;

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : const {};
