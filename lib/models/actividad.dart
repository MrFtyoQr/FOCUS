import 'package:hipperapp/models/estado_actividad.dart';

/// Modelo de una actividad en el sistema de hiperproductividad
class Actividad {
  final String id;
  final String titulo;
  final String? descripcion;
  final EstadoActividad estado;
  final String? proyectoId;
  final String? personaAsignadaId;
  final DateTime? fechaObjetivo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool tieneAdjuntos;
  final int orden; // Para ordenamiento en listas (especialmente en "Hoy")

  Actividad({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.estado,
    this.proyectoId,
    this.personaAsignadaId,
    this.fechaObjetivo,
    required this.createdAt,
    required this.updatedAt,
    this.tieneAdjuntos = false,
    this.orden = 0,
  });

  Actividad copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    EstadoActividad? estado,
    String? proyectoId,
    String? personaAsignadaId,
    DateTime? fechaObjetivo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? tieneAdjuntos,
    int? orden,
  }) {
    return Actividad(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      proyectoId: proyectoId ?? this.proyectoId,
      personaAsignadaId: personaAsignadaId ?? this.personaAsignadaId,
      fechaObjetivo: fechaObjetivo ?? this.fechaObjetivo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tieneAdjuntos: tieneAdjuntos ?? this.tieneAdjuntos,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'estado': estado.name,
      'proyectoId': proyectoId,
      'personaAsignadaId': personaAsignadaId,
      'fechaObjetivo': fechaObjetivo?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tieneAdjuntos': tieneAdjuntos ? 1 : 0,
      'orden': orden,
    };
  }

  factory Actividad.fromMap(Map<String, dynamic> map) {
    return Actividad(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      estado: EstadoActividad.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoActividad.bandeja,
      ),
      proyectoId: map['proyectoId'] as String?,
      personaAsignadaId: map['personaAsignadaId'] as String?,
      fechaObjetivo: map['fechaObjetivo'] != null
          ? DateTime.parse(map['fechaObjetivo'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      tieneAdjuntos: (map['tieneAdjuntos'] as int? ?? 0) == 1,
      orden: map['orden'] as int? ?? 0,
    );
  }
}

