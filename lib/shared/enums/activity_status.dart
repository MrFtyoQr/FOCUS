enum ActivityStatus {
  bandeja, hoy, manana, programado, pendientes, completada;

  String get label {
    switch (this) {
      case bandeja:    return 'Bandeja';
      case hoy:        return 'Hoy';
      case manana:     return 'Mañana';
      case programado: return 'Programado';
      case pendientes: return 'Pendientes';
      case completada: return 'Completada';
    }
  }

  static ActivityStatus fromString(String value) {
    if (value == 'retrasada') return ActivityStatus.pendientes;
    return ActivityStatus.values.firstWhere((e) => e.name == value, orElse: () => ActivityStatus.bandeja);
  }
}
