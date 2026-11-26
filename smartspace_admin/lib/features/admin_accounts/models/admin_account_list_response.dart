import 'admin_account_model.dart';

/// Tổng hợp trên toàn bộ admin (không phụ thuộc filter đang áp dụng).
class AdminAccountSummary {
  final int total;
  final int active;
  final int blocked;

  const AdminAccountSummary({
    required this.total,
    required this.active,
    required this.blocked,
  });

  static const empty = AdminAccountSummary(total: 0, active: 0, blocked: 0);

  factory AdminAccountSummary.fromJson(Map<String, dynamic> json) {
    return AdminAccountSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      blocked: (json['blocked'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAccountListResponse {
  final AdminAccountSummary summary;
  final List<AdminAccountModel> admins;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;

  const AdminAccountListResponse({
    required this.summary,
    required this.admins,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
  });

  factory AdminAccountListResponse.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? const {};
    final pageJson = json['admins'] as Map<String, dynamic>? ?? const {};
    final content = pageJson['content'] as List<dynamic>? ?? const [];

    return AdminAccountListResponse(
      summary: AdminAccountSummary.fromJson(summaryJson),
      admins: content
          .map((e) => AdminAccountModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (pageJson['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (pageJson['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (pageJson['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (pageJson['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
