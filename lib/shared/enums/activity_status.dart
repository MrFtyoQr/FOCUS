enum ActivityStatus {
  bandeja,
  hoy,
  manana,
  programado,
  pendientes,
  completada;

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

  /// Valor que espera el backend (inglés)
  String get apiValue {
    switch (this) {
      case bandeja:    return 'inbox';
      case hoy:        return 'today';
      case manana:     return 'tomorrow';
      case programado: return 'scheduled';
      case pendientes: return 'pending';
      case completada: return 'completed';
    }
  }

  static ActivityStatus fromString(String value) {
    switch (value) {
      // Valores del backend (inglés)
      case 'inbox':     return ActivityStatus.bandeja;
      case 'today':     return ActivityStatus.hoy;
      case 'tomorrow':  return ActivityStatus.manana;
      case 'scheduled': return ActivityStatus.programado;
      case 'pending':   return ActivityStatus.pendientes;
      case 'completed': return ActivityStatus.completada;
      // Alias internos (español — mock / legacy)
      case 'hoy':        return ActivityStatus.hoy;
      case 'manana':     return ActivityStatus.manana;
      case 'programado': return ActivityStatus.programado;
      case 'pendientes': return ActivityStatus.pendientes;
      case 'completada': return ActivityStatus.completada;
      default:           return ActivityStatus.bandeja;
    }
  }
}
