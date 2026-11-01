/// Report cần focus khi mở bản đồ từ màn chi tiết: `<mapPath>?focus=<id>&lat=<lat>&lng=<lng>`.
///
/// Đi qua query param (không dùng `extra`) để deep link / khôi phục route vẫn giữ được focus.
class MapFocusTarget {
  /// Zoom khi mở bản đồ tại report — bằng `ClusterMapLayer.clusterMaxZoom` để marker tách khỏi cụm.
  static const double zoom = 16;

  static const String _idKey = 'focus';
  static const String _latKey = 'lat';
  static const String _lngKey = 'lng';

  final String reportId;
  final double latitude;
  final double longitude;

  const MapFocusTarget({
    required this.reportId,
    required this.latitude,
    required this.longitude,
  });

  /// Null nếu thiếu/sai tham số, toạ độ ngoài phạm vi hoặc là (0, 0) (report chưa có vị trí).
  static MapFocusTarget? fromQueryParameters(Map<String, String> query) {
    final id = query[_idKey]?.trim();
    final lat = double.tryParse(query[_latKey] ?? '');
    final lng = double.tryParse(query[_lngKey] ?? '');
    if (id == null || id.isEmpty || lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    if (lat == 0 && lng == 0) return null;
    return MapFocusTarget(reportId: id, latitude: lat, longitude: lng);
  }

  Map<String, String> toQueryParameters() => {
        _idKey: reportId,
        _latKey: latitude.toString(),
        _lngKey: longitude.toString(),
      };

  /// Location đầy đủ để `context.push(...)` tới màn bản đồ có path [mapPath].
  String toLocation(String mapPath) =>
      Uri(path: mapPath, queryParameters: toQueryParameters()).toString();

  @override
  bool operator ==(Object other) =>
      other is MapFocusTarget &&
      other.reportId == reportId &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(reportId, latitude, longitude);
}
