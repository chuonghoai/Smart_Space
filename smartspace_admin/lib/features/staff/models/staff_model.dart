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
  final double? baseLatitude;
  final double? baseLongitude;
  final String? baseAddress;

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
    this.baseLatitude,
    this.baseLongitude,
    this.baseAddress,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
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
      baseLatitude: ((json['baseLatitude'] ?? json['base_latitude']) as num?)
          ?.toDouble(),
      baseLongitude:
          ((json['baseLongitude'] ?? json['base_longitude']) as num?)
              ?.toDouble(),
      baseAddress: (json['baseAddress'] ?? json['base_address']) as String?,
    );
  }

  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';
  bool get hasBaseLocation => baseLatitude != null && baseLongitude != null;

  String? get formattedBaseLocation {
    final addr = baseAddress?.trim();
    if (addr != null && addr.isNotEmpty) return addr;
    if (hasBaseLocation) {
      return '${baseLatitude!.toStringAsFixed(5)}, ${baseLongitude!.toStringAsFixed(5)}';
    }
    return null;
  }
}
