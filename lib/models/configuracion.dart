import 'package:flutter/material.dart';

/// Configuración del usuario y del sistema
class Configuracion {
  final String id;
  final String nombreUsuario;
  final List<TimeOfDay> horariosRevision; // Ej: [10:00, 14:00, 18:00]
  final bool notificacionesActivas;
  final DateTime createdAt;
  final DateTime updatedAt;

  Configuracion({
    required this.id,
    required this.nombreUsuario,
    required this.horariosRevision,
    this.notificacionesActivas = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Configuracion copyWith({
    String? id,
    String? nombreUsuario,
    List<TimeOfDay>? horariosRevision,
    bool? notificacionesActivas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Configuracion(
      id: id ?? this.id,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      horariosRevision: horariosRevision ?? this.horariosRevision,
      notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreUsuario': nombreUsuario,
      'horariosRevision': horariosRevision
          .map((h) => '${h.hour}:${h.minute.toString().padLeft(2, '0')}')
          .toList(),
      'notificacionesActivas': notificacionesActivas ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'] as String,
      nombreUsuario: map['nombreUsuario'] as String,
      horariosRevision: (map['horariosRevision'] as List)
          .map((h) {
            final parts = (h as String).split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          })
          .toList(),
      notificacionesActivas: (map['notificacionesActivas'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

