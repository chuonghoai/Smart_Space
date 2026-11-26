class StaffModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? positionId;
  final String? positionName;
  final int processingCount;
  final double? baseLatitude;
  final double? baseLongitude;
  final String? baseAddress;
  final int weightedLoad;
  final int overdueCount;
  final bool isOverloaded;
  final String assignmentHint; // 'recommended' | 'normal' | 'overloaded'
  final Map<String, int> severityBreakdown;

  StaffModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.positionId,
    this.positionName,
    this.processingCount = 0,
    this.baseLatitude,
    this.baseLongitude,
    this.baseAddress,
    this.weightedLoad = 0,
    this.overdueCount = 0,
    this.isOverloaded = false,
    this.assignmentHint = 'normal',
    this.severityBreakdown = const {},
  });

  bool get hasBaseLocation =>
      baseLatitude != null &&
      baseLongitude != null &&
      baseLatitude! >= -90 &&
      baseLatitude! <= 90 &&
      baseLongitude! >= -180 &&
      baseLongitude! <= 180;

  String? get formattedBaseCoordinates => hasBaseLocation
      ? '${baseLatitude!.toStringAsFixed(5)}, ${baseLongitude!.toStringAsFixed(5)}'
      : null;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['severityBreakdown'];
    final breakdown = rawBreakdown is Map
        ? rawBreakdown.map(
            (k, v) => MapEntry(k.toString().toLowerCase(), (v as num?)?.toInt() ?? 0),
          )
        : const <String, int>{};
    return StaffModel(
      id: json['id']?.toString() ?? '',
      fullName: (json['fullName'] ?? json['full_name']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: (json['phoneNumber'] ?? json['phone_number']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      positionId: (json['positionId'] ?? json['position_id']) as String?,
      positionName: (json['positionName'] ?? json['position_name']) as String?,
      processingCount:
          ((json['processingCount'] ?? json['processing_count']) as num?)
                  ?.toInt() ??
              0,
      baseLatitude:
          ((json['baseLatitude'] ?? json['base_latitude']) as num?)?.toDouble(),
      baseLongitude:
          ((json['baseLongitude'] ?? json['base_longitude']) as num?)
              ?.toDouble(),
      baseAddress: (json['baseAddress'] ?? json['base_address']) as String?,
      weightedLoad: (json['weightedLoad'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      isOverloaded: (json['isOverloaded'] as bool?) ?? (json['overloaded'] as bool?) ?? false,
      assignmentHint: json['assignmentHint']?.toString() ?? 'normal',
      severityBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'positionId': positionId,
      'positionName': positionName,
      'processingCount': processingCount,
      if (baseLatitude != null) 'baseLatitude': baseLatitude,
      if (baseLongitude != null) 'baseLongitude': baseLongitude,
      if (baseAddress != null) 'baseAddress': baseAddress,
    };
  }
}
