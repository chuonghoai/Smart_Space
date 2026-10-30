import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';

void main() {
  group('MapFocusTarget', () {
    const target = MapFocusTarget(reportId: 'r-1', latitude: 10.8231, longitude: 106.6297);

    test('toLocation → fromQueryParameters giữ nguyên dữ liệu', () {
      final uri = Uri.parse(target.toLocation('/map'));
      expect(uri.path, '/map');
      expect(MapFocusTarget.fromQueryParameters(uri.queryParameters), target);
    });

    test('mở bản đồ bình thường (không có query) → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {}), isNull);
    });

    test('thiếu/sai tham số → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '10.8'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': ' ', 'lat': '10.8', 'lng': '106.6'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': 'abc', 'lng': '106.6'}), isNull);
    });

    test('toạ độ ngoài phạm vi hoặc (0, 0) → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '95', 'lng': '106.6'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '10.8', 'lng': '-181'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '0', 'lng': '0'}), isNull);
    });
  });
}
