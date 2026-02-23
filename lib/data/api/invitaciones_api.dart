import 'package:dio/dio.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'estancias_api.dart';

/// Invitación con detalle (pendientes): incluye estancia_nombre e invitado_por.
class InvitacionConDetalle {
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
  final String? estanciaNombre;
  final UserResponse? invitadoPor;

  InvitacionConDetalle({
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
    this.estanciaNombre,
    this.invitadoPor,
  });

  factory InvitacionConDetalle.fromJson(Map<String, dynamic> json) {
    return InvitacionConDetalle(
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
      estanciaNombre: json['estancia_nombre'] as String?,
      invitadoPor: json['invitado_por'] != null
          ? UserResponse.fromJson(
              Map<String, dynamic>.from(json['invitado_por'] as Map),
            )
          : null,
    );
  }
}

/// Cliente API para invitaciones: pendientes, aceptar/rechazar, por-token.
class InvitacionesApi {
  InvitacionesApi._();
  static final InvitacionesApi _instance = InvitacionesApi._();
  factory InvitacionesApi() => _instance;

  final ApiClient _client = ApiClient();

  Future<List<InvitacionConDetalle>> listarPendientes() async {
    final response = await _client.dio.get<List<dynamic>>(
      'invitaciones/pendientes',
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .whereType<Map>()
        .map((e) => InvitacionConDetalle.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<InvitacionEstanciaResponse> aceptar(int invitacionId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'invitaciones/$invitacionId/aceptar',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return InvitacionEstanciaResponse.fromJson(response.data!);
  }

  Future<InvitacionEstanciaResponse> rechazar(int invitacionId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'invitaciones/$invitacionId/rechazar',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return InvitacionEstanciaResponse.fromJson(response.data!);
  }

  /// GET /invitaciones/por-token/{token} — no requiere auth (para mostrar página del link).
  Future<Map<String, dynamic>> getPorToken(String token) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'invitaciones/por-token/$token',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return response.data!;
  }

  /// POST /invitaciones/por-token/{token}/aceptar — requiere usuario autenticado.
  Future<InvitacionEstanciaResponse> aceptarPorToken(String token) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'invitaciones/por-token/$token/aceptar',
    );
    if (response.data == null)
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Sin datos',
      );
    return InvitacionEstanciaResponse.fromJson(response.data!);
  }
}
