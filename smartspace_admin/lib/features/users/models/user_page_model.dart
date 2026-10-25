import 'package:smartspace_admin/features/users/models/admin_user_model.dart';

/// Parse `PageResponse<AdminUserResponse>` từ backend.
class UserPageModel {
  final List<AdminUserModel> users;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalElements;

  const UserPageModel({
    required this.users,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalElements,
  });

  factory UserPageModel.fromJson(Map<String, dynamic> json) {
    final contentRaw = json['content'];
    final contentList = contentRaw is List ? contentRaw : const [];

    return UserPageModel(
      users: contentList
          .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
