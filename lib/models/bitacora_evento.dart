import 'package:hipperapp/models/tipo_evento.dart';

/// Evento registrado en la bitácora del sistema
class BitacoraEvento {
  final String id;
  final String actividadId;
  final TipoEvento tipo;
  final String? descripcion; // Detalles del evento
  final String? valorAnterior; // Para eventos de movimiento/actualización
  final String? valorNuevo;
  final DateTime timestamp;
  final String? usuarioId; // Para futuro multiusuario

  BitacoraEvento({
    required this.id,
    required this.actividadId,
    required this.tipo,
    this.descripcion,
    this.valorAnterior,
    this.valorNuevo,
    required this.timestamp,
    this.usuarioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actividadId': actividadId,
      'tipo': tipo.name,
      'descripcion': descripcion,
      'valorAnterior': valorAnterior,
      'valorNuevo': valorNuevo,
      'timestamp': timestamp.toIso8601String(),
      'usuarioId': usuarioId,
    };
  }

  factory BitacoraEvento.fromMap(Map<String, dynamic> map) {
    return BitacoraEvento(
      id: map['id'] as String,
      actividadId: map['actividadId'] as String,
      tipo: TipoEvento.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoEvento.update,
      ),
      descripcion: map['descripcion'] as String?,
      valorAnterior: map['valorAnterior'] as String?,
      valorNuevo: map['valorNuevo'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      usuarioId: map['usuarioId'] as String?,
    );
  }
}

