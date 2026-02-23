import 'package:dio/dio.dart';
import 'api_client.dart';

/// DTO alineado al backend (proyecto_schemas).
class ProyectoResponse {
  final int id;
  final String nombre;
  final String? descripcion;
  final int estanciaId;
  final int? responsableId;
  final String estado;
  final String? fechaInicio;
  final String? fechaFinEstimada;
  final String? fechaCreacion;

  ProyectoResponse({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.estanciaId,
    this.responsableId,
    required this.estado,
    this.fechaInicio,
    this.fechaFinEstimada,
    this.fechaCreacion,
  });

  factory ProyectoResponse.fromJson(Map<String, dynamic> json) {
    return ProyectoResponse(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estanciaId: json['estancia_id'] as int,
      responsableId: json['responsable_id'] as int?,
      estado: json['estado'] as String? ?? 'pendiente',
      fechaInicio: json['fecha_inicio'] as String?,
      fechaFinEstimada: json['fecha_fin_estimada'] as String?,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }
}

/// Cliente API para proyectos: list por estancia, CRUD.
class ProyectosApi {
  ProyectosApi._();
  static final ProyectosApi _instance = ProyectosApi._();
  factory ProyectosApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<ProyectoResponse>> list({
    required int estanciaId,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      'proyectos',
      queryParameters: {'estancia_id': estanciaId, 'skip': skip, 'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => ProyectoResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProyectoResponse> get(int proyectoId) async {
    final response = await _client.dio.get<Map<String, dynamic>>('proyectos/$proyectoId');
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return ProyectoResponse.fromJson(response.data!);
  }

  Future<ProyectoResponse> create({
    required int estanciaId,
    required String nombre,
    String? descripcion,
    int? responsableId,
    String? estado,
    String? fechaInicio,
    String? fechaFinEstimada,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'proyectos',
      data: {
        'estancia_id': estanciaId,
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (responsableId != null) 'responsable_id': responsableId,
        if (estado != null) 'estado': estado,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
        if (fechaFinEstimada != null) 'fecha_fin_estimada': fechaFinEstimada,
      },
    );
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return ProyectoResponse.fromJson(response.data!);
  }

  Future<ProyectoResponse> update(
    int proyectoId, {
    String? nombre,
    String? descripcion,
    int? responsableId,
    String? estado,
    String? fechaInicio,
    String? fechaFinEstimada,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      'proyectos/$proyectoId',
      data: {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (responsableId != null) 'responsable_id': responsableId,
        if (estado != null) 'estado': estado,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
        if (fechaFinEstimada != null) 'fecha_fin_estimada': fechaFinEstimada,
      },
    );
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return ProyectoResponse.fromJson(response.data!);
  }

  Future<void> delete(int proyectoId) async {
    await _client.dio.delete('proyectos/$proyectoId');
  }

  /// GET /proyectos/{id}/avance — avance del proyecto (tareas completadas/total).
  Future<ProyectoAvanceResponse> getAvance(int proyectoId) async {
    final response = await _client.dio.get<Map<String, dynamic>>('proyectos/$proyectoId/avance');
    if (response.data == null) throw DioException(requestOptions: response.requestOptions, message: 'Sin datos');
    return ProyectoAvanceResponse.fromJson(response.data!);
  }
}

/// Respuesta de avance (KpiProyectoResponse).
class ProyectoAvanceResponse {
  final int proyectoId;
  final double avance;
  final int tareasTotales;
  final int tareasCompletadas;

  ProyectoAvanceResponse({
    required this.proyectoId,
    required this.avance,
    required this.tareasTotales,
    required this.tareasCompletadas,
  });

  factory ProyectoAvanceResponse.fromJson(Map<String, dynamic> json) {
    return ProyectoAvanceResponse(
      proyectoId: json['proyecto_id'] as int,
      avance: (json['avance'] as num?)?.toDouble() ?? 0.0,
      tareasTotales: json['tareas_totales'] as int? ?? 0,
      tareasCompletadas: json['tareas_completadas'] as int? ?? 0,
    );
  }
}
