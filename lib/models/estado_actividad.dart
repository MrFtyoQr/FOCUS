/// Estados posibles de una actividad según el método de hiperproductividad
enum EstadoActividad {
  /// Bandeja de entrada - Captura total, no se ejecuta desde aquí
  bandeja,
  
  /// Hoy (00:01-23:59) - Ejecución directa, capacidad limitada
  hoy,
  
  /// Mañana - Ajuste y cierre, máximo 2 iteraciones para tareas simples
  manana,
  
  /// Otro Día Programado - Fecha objetivo (deadline, no inicio)
  programado,
  
  /// Pendientes - Bloqueado por terceros, no contamina la ejecución diaria
  pendientes,
  
  /// Completada - Tarea finalizada
  completada,
}

extension EstadoActividadExtension on EstadoActividad {
  String get nombre {
    switch (this) {
      case EstadoActividad.bandeja:
        return 'Bandeja';
      case EstadoActividad.hoy:
        return 'Hoy';
      case EstadoActividad.manana:
        return 'Mañana';
      case EstadoActividad.programado:
        return 'Programado';
      case EstadoActividad.pendientes:
        return 'Pendientes';
      case EstadoActividad.completada:
        return 'Completada';
    }
  }
  
  String get descripcion {
    switch (this) {
      case EstadoActividad.bandeja:
        return 'Captura total, no se ejecuta desde aquí';
      case EstadoActividad.hoy:
        return 'Ejecución directa, capacidad limitada';
      case EstadoActividad.manana:
        return 'Ajuste y cierre, máximo 2 iteraciones';
      case EstadoActividad.programado:
        return 'Fecha objetivo (deadline, no inicio)';
      case EstadoActividad.pendientes:
        return 'Bloqueado por terceros';
      case EstadoActividad.completada:
        return 'Tarea finalizada';
    }
  }
}

