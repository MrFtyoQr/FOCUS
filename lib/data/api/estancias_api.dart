import 'package:dio/dio.dart';
import 'api_client.dart';

/// DTOs alineados al backend (estancia_schemas, solicitud_schemas, invitacion_schemas).
class EstanciaResponse {
  final int id;
  final String nombre;
  final String? descripcion;
  final int propietarioId;
  final bool activa;
  final String? fechaCreacion;

  EstanciaResponse({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.propietarioId,
    required this.activa,
    this.fechaCreacion,
  });

  factory EstanciaResponse.fromJson(Map<String, dynamic> json) {
    return EstanciaResponse(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      propietarioId: json['propietario_id'] as int,
      activa: json['activa'] as bool? ?? true,
      fechaCreacion: json['fecha_creacion'] as String?,
    );
  }
}

class SolicitudEstanciaResponse {
  final int id;
  final int usuarioId;
  final int estanciaId;
  final String estado;
  final String? mensaje;
  final String? fechaCreacion;
  final String? fechaResolucion;
  final int? resueltoPorId;

  SolicitudEstanciaResponse({
    required this.id,
    required this.usuarioId,
    required this.estanciaId,
    required this.estado,
    this.mensaje,
    this.fechaCreacion,
    this.fechaResolucion,
    this.resueltoPorId,
  });

  factory SolicitudEstanciaResponse.fromJson(Map<String, dynamic> json) {
    return SolicitudEstanciaResponse(
      id: json['id'] as int,
      usuarioId: json['usuario_id'] as int,
      estanciaId: json['estancia_id'] as int,
      estado: json['estado'] as String,
      mensaje: json['mensaje'] as String?,
      fechaCreacion: json['fecha_creacion'] as String?,
      fechaResolucion: json['fecha_resolucion'] as String?,
      resueltoPorId: json['resuelto_por_id'] as int?,
    );
  }
}

class MiembroEstanciaResponse {
  final int usuarioId;
  final String nombre;
  final String email;
  final String? apellido;
  final String rolEnEstancia;
  final String? fechaIngreso;

  MiembroEstanciaResponse({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    this.apellido,
    required this.rolEnEstancia,
    this.fechaIngreso,
  });

  factory MiembroEstanciaResponse.fromJson(Map<String, dynamic> json) {
    return MiembroEstanciaResponse(
      usuarioId: json['usuario_id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      apellido: json['apellido'] as String?,
      rolEnEstancia: json['rol_en_estancia'] as String,
      fechaIngreso: json['fecha_ingreso'] as String?,
    );
  }
}

class InvitacionEstanciaResponse {
  final int id;
  final int estanciaId;
  final int invitadoPorId;
  final int usuarioInvitadoId;
  final String estado;
  final String? mensaje;
  final String rolAsignado;
  final String? fechaCreacion;
  final String? fechaResolucion;
  final String? token;

  InvitacionEstanciaResponse({
    required this.id,
    required this.estanciaId,
    required this.invitadoPorId,
    required this.usuarioInvitadoId,
    required this.estado,
    this.mensaje,
    required this.rolAsignado,
    this.fechaCreacion,
    this.fechaResolucion,
    this.token,
  });

  factory InvitacionEstanciaResponse.fromJson(Map<String, dynamic> json) {
    return InvitacionEstanciaResponse(
      id: json['id'] as int,
      estanciaId: json['estancia_id'] as int,
      invitadoPorId: json['invitado_por_id'] as int,
      usuarioInvitadoId: json['usuario_invitado_id'] as int,
      estado: json['estado'] as String,
      mensaje: json['mensaje'] as String?,
      rolAsignado: json['rol_asignado'] as String? ?? 'miembro',
      fechaCreacion: json['fecha_creacion'] as String?,
      fechaResolucion: json['fecha_resolucion'] as String?,
      token: json['token'] as String?,
    );
  }
}

/// Cliente API para estancias (GET/POST/PUT/DELETE, solicitudes, códigos, invitar, miembros).
class EstanciasApi {
  EstanciasApi._();
  static final EstanciasApi _instance = EstanciasApi._();
  factory EstanciasApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<EstanciaResponse>> list({int skip = 0, int limit = 100}) async {
    final response = await _client.dio.get<List<dynamic>>(
      'estancias',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => EstanciaResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<EstanciaResponse> get(int estanciaId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'estancias/$estanciaId',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return EstanciaResponse.fromJson(response.data!);
  }

  Future<EstanciaResponse> create({
    required String nombre,
    String? descripcion,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias',
      data: {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
      },
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return EstanciaResponse.fromJson(response.data!);
  }

  Future<EstanciaResponse> update(
    int estanciaId, {
    String? nombre,
    String? descripcion,
  }) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      'estancias/$estanciaId',
      data: {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
      },
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return EstanciaResponse.fromJson(response.data!);
  }

  Future<void> delete(int estanciaId) async {
    await _client.dio.delete('estancias/$estanciaId');
  }

  Future<SolicitudEstanciaResponse> unirsePorCodigo(String codigo) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias/unirse-por-codigo',
      data: {'codigo': codigo},
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return SolicitudEstanciaResponse.fromJson(response.data!);
  }

  Future<SolicitudEstanciaResponse> solicitarAcceso(
    int estanciaId, {
    String? mensaje,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/estancias/$estanciaId/solicitar-acceso',
      data: mensaje != null ? {'mensaje': mensaje} : null,
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return SolicitudEstanciaResponse.fromJson(response.data!);
  }

  Future<List<SolicitudEstanciaResponse>> listarSolicitudes(
    int estanciaId,
  ) async {
    final response = await _client.dio.get<List<dynamic>>(
      'estancias/$estanciaId/solicitudes',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map(
          (e) =>
              SolicitudEstanciaResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<SolicitudEstanciaResponse> aceptarSolicitud(
    int estanciaId,
    int solicitudId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias/$estanciaId/solicitudes/$solicitudId/aceptar',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return SolicitudEstanciaResponse.fromJson(response.data!);
  }

  Future<SolicitudEstanciaResponse> rechazarSolicitud(
    int estanciaId,
    int solicitudId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias/$estanciaId/solicitudes/$solicitudId/rechazar',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return SolicitudEstanciaResponse.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> generarCodigo(int estanciaId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias/$estanciaId/codigos',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return response.data!;
  }

  Future<InvitacionEstanciaResponse> invitar(
    int estanciaId, {
    required int usuarioInvitadoId,
    String? mensaje,
    String rolAsignado = 'miembro',
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'estancias/$estanciaId/invitar',
      data: {
        'usuario_invitado_id': usuarioInvitadoId,
        if (mensaje != null) 'mensaje': mensaje,
        'rol_asignado': rolAsignado,
      },
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return InvitacionEstanciaResponse.fromJson(response.data!);
  }

  Future<List<MiembroEstanciaResponse>> listarMiembros(int estanciaId) async {
    final response = await _client.dio.get<List<dynamic>>(
      'estancias/$estanciaId/miembros',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map(
          (e) => MiembroEstanciaResponse.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> eliminarMiembro(int estanciaId, int userId) async {
    await _client.dio.delete('estancias/$estanciaId/miembros/$userId');
  }

  Future<MiembroEstanciaResponse> cambiarRolMiembro(
    int estanciaId,
    int userId,
    String rolEnEstancia,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      'estancias/$estanciaId/miembros/$userId',
      data: {'rol_en_estancia': rolEnEstancia},
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return MiembroEstanciaResponse.fromJson(response.data!);
  }
}
