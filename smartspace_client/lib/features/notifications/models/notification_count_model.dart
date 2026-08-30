class NotificationCountModel {
  final int notifNumber;

  NotificationCountModel({required this.notifNumber});

  factory NotificationCountModel.fromJson(Map<String, dynamic> json) {
    return NotificationCountModel(
      notifNumber: json['notif_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'notif_number': notifNumber};
  }
}
