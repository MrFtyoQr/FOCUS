/// Modelo de un proyecto (contenedor transversal)
class Proyecto {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? color; // Color en hex para identificación visual
  final DateTime createdAt;
  final DateTime updatedAt;

  Proyecto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Proyecto copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Proyecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Proyecto.fromMap(Map<String, dynamic> map) {
    return Proyecto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

