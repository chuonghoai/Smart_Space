import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';

void main() {
  group('MapBounds', () {
    const bounds = MapBounds(minLat: 10, maxLat: 11, minLng: 106, maxLng: 107);

    // Test Case ID: SMP-320
    // Description: Kiểm tra MapBounds.contains trả về true khi khung con nằm hoàn toàn bên trong hoặc trùng khớp khung cha.
    test('contains: khung con nằm trọn bên trong', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.2, maxLat: 10.8, minLng: 106.1, maxLng: 106.9)),
        isTrue,
      );
      expect(bounds.contains(bounds), isTrue);
    });

    // Test Case ID: SMP-321
    // Description: Kiểm tra MapBounds.contains trả về false khi khung kiểm tra vượt quá một cạnh của khung gốc.
    test('contains: khung lệch ra ngoài một cạnh', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.5, maxLat: 11.1, minLng: 106.1, maxLng: 106.9)),
        isFalse,
      );
    });

    // Test Case ID: SMP-322
    // Description: Kiểm tra MapBounds.expandBy giữ nguyên tâm khung nhìn và nhân kích thước lên theo hệ số factor.
    test('expandBy: giữ tâm, nhân kích thước theo factor', () {
      final expanded = bounds.expandBy(2);
      expect(expanded.minLat, closeTo(9.5, 1e-9));
      expect(expanded.maxLat, closeTo(11.5, 1e-9));
      expect(expanded.minLng, closeTo(105.5, 1e-9));
      expect(expanded.maxLng, closeTo(107.5, 1e-9));
    });

    // Test Case ID: SMP-323
    // Description: Kiểm tra MapBounds.expandBy kẹp các cạnh mở rộng trong giới hạn vĩ độ [-90, 90] và kinh độ [-180, 180].
    test('expandBy: kẹp trong giới hạn toạ độ hợp lệ', () {
      const world = MapBounds(minLat: -80, maxLat: 80, minLng: -170, maxLng: 170);
      final expanded = world.expandBy(3);
      expect(expanded.minLat, -90);
      expect(expanded.maxLat, 90);
      expect(expanded.minLng, -180);
      expect(expanded.maxLng, 180);
    });

    // Test Case ID: SMP-324
    // Description: Kiểm tra MapBounds.toQueryParameters xuất đúng tên tham số snake_case (min_lat, max_lat, min_lng, max_lng).
    test('toQueryParameters dùng tên param snake_case của API client', () {
      expect(bounds.toQueryParameters(), {
        'min_lat': 10.0,
        'max_lat': 11.0,
        'min_lng': 106.0,
        'max_lng': 107.0,
      });
    });
  });

  group('ViewportLoadGate', () {
    const viewport = MapBounds(minLat: 10.7, maxLat: 10.9, minLng: 106.6, maxLng: 106.8);
    const inside = MapBounds(minLat: 10.75, maxLat: 10.85, minLng: 106.65, maxLng: 106.75);

    late DateTime now;
    late ViewportLoadGate gate;

    setUp(() {
      now = DateTime(2026, 1, 1, 12);
      gate = ViewportLoadGate(now: () => now);
    });

    // Test Case ID: SMP-325
    // Description: Kiểm tra ViewportLoadGate.begin ở lần đầu trả về request có bounds mở rộng theo prefetchFactor và cập nhật lastViewport.
    test('request đầu tiên dùng khung mở rộng theo prefetchFactor', () {
      final request = gate.begin(viewport)!;
      expect(request.bounds, viewport.expandBy(gate.prefetchFactor));
      expect(gate.lastViewport, viewport);
    });

    // Test Case ID: SMP-326
    // Description: Kiểm tra ViewportLoadGate.begin trả về null khi khung mới nằm trong vùng đã tải thành công và chưa quá hạn freshness.
    test('khung nằm trong vùng đã tải và còn mới → bỏ qua', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      expect(gate.begin(inside), isNull);
    });

    // Test Case ID: SMP-327
    // Description: Kiểm tra ViewportLoadGate.begin tạo request mới khi dữ liệu đã tải vượt quá thời gian freshness.
    test('quá hạn freshness → tải lại', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      now = now.add(gate.freshness + const Duration(seconds: 1));
      expect(gate.begin(inside), isNotNull);
    });

    // Test Case ID: SMP-328
    // Description: Kiểm tra khi kết quả trước bị truncated thì khung nhìn khác phải tải lại nhưng đúng khung cũ không lặp vô hạn.
    test('truncated: khung khác phải tải lại, cùng khung thì không lặp', () {
      gate.succeed(gate.begin(viewport)!, truncated: true);
      expect(gate.begin(viewport), isNull);
      expect(gate.begin(inside), isNotNull);
    });

    // Test Case ID: SMP-329
    // Description: Kiểm tra request cũ mất trạng thái isCurrent khi có request mới hơn và kết quả của request cũ không ghi đè trạng thái.
    test('request cũ không còn là current khi đã có request mới', () {
      final first = gate.begin(viewport)!;
      final second = gate.begin(inside, force: true)!;
      expect(gate.isCurrent(first), isFalse);
      expect(gate.isCurrent(second), isTrue);

      // Kết quả của request cũ không được ghi nhận
      gate.succeed(first, truncated: false);
      gate.succeed(second, truncated: false);
      expect(gate.begin(inside), isNull);
    });

    // Test Case ID: SMP-330
    // Description: Kiểm tra ViewportLoadGate.fail cho phép gọi begin lại trên chính khung viewport vừa thất bại.
    test('lỗi → cho phép thử lại cùng khung', () {
      final request = gate.begin(viewport)!;
      gate.fail(request);
      expect(gate.begin(viewport), isNotNull);
    });

    // Test Case ID: SMP-331
    // Description: Kiểm tra ViewportLoadGate.invalidate xóa bộ nhớ vùng đã tải khiến khung cũ phải tải lại.
    test('invalidate (đổi bộ lọc) → khung đã tải cũng phải tải lại', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      gate.invalidate();
      expect(gate.begin(inside), isNotNull);
    });
  });

  group('ClusterLayerColors.fromTheme', () {
    // Test Case ID: SMP-332
    // Description: Kiểm tra ClusterLayerColors.fromTheme mặc định lấy màu alert từ colorScheme.error và onAlert từ colorScheme.onError.
    test('mặc định: cảnh báo dùng error / onError của theme', () {
      final theme = ThemeData.light();
      final colors = ClusterLayerColors.fromTheme(theme);
      expect(colors.alert, theme.colorScheme.error);
      expect(colors.onAlert, theme.colorScheme.onError);
    });

    // Test Case ID: SMP-333
    // Description: Kiểm tra ClusterLayerColors.fromTheme tự động chọn màu chữ đen hoặc trắng theo độ tương phản khi truyền màu alert tùy chọn.
    test('màu cảnh báo tuỳ chọn: chữ chọn theo độ tương phản', () {
      final theme = ThemeData.light();
      final onYellow = ClusterLayerColors.fromTheme(theme, alert: const Color(0xFFF9A825));
      expect(onYellow.onAlert, Colors.black, reason: 'nền warning vàng cần chữ tối');

      final onDark = ClusterLayerColors.fromTheme(theme, alert: const Color(0xFF1565C0));
      expect(onDark.onAlert, Colors.white);
    });
  });

  group('ClusterMapLayer.toFeatureCollection', () {
    const marker = ClusterMarker(
      id: 'a',
      latitude: 10.5,
      longitude: 106.5,
      imageUrl: '',
      isAlert: true,
      isEmphasized: false,
      styleKey: 'pending',
    );

    // Test Case ID: SMP-334
    // Description: Kiểm tra ClusterMapLayer.toFeatureCollection sinh GeoJSON Point theo thứ tự [lng, lat] cùng đủ properties của marker.
    test('tạo Point [lng, lat] kèm đủ thuộc tính cho layer', () {
      final json = jsonDecode(ClusterMapLayer.toFeatureCollection(
        [marker],
        (m) => 'img-${m.id}',
        (m) => 'fallback-${m.styleKey}',
      )) as Map<String, dynamic>;

      final feature = (json['features'] as List).single as Map<String, dynamic>;
      expect(feature['geometry'], {
        'type': 'Point',
        'coordinates': [106.5, 10.5],
      });
      expect(feature['properties'], {
        'id': 'a',
        'isAlert': true,
        'isEmphasized': false,
        'imageKey': 'img-a',
        'fallbackKey': 'fallback-pending',
      });
    });

    // Test Case ID: SMP-335
    // Description: Kiểm tra ClusterMapLayer.toFeatureCollection loại bỏ marker có toạ độ (0, 0) khỏi danh sách features.
    test('bỏ điểm có toạ độ (0,0)', () {
      const zero = ClusterMarker(
        id: 'zero',
        latitude: 0,
        longitude: 0,
        imageUrl: '',
        isAlert: false,
        isEmphasized: false,
        styleKey: 'n',
      );
      final json = jsonDecode(ClusterMapLayer.toFeatureCollection(
        [marker, zero],
        (m) => m.id,
        (m) => m.styleKey,
      )) as Map<String, dynamic>;
      expect((json['features'] as List), hasLength(1));
    });
  });
}
