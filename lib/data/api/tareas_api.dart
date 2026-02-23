import 'package:dio/dio.dart';
import 'api_client.dart';

/// DTO alineado al backend (tarea_schemas). Asignación y estado vía PUT /tareas/{id}.
class TareaResponse {
  final int id;
  final String titulo;
  final String? descripcion;
  final int proyectoId;
  final int? asignadoId;
  final String estado;
  final String prioridad;
  final String? fechaVencimiento;
  final String? fechaCreacion;

  TareaResponse({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.proyectoId,
    this.asignadoId,
    required this.estado,
    required this.prioridad,
    this.fechaVencimiento,
    this.fechaCreacion,
  });

  factory TareaResponse.fromJson(Map<String, dynamic> json) {
    return TareaResponse(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      proyectoId: json['proyecto_id'] as int,
      asignadoId: json['asignado_id'] as int?,
      estado: json['estado'] as String? ?? 'pendiente',
      prioridad: json['prioridad'] as String? ?? 'media',
      fechaVencimiento: json['fecha_vencimiento'] as String?,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }
}

/// Cliente API para tareas: list por proyecto, CRUD. Asignar y estado con update().
class TareasApi {
  TareasApi._();
  static final TareasApi _instance = TareasApi._();
  factory TareasApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<TareaResponse>> list({
    required int proyectoId,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      'tareas',
      queryParameters: {'proyecto_id': proyectoId, 'skip': skip, 'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => TareaResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TareaResponse> get(int tareaId) async {
    final response = await _client.dio.get<Map<String, dynamic>>('tareas/$tareaId');
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return TareaResponse.fromJson(response.data!);
  }

  Future<TareaResponse> create({
    required int proyectoId,
    required String titulo,
    String? descripcion,
    int? asignadoId,
    String? estado,
    String? prioridad,
    String? fechaVencimiento,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'tareas',
      data: {
        'proyecto_id': proyectoId,
        'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        if (asignadoId != null) 'asignado_id': asignadoId,
        if (estado != null) 'estado': estado,
        if (prioridad != null) 'prioridad': prioridad,
        if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      },
    );
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return TareaResponse.fromJson(response.data!);
  }

  Future<TareaResponse> update(
    int tareaId, {
    String? titulo,
    String? descripcion,
    int? asignadoId,
    String? estado,
    String? prioridad,
    String? fechaVencimiento,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      'tareas/$tareaId',
      data: {
        if (titulo != null) 'titulo': titulo,
        if (descripcion != null) 'descripcion': descripcion,
        if (asignadoId != null) 'asignado_id': asignadoId,
        if (estado != null) 'estado': estado,
        if (prioridad != null) 'prioridad': prioridad,
        if (fechaVencimiento != null) 'fecha_vencimiento': fechaVencimiento,
      },
    );
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return TareaResponse.fromJson(response.data!);
  }

  Future<void> delete(int tareaId) async {
    await _client.dio.delete('tareas/$tareaId');
  }

  /// Asignar tarea: wrapper de update con asignado_id.
  Future<TareaResponse> asignar(int tareaId, int asignadoId) async {
    return update(tareaId, asignadoId: asignadoId);
  }

  /// Cambiar estado: wrapper de update con estado.
  Future<TareaResponse> cambiarEstado(int tareaId, String estado) async {
    return update(tareaId, estado: estado);
  }
}
