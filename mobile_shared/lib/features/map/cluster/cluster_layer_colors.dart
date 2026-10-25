import 'package:flutter/material.dart';

/// Màu của lớp cluster, lấy từ theme hiện tại.
@immutable
class ClusterLayerColors {
  final Color normal;
  final Color onNormal;
  final Color alert;
  final Color onAlert;
  final Color stroke;
  final Brightness brightness;

  const ClusterLayerColors({
    required this.normal,
    required this.onNormal,
    required this.alert,
    required this.onAlert,
    required this.stroke,
    required this.brightness,
  });

  /// [alert] mặc định là `error` (mối nguy thật sự). Truyền màu khác theo đúng ý nghĩa
  /// nghiệp vụ, vd. `warning` cho việc cần chú ý; khi đó màu chữ được chọn theo độ tương phản.
  factory ClusterLayerColors.fromTheme(ThemeData theme, {Color? alert}) {
    final cs = theme.colorScheme;
    return ClusterLayerColors(
      normal: cs.primary,
      onNormal: cs.onPrimary,
      alert: alert ?? cs.error,
      onAlert: alert == null ? cs.onError : _contrastOn(alert),
      stroke: cs.surface,
      brightness: theme.brightness,
    );
  }

  static Color _contrastOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light
          ? Colors.black
          : Colors.white;

  /// Dùng trong id ảnh marker để đổi theme thì tạo lại ảnh đúng màu.
  String get cacheKey =>
      '${brightness.name}${normal.toARGB32().toRadixString(16)}${alert.toARGB32().toRadixString(16)}';

  /// Mapbox expression cần màu dạng chuỗi CSS.
  static String toRgba(Color color) {
    final argb = color.toARGB32();
    final a = ((argb >> 24) & 0xFF) / 255;
    return 'rgba(${(argb >> 16) & 0xFF}, ${(argb >> 8) & 0xFF}, ${argb & 0xFF}, ${a.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) =>
      other is ClusterLayerColors &&
      other.normal == normal &&
      other.onNormal == onNormal &&
      other.alert == alert &&
      other.onAlert == onAlert &&
      other.stroke == stroke &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(normal, onNormal, alert, onAlert, stroke, brightness);
}

