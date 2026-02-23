import 'api_client.dart';

class AuditoriaEntry {
  final int id;
  final int? usuarioId;
  final String accion;
  final String? entidad;
  final int? entidadId;
  final String? nivel;
  final bool exitoso;
  final String? mensajeError;
  final Map<String, dynamic>? detalles;
  final String? ipAddress;
  final String? userAgent;
  final String? timestamp;

  AuditoriaEntry({
    required this.id,
    required this.usuarioId,
    required this.accion,
    required this.entidad,
    required this.entidadId,
    required this.nivel,
    required this.exitoso,
    required this.mensajeError,
    required this.detalles,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
  });

  factory AuditoriaEntry.fromJson(Map<String, dynamic> json) {
    return AuditoriaEntry(
      id: (json['id'] as num).toInt(),
      usuarioId: (json['usuario_id'] as num?)?.toInt(),
      accion: json['accion'] as String? ?? '',
      entidad: json['entidad'] as String?,
      entidadId: (json['entidad_id'] as num?)?.toInt(),
      nivel: json['nivel'] as String?,
      exitoso: json['exitoso'] as bool? ?? true,
      mensajeError: json['mensaje_error'] as String?,
      detalles: (json['detalles'] is Map) ? Map<String, dynamic>.from(json['detalles'] as Map) : null,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// Endpoint blueprint:
/// - GET /api/v1/auditoria (solo SUPER_ADMIN)
class AuditoriaApi {
  AuditoriaApi._();
  static final AuditoriaApi _instance = AuditoriaApi._();
  factory AuditoriaApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<AuditoriaEntry>> getAuditoria({
    int skip = 0,
    int limit = 100,
    int? usuarioId,
    String? accion,
    String? entidad,
    String? desde,
    String? hasta,
  }) async {
    final qp = <String, dynamic>{
      'skip': skip,
      'limit': limit,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (accion != null && accion.isNotEmpty) 'accion': accion,
      if (entidad != null && entidad.isNotEmpty) 'entidad': entidad,
      if (desde != null && desde.isNotEmpty) 'desde': desde,
      if (hasta != null && hasta.isNotEmpty) 'hasta': hasta,
    };
    final response = await _client.dio.get<List<dynamic>>('auditoria', queryParameters: qp);
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => AuditoriaEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

