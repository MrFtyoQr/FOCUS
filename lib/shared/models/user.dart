import '../enums/user_role.dart';

class UserModel {
  final int      id;
  final String   email;
  final String   firstName;
  final String   lastName;
  final UserRole role;
  final int?     areaId;
  final String?  areaName;
  final bool     onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.areaId,
    this.areaName,
    this.onboardingCompleted = false,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdminArea  => role == UserRole.adminArea;
  bool get isTrabajador => role == UserRole.trabajador;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                  json['id'] as int,
    email:               json['email'] as String,
    firstName:           (json['first_name'] ?? json['nombre'] ?? '') as String,
    lastName:            (json['last_name']  ?? json['apellido'] ?? '') as String,
    role:                UserRole.fromString(json['role'] as String? ?? 'trabajador'),
    areaId:              json['area'] as int?,
    areaName:            json['area_name'] as String?,
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {'first_name': firstName, 'last_name': lastName};
}
