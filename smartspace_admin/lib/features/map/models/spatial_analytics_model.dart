class SpatialHotspotItem {
  final String h3Index;
  final double centerLat;
  final double centerLng;
  final String? sampleAddress;
  final int countLast30d;
  final double prev90dAvg30d;
  final double growthRatio;
  final bool isAccelerating;
  final int pendingCount;
  final int processingCount;
  final int highCriticalCount;
  final int overdueCount;
  final int riskScore;

  const SpatialHotspotItem({
    required this.h3Index,
    required this.centerLat,
    required this.centerLng,
    this.sampleAddress,
    this.countLast30d = 0,
    this.prev90dAvg30d = 0.0,
    this.growthRatio = 0.0,
    this.isAccelerating = false,
    this.pendingCount = 0,
    this.processingCount = 0,
    this.highCriticalCount = 0,
    this.overdueCount = 0,
    this.riskScore = 0,
  });

  factory SpatialHotspotItem.fromJson(Map<String, dynamic> json) {
    return SpatialHotspotItem(
      h3Index: json['h3Index']?.toString() ?? '',
      centerLat: (json['centerLat'] as num?)?.toDouble() ?? 0.0,
      centerLng: (json['centerLng'] as num?)?.toDouble() ?? 0.0,
      sampleAddress: json['sampleAddress']?.toString(),
      countLast30d: (json['countLast30d'] as num?)?.toInt() ?? 0,
      prev90dAvg30d: (json['prev90dAvg30d'] as num?)?.toDouble() ?? 0.0,
      growthRatio: (json['growthRatio'] as num?)?.toDouble() ?? 0.0,
      isAccelerating: (json['isAccelerating'] as bool?) ?? (json['accelerating'] as bool?) ?? false,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      highCriticalCount: (json['highCriticalCount'] as num?)?.toInt() ?? 0,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      riskScore: (json['riskScore'] as num?)?.toInt() ?? 0,
    );
  }
}

class SpatialAnalyticsResult {
  final int h3Resolution;
  final int totalHotspots;
  final int acceleratingHotspots;
  final List<SpatialHotspotItem> hotspots;

  const SpatialAnalyticsResult({
    this.h3Resolution = 11,
    this.totalHotspots = 0,
    this.acceleratingHotspots = 0,
    this.hotspots = const [],
  });

  static const empty = SpatialAnalyticsResult();

  factory SpatialAnalyticsResult.fromJson(Map<String, dynamic> json) {
    final list = (json['hotspots'] as List<dynamic>? ?? [])
        .map((e) => SpatialHotspotItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return SpatialAnalyticsResult(
      h3Resolution: (json['h3Resolution'] as num?)?.toInt() ?? 11,
      totalHotspots: (json['totalHotspots'] as num?)?.toInt() ?? 0,
      acceleratingHotspots: (json['acceleratingHotspots'] as num?)?.toInt() ?? 0,
      hotspots: list,
    );
  }
}
