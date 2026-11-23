class StaffModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender; // 'male' | 'female' | 'other'
  final String? status;
  final int processingCount;
  final String? positionId;
  final String? positionName;
  final int weightedLoad;
  final int overdueCount;
  final bool isOverloaded;
  final String assignmentHint;
  final Map<String, int> severityBreakdown;

  const StaffModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.status,
    this.processingCount = 0,
    this.positionId,
    this.positionName,
    this.weightedLoad = 0,
    this.overdueCount = 0,
    this.isOverloaded = false,
    this.assignmentHint = 'normal',
    this.severityBreakdown = const {},
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['severityBreakdown'];
    final breakdown = rawBreakdown is Map
        ? rawBreakdown.map(
            (k, v) => MapEntry(k.toString().toLowerCase(), (v as num?)?.toInt() ?? 0),
          )
        : const <String, int>{};
    return StaffModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      gender: json['gender'] as String?,
      status: json['status'] as String?,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      positionId: json['positionId'] as String?,
      positionName: json['positionName'] as String?,
      weightedLoad: (json['weightedLoad'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      isOverloaded: (json['isOverloaded'] as bool?) ?? (json['overloaded'] as bool?) ?? false,
      assignmentHint: json['assignmentHint']?.toString() ?? 'normal',
      severityBreakdown: breakdown,
    );
  }

  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';
}
