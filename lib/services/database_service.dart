import '../database/app_database.dart';

/// Servicio singleton para gestionar la base de datos
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static AppDatabase? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Inicializa la base de datos
  Future<void> initialize() async {
    if (_database == null) {
      _database = AppDatabase();
      // Inicializar la conexión
      await _database!.database;
    }
  }

  /// Obtiene la instancia de la base de datos
  AppDatabase get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Cierra la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
