import '../enums/activity_status.dart';

class ActivityModel {
  final String         id;
  final String         title;
  final String         description;
  final ActivityStatus status;
  final String         ownerId;
  final String         ownerName;
  final String?        assignedToId;
  final String?        assignedToName;
  final String?        assignedById;
  final String?        assignedByName;
  final String?        projectId;
  final String?        projectName;
  final String?        areaId;
  final String?        areaName;
  final DateTime?      targetDate;
  final DateTime?      completedAt;
  final DateTime       createdAt;
  final DateTime       updatedAt;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    this.assignedToId,
    this.assignedToName,
    this.assignedById,
    this.assignedByName,
    this.projectId,
    this.projectName,
    this.areaId,
    this.areaName,
    this.targetDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAssigned  => assignedById != null;
  bool get isCompleted => status == ActivityStatus.completada;

  /// Sin proyecto enlazado (independientes / fuera de proyectos).
  bool get isSinProyecto =>
      projectId == null || projectId!.isEmpty;

  /// El backend puede devolver campos relacionales como UUID plano
  /// o como objeto anidado `{"id": "...", "full_name": "..."}`.
  /// Este helper extrae el id en ambos casos.
  static String? _id(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map)   return v['id'] as String?;
    return null;
  }

  /// Extrae el nombre de un objeto anidado (`full_name`) o devuelve
  /// el valor plano si ya es un String. Si no hay nada, usa [fallback].
  static String? _name(dynamic nested, dynamic flat, {String? key = 'full_name'}) {
    if (flat is String && flat.isNotEmpty) return flat;
    if (nested is Map) return (nested[key] ?? nested['name']) as String?;
    return null;
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id:             json['id'] as String,
    title:          (json['title'] ?? '') as String,
    description:    (json['description'] ?? '') as String,
    status:         ActivityStatus.fromString(
                      (json['status'] ?? 'inbox') as String),
    // El backend puede devolver el campo como objeto anidado {id, ...}
    // o como campo plano "owner_id", "project_id", etc.
    ownerId:        _id(json['owner'])       ?? (json['owner_id']       as String?) ?? '',
    ownerName:      _name(json['owner'], json['owner_name'])             ?? '',
    assignedToId:   _id(json['assigned_to']) ?? (json['assigned_to_id'] as String?),
    assignedToName: _name(json['assigned_to'], json['assigned_to_name']),
    assignedById:   _id(json['assigned_by']) ?? (json['assigned_by_id'] as String?),
    assignedByName: _name(json['assigned_by'], json['assigned_by_name']),
    projectId:      _id(json['project'])     ?? (json['project_id']     as String?),
    projectName:    _name(json['project'], json['project_name'], key: 'name'),
    areaId:         _id(json['area'])        ?? (json['area_id']        as String?),
    areaName:       _name(json['area'], json['area_name'], key: 'name'),
    targetDate:     json['target_date'] != null
        ? DateTime.tryParse(json['target_date'] as String) : null,
    completedAt:    json['completed_at'] != null
        ? DateTime.tryParse(json['completed_at'] as String) : null,
    createdAt:  DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    updatedAt:  DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}
