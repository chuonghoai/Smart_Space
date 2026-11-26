import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/features/map/models/map_focus_target.dart';

void main() {
  group('MapFocusTarget', () {
    const target = MapFocusTarget(reportId: 'r-1', latitude: 10.8231, longitude: 106.6297);

    // Test Case ID: SMP-316
    // Description: Kiểm tra chuyển đổi khứ hồi từ MapFocusTarget.toLocation sang MapFocusTarget.fromQueryParameters giữ nguyên path và dữ liệu.
    test('toLocation → fromQueryParameters giữ nguyên dữ liệu', () {
      final uri = Uri.parse(target.toLocation('/map'));
      expect(uri.path, '/map');
      expect(MapFocusTarget.fromQueryParameters(uri.queryParameters), target);
    });

    // Test Case ID: SMP-317
    // Description: Kiểm tra MapFocusTarget.fromQueryParameters trả về null khi Map query rỗng.
    test('mở bản đồ bình thường (không có query) → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {}), isNull);
    });

    // Test Case ID: SMP-318
    // Description: Kiểm tra MapFocusTarget.fromQueryParameters trả về null khi thiếu tham số, focus rỗng hoặc toạ độ không phải số.
    test('thiếu/sai tham số → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '10.8'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': ' ', 'lat': '10.8', 'lng': '106.6'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': 'abc', 'lng': '106.6'}), isNull);
    });

    // Test Case ID: SMP-319
    // Description: Kiểm tra MapFocusTarget.fromQueryParameters trả về null khi toạ độ ngoài phạm vi hợp lệ hoặc là (0, 0).
    test('toạ độ ngoài phạm vi hoặc (0, 0) → null', () {
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '95', 'lng': '106.6'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '10.8', 'lng': '-181'}), isNull);
      expect(MapFocusTarget.fromQueryParameters(const {'focus': 'r-1', 'lat': '0', 'lng': '0'}), isNull);
    });
  });
}
