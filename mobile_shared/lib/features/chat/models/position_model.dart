class PositionModel {
  final String id;
  final String name;
  final String code;
  final String? description;
  final bool active;
  final int staffCount;

  const PositionModel({
    required this.id,
    required this.name,
    this.code = '',
    this.description,
    this.active = true,
    this.staffCount = 0,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
      staffCount: (json['staffCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'active': active,
      'staffCount': staffCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
