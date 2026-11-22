import 'dart:ui' show Locale;

import 'package:mobile_shared/core/utils/report_category_helper.dart';

class ReportCategoryModel {
  final String id;
  final String code;
  final String nameVi;
  final String nameEn;
  final String? description;
  final String? iconKey;
  final String defaultSeverity;
  final bool active;
  final int displayOrder;

  const ReportCategoryModel({
    required this.id,
    required this.code,
    required this.nameVi,
    required this.nameEn,
    this.description,
    this.iconKey,
    this.defaultSeverity = 'low',
    this.active = true,
    this.displayOrder = 0,
  });

  factory ReportCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReportCategoryModel(
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
