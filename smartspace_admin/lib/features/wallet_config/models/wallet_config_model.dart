class WalletConfigModel {
  final double commissionLow;
  final double commissionMedium;
  final double commissionHigh;
  final double commissionCritical;
  final double penaltyRate1;
  final double penaltyRate2;
  final double penaltyRate3;

  const WalletConfigModel({
    required this.commissionLow,
    required this.commissionMedium,
    required this.commissionHigh,
    required this.commissionCritical,
    required this.penaltyRate1,
    required this.penaltyRate2,
    required this.penaltyRate3,
  });

  factory WalletConfigModel.fromJson(Map<String, dynamic> json) {
    return WalletConfigModel(
      commissionLow: (json['commissionLow'] as num?)?.toDouble() ?? 2000.0,
      commissionMedium: (json['commissionMedium'] as num?)?.toDouble() ?? 5000.0,
      commissionHigh: (json['commissionHigh'] as num?)?.toDouble() ?? 7000.0,
      commissionCritical: (json['commissionCritical'] as num?)?.toDouble() ?? 10000.0,
      penaltyRate1: (json['penaltyRate1'] as num?)?.toDouble() ?? 0.2,
      penaltyRate2: (json['penaltyRate2'] as num?)?.toDouble() ?? 0.2,
      penaltyRate3: (json['penaltyRate3'] as num?)?.toDouble() ?? 0.6,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commissionLow': commissionLow,
      'commissionMedium': commissionMedium,
      'commissionHigh': commissionHigh,
      'commissionCritical': commissionCritical,
      'penaltyRate1': penaltyRate1,
      'penaltyRate2': penaltyRate2,
      'penaltyRate3': penaltyRate3,
    };
  }

  WalletConfigModel copyWith({
    double? commissionLow,
    double? commissionMedium,
    double? commissionHigh,
    double? commissionCritical,
    double? penaltyRate1,
    double? penaltyRate2,
    double? penaltyRate3,
  }) {
    return WalletConfigModel(
      commissionLow: commissionLow ?? this.commissionLow,
      commissionMedium: commissionMedium ?? this.commissionMedium,
      commissionHigh: commissionHigh ?? this.commissionHigh,
      commissionCritical: commissionCritical ?? this.commissionCritical,
      penaltyRate1: penaltyRate1 ?? this.penaltyRate1,
      penaltyRate2: penaltyRate2 ?? this.penaltyRate2,
      penaltyRate3: penaltyRate3 ?? this.penaltyRate3,
    );
  }
}

