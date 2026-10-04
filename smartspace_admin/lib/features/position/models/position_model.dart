class PositionModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool active;
  final int staffCount;

  const PositionModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.active = true,
    this.staffCount = 0,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) => PositionModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        active: json['active'] as bool? ?? true,
        staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
      );
}
