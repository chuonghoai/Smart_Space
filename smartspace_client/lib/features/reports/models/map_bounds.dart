import 'dart:math' as math;

/// Khung nhìn bản đồ (bounding box) theo toạ độ địa lý.
class MapBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  /// [other] nằm trọn trong khung này.
  bool contains(MapBounds other) {
    return other.minLat >= minLat &&
        other.maxLat <= maxLat &&
        other.minLng >= minLng &&
        other.maxLng <= maxLng;
  }

  /// Phóng to khung quanh tâm theo [factor] (1.5 = rộng gấp 1.5 lần),
  /// kẹp trong giới hạn hợp lệ của toạ độ.
  MapBounds expandBy(double factor) {
    final halfLat = (maxLat - minLat) * factor / 2;
    final halfLng = (maxLng - minLng) * factor / 2;
    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    return MapBounds(
      minLat: math.max(-90, centerLat - halfLat),
      maxLat: math.min(90, centerLat + halfLat),
      minLng: math.max(-180, centerLng - halfLng),
      maxLng: math.min(180, centerLng + halfLng),
    );
  }

  Map<String, dynamic> toQueryParameters() => {
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lng': minLng,
        'max_lng': maxLng,
      };

  @override
  bool operator ==(Object other) =>
      other is MapBounds &&
      other.minLat == minLat &&
      other.maxLat == maxLat &&
      other.minLng == minLng &&
      other.maxLng == maxLng;

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLng, maxLng);
}
