class RecentActivityModel {
  final String id;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? targetId;
  final String? targetType;
  final String message;
  final String? createdAt;

  const RecentActivityModel({
    required this.id,
    this.actorName,
    this.actorAvatarUrl,
    this.targetId,
    this.targetType,
    required this.message,
    this.createdAt,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id']?.toString() ?? '',
      actorName: json['actorName']?.toString(),
      actorAvatarUrl: json['actorAvatarUrl']?.toString(),
      targetId: json['targetId']?.toString(),
      targetType: json['targetType']?.toString(),
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actorName': actorName,
      'actorAvatarUrl': actorAvatarUrl,
      'targetId': targetId,
      'targetType': targetType,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
