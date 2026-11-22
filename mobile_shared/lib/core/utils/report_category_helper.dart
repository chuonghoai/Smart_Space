import 'package:flutter/material.dart';

/// Helper dùng chung cho Danh mục phản ánh (Client / Admin / Staff).
///
/// Là nguồn duy nhất cho danh sách `iconKey` mà backend lưu và cách chọn tên
/// hiển thị theo locale, tránh mỗi app tự định nghĩa một bản riêng rồi lệch nhau.
class ReportCategoryHelper {
  const ReportCategoryHelper._();

  static const String defaultIconKey = 'category';

  static const Map<String, IconData> _icons = {
    'eco': Icons.eco_outlined,
    'construction': Icons.construction_outlined,
    'bolt': Icons.bolt_outlined,
    'water_drop': Icons.water_drop_outlined,
    'shield': Icons.shield_outlined,
    'park': Icons.park_outlined,
    'traffic': Icons.traffic_outlined,
    defaultIconKey: Icons.category_outlined,
  };

  /// Toàn bộ `iconKey` hợp lệ, theo thứ tự hiển thị trong form quản trị.
  static final List<String> iconKeys = List.unmodifiable(_icons.keys);

  /// Icon tương ứng với [iconKey]; key lạ hoặc `null` trả về icon mặc định.
  static IconData iconFor(String? iconKey) =>
      _icons[iconKey] ?? Icons.category_outlined;

  /// Tên danh mục theo [locale]: ưu tiên tiếng Anh khi locale là `en`, còn lại
  /// ưu tiên tiếng Việt; fallback sang ngôn ngữ còn lại nếu bị trống.
  /// Trả về `null` khi cả hai tên đều trống (ví dụ report cũ chưa có danh mục).
  static String? localizedName({
    required Locale locale,
    String? nameVi,
    String? nameEn,
  }) {
    final vi = nameVi?.trim() ?? '';
    final en = nameEn?.trim() ?? '';
    if (vi.isEmpty && en.isEmpty) return null;
    if (locale.languageCode.toLowerCase() == 'en' && en.isNotEmpty) {
      return en;
    }
    return vi.isNotEmpty ? vi : en;
  }
}
