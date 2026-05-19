enum UserRole {
  superAdmin,
  adminArea,
  trabajador,
  /// Cuenta solo personal, sin organización ni jerarquía.
  personal;

  String get label {
    switch (this) {
      case superAdmin:
        return 'Super Admin';
      case adminArea:
        return 'Admin de Área';
      case trabajador:
        return 'Trabajador';
      case personal:
        return 'Personal';
    }
  }

  /// Acepta variantes típicas de API (`super_admin`, `superAdmin`, `admin_area`, etc.).
  static UserRole fromString(String value) {
    final v = value.trim().toLowerCase().replaceAll('-', '_');
    if (v.isEmpty) return UserRole.trabajador;
    final compact = v.replaceAll('_', '');
    if (compact == 'superadmin' || v == 'super_admin') {
      return UserRole.superAdmin;
    }
    if (compact == 'adminarea' || v == 'admin_area') {
      return UserRole.adminArea;
    }
    if (compact == 'personal' ||
        v == 'solo' ||
        v == 'none' ||
        v == 'usuario' ||
        v == 'individual') {
      return UserRole.personal;
    }
    if (compact == 'trabajador' ||
        v == 'worker' ||
        v == 'empleado' ||
        v == 'employee') {
      return UserRole.trabajador;
    }
    return UserRole.trabajador;
  }
}
