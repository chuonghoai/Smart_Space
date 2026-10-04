class StaffModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? status;
  final int processingCount;
  final String? positionId;
  final String? positionName;

  const StaffModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.status,
    this.processingCount = 0,
    this.positionId,
    this.positionName,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String?,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      positionId: json['positionId'] as String?,
      positionName: json['positionName'] as String?,
    );
  }

  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';
}
