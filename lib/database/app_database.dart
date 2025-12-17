import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

/// Base de datos SQLite simple y persistente
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'hipperapp.db');

    return await openDatabase(dbPath, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de Actividades
    await db.execute('''
      CREATE TABLE actividades (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT NOT NULL,
        proyectoId TEXT,
        personaAsignadaId TEXT,
        fechaObjetivo INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        tieneAdjuntos INTEGER DEFAULT 0,
        orden INTEGER DEFAULT 0
      )
    ''');

    // Tabla de Proyectos
    await db.execute('''
      CREATE TABLE proyectos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        color TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabla de Personas
    await db.execute('''
      CREATE TABLE personas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT,
        telefono TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabla de Bitácora
    await db.execute('''
      CREATE TABLE bitacora (
        id TEXT PRIMARY KEY,
        actividadId TEXT NOT NULL,
        tipo TEXT NOT NULL,
        descripcion TEXT,
        valorAnterior TEXT,
        valorNuevo TEXT,
        timestamp INTEGER NOT NULL,
        usuarioId TEXT
      )
    ''');

    // Tabla de Configuración
    await db.execute('''
      CREATE TABLE configuracion (
        id TEXT PRIMARY KEY,
        nombreUsuario TEXT NOT NULL,
        horariosRevision TEXT NOT NULL,
        notificacionesActivas INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Índices para mejor rendimiento
    await db.execute(
      'CREATE INDEX idx_actividades_estado ON actividades(estado)',
    );
    await db.execute(
      'CREATE INDEX idx_actividades_proyecto ON actividades(proyectoId)',
    );
    await db.execute(
      'CREATE INDEX idx_bitacora_actividad ON bitacora(actividadId)',
    );
  }

  // ========== MÉTODOS PARA ACTIVIDADES ==========

  Future<List<Actividad>> getActividadesPorEstado(
    EstadoActividad estado,
  ) async {
    final db = await database;
    final results = await db.query(
      'actividades',
      where: 'estado = ?',
      whereArgs: [estado.name],
      orderBy: 'orden ASC, updatedAt DESC',
    );
    return results.map((row) => _actividadFromMap(row)).toList();
  }

  Future<Actividad?> getActividadPorId(String id) async {
    final db = await database;
    final results = await db.query(
      'actividades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _actividadFromMap(results.first);
  }

  Future<void> insertarActividad(Actividad actividad) async {
    final db = await database;
    await db.insert('actividades', _actividadToMap(actividad));
  }

  Future<void> actualizarActividad(Actividad actividad) async {
    final db = await database;
    await db.update(
      'actividades',
      _actividadToMap(actividad),
      where: 'id = ?',
      whereArgs: [actividad.id],
    );
  }

  Future<void> eliminarActividad(String id) async {
    final db = await database;
    await db.delete('actividades', where: 'id = ?', whereArgs: [id]);
  }

  // ========== MÉTODOS PARA PROYECTOS ==========

  Future<List<Proyecto>> getAllProyectos() async {
    final db = await database;
    final results = await db.query('proyectos', orderBy: 'nombre ASC');
    return results.map((row) => _proyectoFromMap(row)).toList();
  }

  Future<Proyecto?> getProyectoPorId(String id) async {
    final db = await database;
    final results = await db.query(
      'proyectos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _proyectoFromMap(results.first);
  }

  Future<void> insertarProyecto(Proyecto proyecto) async {
    final db = await database;
    await db.insert('proyectos', _proyectoToMap(proyecto));
  }

  Future<void> actualizarProyecto(Proyecto proyecto) async {
    final db = await database;
    await db.update(
      'proyectos',
      _proyectoToMap(proyecto),
      where: 'id = ?',
      whereArgs: [proyecto.id],
    );
  }

  // ========== MÉTODOS PARA PERSONAS ==========

  Future<List<Persona>> getAllPersonas() async {
    final db = await database;
    final results = await db.query('personas', orderBy: 'nombre ASC');
    return results.map((row) => _personaFromMap(row)).toList();
  }

  Future<void> insertarPersona(Persona persona) async {
    final db = await database;
    await db.insert('personas', _personaToMap(persona));
  }

  // ========== MÉTODOS PARA BITÁCORA ==========

  Future<List<BitacoraEvento>> getBitacoraPorActividad(
    String actividadId,
  ) async {
    final db = await database;
    final results = await db.query(
      'bitacora',
      where: 'actividadId = ?',
      whereArgs: [actividadId],
      orderBy: 'timestamp DESC',
    );
    return results.map((row) => _bitacoraFromMap(row)).toList();
  }

  Future<void> insertarEventoBitacora(BitacoraEvento evento) async {
    final db = await database;
    await db.insert('bitacora', _bitacoraToMap(evento));
  }

  // ========== MÉTODOS PARA CONFIGURACIÓN ==========

  Future<Configuracion?> getConfiguracion() async {
    final db = await database;
    final results = await db.query('configuracion', limit: 1);
    if (results.isEmpty) return null;
    return _configuracionFromMap(results.first);
  }

  Future<void> guardarConfiguracion(Configuracion config) async {
    final db = await database;
    await db.insert(
      'configuracion',
      _configuracionToMap(config),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========== HELPERS DE CONVERSIÓN ==========

  Map<String, dynamic> _actividadToMap(Actividad actividad) {
    return {
      'id': actividad.id,
      'titulo': actividad.titulo,
      'descripcion': actividad.descripcion,
      'estado': actividad.estado.name,
      'proyectoId': actividad.proyectoId,
      'personaAsignadaId': actividad.personaAsignadaId,
      'fechaObjetivo': actividad.fechaObjetivo?.millisecondsSinceEpoch,
      'createdAt': actividad.createdAt.millisecondsSinceEpoch,
      'updatedAt': actividad.updatedAt.millisecondsSinceEpoch,
      'tieneAdjuntos': actividad.tieneAdjuntos ? 1 : 0,
      'orden': actividad.orden,
    };
  }

  Actividad _actividadFromMap(Map<String, dynamic> map) {
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
          ? DateTime.fromMillisecondsSinceEpoch(map['fechaObjetivo'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      tieneAdjuntos: (map['tieneAdjuntos'] as int? ?? 0) == 1,
      orden: map['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _proyectoToMap(Proyecto proyecto) {
    return {
      'id': proyecto.id,
      'nombre': proyecto.nombre,
      'descripcion': proyecto.descripcion,
      'color': proyecto.color,
      'createdAt': proyecto.createdAt.millisecondsSinceEpoch,
      'updatedAt': proyecto.updatedAt.millisecondsSinceEpoch,
    };
  }

  Proyecto _proyectoFromMap(Map<String, dynamic> map) {
    return Proyecto(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      color: map['color'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> _personaToMap(Persona persona) {
    return {
      'id': persona.id,
      'nombre': persona.nombre,
      'email': persona.email,
      'telefono': persona.telefono,
      'createdAt': persona.createdAt.millisecondsSinceEpoch,
      'updatedAt': persona.updatedAt.millisecondsSinceEpoch,
    };
  }

  Persona _personaFromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      email: map['email'] as String?,
      telefono: map['telefono'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> _bitacoraToMap(BitacoraEvento evento) {
    return {
      'id': evento.id,
      'actividadId': evento.actividadId,
      'tipo': evento.tipo.name,
      'descripcion': evento.descripcion,
      'valorAnterior': evento.valorAnterior,
      'valorNuevo': evento.valorNuevo,
      'timestamp': evento.timestamp.millisecondsSinceEpoch,
      'usuarioId': evento.usuarioId,
    };
  }

  BitacoraEvento _bitacoraFromMap(Map<String, dynamic> map) {
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
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      usuarioId: map['usuarioId'] as String?,
    );
  }

  Map<String, dynamic> _configuracionToMap(Configuracion config) {
    return {
      'id': config.id,
      'nombreUsuario': config.nombreUsuario,
      'horariosRevision': config.horariosRevision
          .map((h) => '${h.hour}:${h.minute.toString().padLeft(2, '0')}')
          .join(','),
      'notificacionesActivas': config.notificacionesActivas ? 1 : 0,
      'createdAt': config.createdAt.millisecondsSinceEpoch,
      'updatedAt': config.updatedAt.millisecondsSinceEpoch,
    };
  }

  Configuracion _configuracionFromMap(Map<String, dynamic> map) {
    final horarios = (map['horariosRevision'] as String).split(',').map((h) {
      final parts = h.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    return Configuracion(
      id: map['id'] as String,
      nombreUsuario: map['nombreUsuario'] as String,
      horariosRevision: horarios,
      notificacionesActivas: (map['notificacionesActivas'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
