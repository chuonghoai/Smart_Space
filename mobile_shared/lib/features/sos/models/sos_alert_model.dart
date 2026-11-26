/// Trạng thái SOS, khớp enum ESosStatus ở backend.
enum ESosStatus {
  active,
  acknowledged,
  resolved;

  bool get isOpen => this != resolved;

  static ESosStatus fromApi(String? value) {
    return ESosStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value?.toUpperCase(),
      orElse: () => ESosStatus.active,
    );
  }
}

/// Cách SOS kết thúc, khớp enum ESosResolution ở backend.
enum ESosResolution {
  safeByUser('SAFE_BY_USER'),
  resolvedByAdmin('RESOLVED_BY_ADMIN'),
  falseAlarm('FALSE_ALARM');

  final String apiValue;

  const ESosResolution(this.apiValue);

  static ESosResolution? fromApi(String? value) {
    for (final r in ESosResolution.values) {
      if (r.apiValue == value?.toUpperCase()) return r;
    }
    return null;
  }
}

class SosUserModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phone;

  const SosUserModel({required this.id, required this.fullName, this.avatarUrl, this.phone});

  factory SosUserModel.fromJson(Map<String, dynamic> json) {
    return SosUserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': fullName, 'avatar_url': avatarUrl, 'phone': phone};
  }
}

class SosLocationPointModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? recordedAt;

  const SosLocationPointModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.recordedAt,
  });

  factory SosLocationPointModel.fromJson(Map<String, dynamic> json) {
    return SosLocationPointModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recordedAt: DateTime.tryParse(json['recorded_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'recorded_at': recordedAt?.toIso8601String(),
    };
  }
}

class SosAlertModel {
  final String id;
  final ESosStatus status;
  final ESosResolution? resolution;
  final SosUserModel user;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? lastLocationAt;
  final String? message;
  final int notifiedContacts;
  final SosUserModel? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final SosUserModel? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final DateTime? createdAt;

  /// Đường di chuyển, mới nhất trước; chỉ có ở màn chi tiết của admin.
  final List<SosLocationPointModel> track;

  const SosAlertModel({
    required this.id,
    required this.status,
    required this.user,
    required this.latitude,
    required this.longitude,
    this.resolution,
    this.accuracy,
    this.lastLocationAt,
    this.message,
    this.notifiedContacts = 0,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNote,
    this.createdAt,
    this.track = const [],
  });

  bool get isOpen => status.isOpen;

  /// Mở vị trí bằng ứng dụng bản đồ trên thiết bị.
  Uri get mapsUri => Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
      );

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    SosUserModel? user(String key) {
      final value = json[key];
      return value is Map<String, dynamic> ? SosUserModel.fromJson(value) : null;
    }

    final track = json['track'];
    return SosAlertModel(
      id: json['id'] as String? ?? '',
      status: ESosStatus.fromApi(json['status'] as String?),
      resolution: ESosResolution.fromApi(json['resolution'] as String?),
      user: user('user') ?? const SosUserModel(id: '', fullName: ''),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      lastLocationAt: DateTime.tryParse(json['last_location_at']?.toString() ?? ''),
      message: json['message'] as String?,
      notifiedContacts: (json['notified_contacts'] as num?)?.toInt() ?? 0,
      acknowledgedBy: user('acknowledged_by'),
      acknowledgedAt: DateTime.tryParse(json['acknowledged_at']?.toString() ?? ''),
      resolvedBy: user('resolved_by'),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
      resolutionNote: json['resolution_note'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      track: track is List
          ? track.map((e) => SosLocationPointModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name.toUpperCase(),
      'resolution': resolution?.apiValue,
      'user': user.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'last_location_at': lastLocationAt?.toIso8601String(),
      'message': message,
      'notified_contacts': notifiedContacts,
      'acknowledged_by': acknowledgedBy?.toJson(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_by': resolvedBy?.toJson(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_note': resolutionNote,
      'created_at': createdAt?.toIso8601String(),
      'track': track.map((p) => p.toJson()).toList(),
    };
  }

  /// Sự kiện realtime không mang track: giữ track cũ khi gộp.
  SosAlertModel mergeRealtime(SosAlertModel update) {
    if (update.id != id) return update;
    final List<SosLocationPointModel> merged;
    if (update.track.isNotEmpty) {
      merged = update.track;
    } else if (update.lastLocationAt != null && update.lastLocationAt != lastLocationAt && track.isNotEmpty) {
      merged = [
        SosLocationPointModel(
          latitude: update.latitude,
          longitude: update.longitude,
          accuracy: update.accuracy,
          recordedAt: update.lastLocationAt,
        ),
        ...track,
      ];
    } else {
      merged = track;
    }
    return SosAlertModel(
      id: update.id,
      status: update.status,
      resolution: update.resolution,
      user: update.user,
      latitude: update.latitude,
      longitude: update.longitude,
      accuracy: update.accuracy,
      lastLocationAt: update.lastLocationAt,
      message: update.message,
      notifiedContacts: update.notifiedContacts,
      acknowledgedBy: update.acknowledgedBy,
      acknowledgedAt: update.acknowledgedAt,
      resolvedBy: update.resolvedBy,
      resolvedAt: update.resolvedAt,
      resolutionNote: update.resolutionNote,
      createdAt: update.createdAt,
      track: merged,
    );
  }
}

/// Sự kiện từ /user/queue/sos.
class SosRealtimeEvent {
  /// STARTED | LOCATION | ACKNOWLEDGED | RESOLVED
  final String event;
  final SosAlertModel sos;

  const SosRealtimeEvent({required this.event, required this.sos});

  factory SosRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return SosRealtimeEvent(
      event: json['event'] as String? ?? '',
      sos: SosAlertModel.fromJson((json['sos'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {'event': event, 'sos': sos.toJson()};
}
