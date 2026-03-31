import '../enums/user_role.dart';

class UserModel {
  final String  id;
  final String  email;
  final String  firstName;
  final String  lastName;
  final UserRole role;
  final String?  areaId;
  final String?  areaName;
  final bool     biometricsEnabled;
  final bool     onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.areaId,
    this.areaName,
    this.biometricsEnabled = false,
    this.onboardingCompleted = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdminArea  => role == UserRole.adminArea;
  bool get isTrabajador => role == UserRole.trabajador;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:                  json['id'] as String,
    email:               json['email'] as String,
    firstName:           (json['first_name'] ?? '') as String,
    lastName:            (json['last_name']  ?? '') as String,
    role:                UserRole.fromString(json['role'] as String? ?? 'trabajador'),
    areaId:              json['area_id'] as String?,
    areaName:            json['area_name'] as String?,
    biometricsEnabled:   json['biometrics_enabled'] as bool? ?? false,
    onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name':  lastName,
  };
}
