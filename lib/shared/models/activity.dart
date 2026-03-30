import '../enums/activity_status.dart';

class ActivityModel {
  final int            id;
  final String         title;
  final String         description;
  final ActivityStatus status;
  final int            ownerId;
  final String         ownerName;
  final int?           assignedToId;
  final String?        assignedToName;
  final int?           assignedById;
  final String?        assignedByName;
  final int?           projectId;
  final String?        projectName;
  final int?           areaId;
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

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
    id:             json['id'] as int,
    title:          json['title'] as String,
    description:    json['description'] as String? ?? '',
    status:         ActivityStatus.fromString(json['status'] as String),
    ownerId:        json['owner'] as int,
    ownerName:      json['owner_name'] as String,
    assignedToId:   json['assigned_to'] as int?,
    assignedToName: json['assigned_to_name'] as String?,
    assignedById:   json['assigned_by'] as int?,
    assignedByName: json['assigned_by_name'] as String?,
    projectId:      json['project'] as int?,
    projectName:    json['project_name'] as String?,
    areaId:         json['area'] as int?,
    areaName:       json['area_name'] as String?,
    targetDate:     json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
    completedAt:    json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    createdAt:      DateTime.parse(json['created_at'] as String),
    updatedAt:      DateTime.parse(json['updated_at'] as String),
  );
}
