import 'api_client.dart';

/// DTOs alineados al backend (kpi_schemas).
class KpiEstanciaResponse {
  final int estanciaId;
  final Map<String, dynamic> metricas;
  final String? resumen;

  KpiEstanciaResponse({
    required this.estanciaId,
    Map<String, dynamic>? metricas,
    this.resumen,
  }) : metricas = metricas ?? {};

  factory KpiEstanciaResponse.fromJson(Map<String, dynamic> json) {
    return KpiEstanciaResponse(
      estanciaId: json['estancia_id'] as int,
      metricas: (json['metricas'] is Map)
          ? Map<String, dynamic>.from(json['metricas'] as Map)
          : {},
      resumen: json['resumen'] as String?,
    );
  }
}

class KpiUsuarioResponse {
  final int usuarioId;
  final int estanciaId;
  final int tareasCompletadas;
  final int tareasATiempo;
  final double? promedioCalidad;
  final double? velocidadRespuesta;
  final double? colaboracionScore;
  final String? tendencia;

  KpiUsuarioResponse({
    required this.usuarioId,
    required this.estanciaId,
    this.tareasCompletadas = 0,
    this.tareasATiempo = 0,
    this.promedioCalidad,
    this.velocidadRespuesta,
    this.colaboracionScore,
    this.tendencia,
  });

  factory KpiUsuarioResponse.fromJson(Map<String, dynamic> json) {
    return KpiUsuarioResponse(
      usuarioId: json['usuario_id'] as int,
      estanciaId: json['estancia_id'] as int,
      tareasCompletadas: json['tareas_completadas'] as int? ?? 0,
      tareasATiempo: json['tareas_a_tiempo'] as int? ?? 0,
      promedioCalidad: (json['promedio_calidad'] as num?)?.toDouble(),
      velocidadRespuesta: (json['velocidad_respuesta'] as num?)?.toDouble(),
      colaboracionScore: (json['colaboracion_score'] as num?)?.toDouble(),
      tendencia: json['tendencia'] as String?,
    );
  }
}

class KpiProyectoResponse {
  final int proyectoId;
  final double avance;
  final int tareasTotales;
  final int tareasCompletadas;

  KpiProyectoResponse({
    required this.proyectoId,
    this.avance = 0.0,
    this.tareasTotales = 0,
    this.tareasCompletadas = 0,
  });

  factory KpiProyectoResponse.fromJson(Map<String, dynamic> json) {
    return KpiProyectoResponse(
      proyectoId: json['proyecto_id'] as int,
      avance: (json['avance'] as num?)?.toDouble() ?? 0.0,
      tareasTotales: json['tareas_totales'] as int? ?? 0,
      tareasCompletadas: json['tareas_completadas'] as int? ?? 0,
    );
  }
}

class KpiRiesgoResponse {
  final int proyectoId;
  final String? riesgo;
  final double? probabilidadRetraso;
  final Map<String, dynamic>? detalles;

  KpiRiesgoResponse({
    required this.proyectoId,
    this.riesgo,
    this.probabilidadRetraso,
    this.detalles,
  });

  factory KpiRiesgoResponse.fromJson(Map<String, dynamic> json) {
    return KpiRiesgoResponse(
      proyectoId: json['proyecto_id'] as int,
      riesgo: json['riesgo'] as String?,
      probabilidadRetraso: (json['probabilidad_retraso'] as num?)?.toDouble(),
      detalles: (json['detalles'] is Map)
          ? Map<String, dynamic>.from(json['detalles'] as Map)
          : null,
    );
  }
}

/// Endpoints: GET /kpis/estancia/{id}, /kpis/usuario/{id}, /kpis/proyecto/{id}, etc.
class KpisApi {
  KpisApi._();
  static final KpisApi _instance = KpisApi._();
  factory KpisApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<KpiEstanciaResponse> getKpisEstancia(int estanciaId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'kpis/estancia/$estanciaId',
    );
    if (response.data == null) throw Exception('Sin datos');
    return KpiEstanciaResponse.fromJson(response.data!);
  }

  Future<KpiUsuarioResponse> getKpisUsuario(
    int usuarioId,
    int estanciaId,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'kpis/usuario/$usuarioId',
      queryParameters: {'estancia_id': estanciaId},
    );
    if (response.data == null) throw Exception('Sin datos');
    return KpiUsuarioResponse.fromJson(response.data!);
  }

  Future<KpiProyectoResponse> getAvanceProyecto(int proyectoId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'kpis/proyecto/$proyectoId',
    );
    if (response.data == null) throw Exception('Sin datos');
    return KpiProyectoResponse.fromJson(response.data!);
  }

  Future<KpiRiesgoResponse> getRiesgoProyecto(int proyectoId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'kpis/proyecto/$proyectoId/riesgo',
    );
    if (response.data == null) throw Exception('Sin datos');
    return KpiRiesgoResponse.fromJson(response.data!);
  }
}
