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

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id:             json['id'] as String,
    title:          (json['title'] ?? '') as String,
    description:    (json['description'] ?? '') as String,
    status:         ActivityStatus.fromString(
                      (json['status'] ?? 'inbox') as String),
    ownerId:        (json['owner'] ?? '') as String,
    ownerName:      (json['owner_name'] ?? '') as String,
    assignedToId:   json['assigned_to'] as String?,
    assignedToName: json['assigned_to_name'] as String?,
    assignedById:   json['assigned_by'] as String?,
    assignedByName: json['assigned_by_name'] as String?,
    projectId:      json['project'] as String?,
    projectName:    json['project_name'] as String?,
    areaId:         json['area'] as String?,
    areaName:       json['area_name'] as String?,
    targetDate:     json['target_date'] != null
        ? DateTime.tryParse(json['target_date'] as String) : null,
    completedAt:    json['completed_at'] != null
        ? DateTime.tryParse(json['completed_at'] as String) : null,
    createdAt:  DateTime.parse(json['created_at'] as String),
    updatedAt:  DateTime.parse(json['updated_at'] as String),
  );
}
