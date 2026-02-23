import 'api_client.dart';

/// DTO alineado al backend (retroalimentacion_schemas).
class RetroalimentacionResponse {
  final int id;
  final int estanciaId;
  final int? proyectoId;
  final int? emisorId;
  final int receptorId;
  final String tipo;
  final bool anonima;
  final String contenido;
  final int? calificacion;
  final String? fechaCreacion;

  RetroalimentacionResponse({
    required this.id,
    required this.estanciaId,
    this.proyectoId,
    this.emisorId,
    required this.receptorId,
    required this.tipo,
    required this.anonima,
    required this.contenido,
    this.calificacion,
    this.fechaCreacion,
  });

  factory RetroalimentacionResponse.fromJson(Map<String, dynamic> json) {
    return RetroalimentacionResponse(
      id: json['id'] as int,
      estanciaId: json['estancia_id'] as int,
      proyectoId: json['proyecto_id'] as int?,
      emisorId: json['emisor_id'] as int?,
      receptorId: json['receptor_id'] as int,
      tipo: json['tipo'] as String? ?? '',
      anonima: json['anonima'] as bool? ?? false,
      contenido: json['contenido'] as String? ?? '',
      calificacion: json['calificacion'] as int?,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }
}

/// Endpoints: GET /retroalimentacion?estancia_id=, GET /retroalimentacion/{id}, POST /retroalimentacion.
class RetroalimentacionApi {
  RetroalimentacionApi._();
  static final RetroalimentacionApi _instance = RetroalimentacionApi._();
  factory RetroalimentacionApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<RetroalimentacionResponse>> listByEstancia({
    required int estanciaId,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      'retroalimentacion',
      queryParameters: {
        'estancia_id': estanciaId,
        'skip': skip,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map(
          (e) =>
              RetroalimentacionResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<RetroalimentacionResponse> getById(int retroId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'retroalimentacion/$retroId',
    );
    if (response.data == null) throw Exception('Sin datos');
    return RetroalimentacionResponse.fromJson(response.data!);
  }
}
