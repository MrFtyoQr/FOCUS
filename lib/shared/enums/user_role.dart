enum UserRole {
  superAdmin,
  adminArea,
  trabajador;

  String get label {
    switch (this) {
      case superAdmin: return 'Super Admin';
      case adminArea:  return 'Admin de Área';
      case trabajador: return 'Trabajador';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'super_admin': return UserRole.superAdmin;
      case 'admin_area':  return UserRole.adminArea;
      default:            return UserRole.trabajador;
    }
  }
}
