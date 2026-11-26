import 'dart:ui' show Locale;

import 'package:mobile_shared/core/utils/report_category_helper.dart';

class CategoryPositionRef {
  final String id;
  final String code;
  final String name;
  final bool active;

  const CategoryPositionRef({
    required this.id,
    required this.code,
    required this.name,
    this.active = true,
  });

  factory CategoryPositionRef.fromJson(Map<String, dynamic> json) {
    return CategoryPositionRef(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }
}

class CategoryModel {
  final String id;
  final String code;
  final String nameVi;
  final String nameEn;
  final String? description;
  final String? iconKey;
  final String defaultSeverity;
  final bool active;
  final int displayOrder;
  final int reportCount;
  final List<CategoryPositionRef> positions;

  const CategoryModel({
    required this.id,
    required this.code,
    required this.nameVi,
    required this.nameEn,
    this.description,
    this.iconKey,
    this.defaultSeverity = 'low',
    this.active = true,
    this.displayOrder = 0,
    this.reportCount = 0,
    this.positions = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['positions'] as List? ?? const [];
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      nameVi: (json['nameVi'] ?? json['name_vi'])?.toString() ?? '',
      nameEn: (json['nameEn'] ?? json['name_en'])?.toString() ?? '',
      description: json['description'] as String?,
      iconKey: (json['iconKey'] ?? json['icon_key']) as String?,
      defaultSeverity:
          (json['defaultSeverity'] ?? json['default_severity'])?.toString() ??
              'low',
      active: json['active'] as bool? ?? true,
      displayOrder:
          ((json['displayOrder'] ?? json['display_order']) as num?)?.toInt() ??
              0,
      reportCount:
          ((json['reportCount'] ?? json['report_count']) as num?)?.toInt() ?? 0,
      positions: rawPositions
          .whereType<Map<String, dynamic>>()
          .map(CategoryPositionRef.fromJson)
          .toList(),
    );
  }

  String localizedName(Locale locale) =>
      ReportCategoryHelper.localizedName(
        locale: locale,
        nameVi: nameVi,
        nameEn: nameEn,
      ) ??
      code;
}
