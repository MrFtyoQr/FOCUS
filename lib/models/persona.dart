/// Modelo de una persona del equipo (local)
class Persona {
  final String id;
  final String nombre;
  final String? email;
  final String? telefono;
  final DateTime createdAt;
  final DateTime updatedAt;

  Persona({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
    required this.createdAt,
    required this.updatedAt,
  });

  Persona copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Persona(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      email: map['email'] as String?,
      telefono: map['telefono'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

