import 'package:smartspace_admin/core/constants/role_constant.dart';
import 'package:smartspace_admin/core/constants/registration_status.dart';

class UserModel {
  final String id;
  final String email;
  final String fullname;
  final String avatarUrl;
  final ERole role;
  final ERegistrationStatus? registrationStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.fullname,
    required this.avatarUrl,
    required this.role,
    this.registrationStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullname: json['fullname'] as String,
      avatarUrl: json['avatar_url'] as String,
      role: ERole.fromString(json['role'] as String)!,
      registrationStatus: json['registrationStatus'] != null
          ? ERegistrationStatus.fromString(json['registrationStatus'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullname,
      'avatar_url': avatarUrl,
      'role': role.value,
    };
  }
}
