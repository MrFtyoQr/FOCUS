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

  static ActivityStatus fromString(String value) {
    switch (value) {
      case 'hoy':        return ActivityStatus.hoy;
      case 'manana':     return ActivityStatus.manana;
      case 'programado': return ActivityStatus.programado;
      case 'pendientes': return ActivityStatus.pendientes;
      case 'completada': return ActivityStatus.completada;
      // alias desde backend legacy
      case 'retrasada':  return ActivityStatus.pendientes;
      default:           return ActivityStatus.bandeja;
    }
  }
}
