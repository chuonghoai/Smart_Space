/// Tài khoản quản trị viên trong "Hội đồng quản trị".
class AdminAccountModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? status; // 'active' | 'blocked'
  final DateTime? createdAt;

  /// true nếu đây là tài khoản của admin đang đăng nhập (do backend tính từ JWT).
  final bool isCurrentUser;

  const AdminAccountModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.status,
    this.createdAt,
    this.isCurrentUser = false,
  });

  factory AdminAccountModel.fromJson(Map<String, dynamic> json) {
    return AdminAccountModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      isCurrentUser: json['currentUser'] as bool? ?? false,
    );
  }

  bool get isActive => status == 'active';

  /// Tên hiển thị — fallback về email khi chưa có họ tên.
  String get displayName => fullName.trim().isNotEmpty ? fullName.trim() : email;
}
