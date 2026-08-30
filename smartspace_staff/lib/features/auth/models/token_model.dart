import 'package:smartspace_staff/core/constants/registration_status.dart';
import 'package:smartspace_staff/features/profile/models/user_model.dart';

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final ERegistrationStatus? registrationStatus;
  final UserModel? userModel;

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.registrationStatus,
    this.userModel,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      registrationStatus: ERegistrationStatus.fromString(
        json['registration_status'] as String,
      ),
      userModel: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'registration_status': registrationStatus?.value,
      'user': userModel?.toJson(),
    };
  }
}
