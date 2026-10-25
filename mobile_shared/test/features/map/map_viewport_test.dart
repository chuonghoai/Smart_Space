import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_shared/features/map/cluster/cluster_map_layer.dart';
import 'package:mobile_shared/features/map/models/map_bounds.dart';
import 'package:mobile_shared/features/map/viewport/viewport_load_gate.dart';

void main() {
  group('MapBounds', () {
    const bounds = MapBounds(minLat: 10, maxLat: 11, minLng: 106, maxLng: 107);

    test('contains: khung con nằm trọn bên trong', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.2, maxLat: 10.8, minLng: 106.1, maxLng: 106.9)),
        isTrue,
      );
      expect(bounds.contains(bounds), isTrue);
    });

    test('contains: khung lệch ra ngoài một cạnh', () {
      expect(
        bounds.contains(const MapBounds(minLat: 10.5, maxLat: 11.1, minLng: 106.1, maxLng: 106.9)),
        isFalse,
      );
    });

    test('expandBy: giữ tâm, nhân kích thước theo factor', () {
      final expanded = bounds.expandBy(2);
      expect(expanded.minLat, closeTo(9.5, 1e-9));
      expect(expanded.maxLat, closeTo(11.5, 1e-9));
      expect(expanded.minLng, closeTo(105.5, 1e-9));
      expect(expanded.maxLng, closeTo(107.5, 1e-9));
    });

    test('expandBy: kẹp trong giới hạn toạ độ hợp lệ', () {
      const world = MapBounds(minLat: -80, maxLat: 80, minLng: -170, maxLng: 170);
      final expanded = world.expandBy(3);
      expect(expanded.minLat, -90);
      expect(expanded.maxLat, 90);
      expect(expanded.minLng, -180);
      expect(expanded.maxLng, 180);
    });

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

    test('request đầu tiên dùng khung mở rộng theo prefetchFactor', () {
      final request = gate.begin(viewport)!;
      expect(request.bounds, viewport.expandBy(gate.prefetchFactor));
      expect(gate.lastViewport, viewport);
    });

    test('khung nằm trong vùng đã tải và còn mới → bỏ qua', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      expect(gate.begin(inside), isNull);
    });

    test('quá hạn freshness → tải lại', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      now = now.add(gate.freshness + const Duration(seconds: 1));
      expect(gate.begin(inside), isNotNull);
    });

    test('truncated: khung khác phải tải lại, cùng khung thì không lặp', () {
      gate.succeed(gate.begin(viewport)!, truncated: true);
      expect(gate.begin(viewport), isNull);
      expect(gate.begin(inside), isNotNull);
    });

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

    test('lỗi → cho phép thử lại cùng khung', () {
      final request = gate.begin(viewport)!;
      gate.fail(request);
      expect(gate.begin(viewport), isNotNull);
    });

    test('invalidate (đổi bộ lọc) → khung đã tải cũng phải tải lại', () {
      gate.succeed(gate.begin(viewport)!, truncated: false);
      gate.invalidate();
      expect(gate.begin(inside), isNotNull);
    });
  });

  group('ClusterLayerColors.fromTheme', () {
    test('mặc định: cảnh báo dùng error / onError của theme', () {
      final theme = ThemeData.light();
      final colors = ClusterLayerColors.fromTheme(theme);
      expect(colors.alert, theme.colorScheme.error);
      expect(colors.onAlert, theme.colorScheme.onError);
    });

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
