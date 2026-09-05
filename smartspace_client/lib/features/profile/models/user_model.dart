import 'package:smartspace_client/core/constants/registration_status.dart';
import 'package:smartspace_client/core/constants/role_constant.dart';

class UserModel {
  final String id;
  final String email;
  final String fullname;
  final String avatarUrl;
  final ERole role;
  final ERegistrationStatus? registrationStatus;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;

  UserModel({
    required this.id,
    required this.email,
    required this.fullname,
    required this.avatarUrl,
    required this.role,
    this.registrationStatus,
    this.phone,
    this.dateOfBirth,
    this.gender,
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
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullname': fullname,
      'avatar_url': avatarUrl,
      'role': role.value,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (gender != null) 'gender': gender,
    };
  }
}
