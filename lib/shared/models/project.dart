class ProjectModel {
  final int     id;
  final String  name;
  final String  description;
  final String  color;
  final int     ownerId;
  final String  ownerName;
  final int?    areaId;
  final String? areaName;
  final int     totalActivities;
  final int     completedActivities;
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.ownerId,
    required this.ownerName,
    this.areaId,
    this.areaName,
    required this.totalActivities,
    required this.completedActivities,
    required this.createdAt,
  });

  double get progress => totalActivities == 0 ? 0 : completedActivities / totalActivities;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id:                  json['id'] as int,
    name:                json['name'] as String,
    description:         json['description'] as String? ?? '',
    color:               json['color'] as String? ?? '#7F77DD',
    ownerId:             json['owner'] as int,
    ownerName:           json['owner_name'] as String,
    areaId:              json['area'] as int?,
    areaName:            json['area_name'] as String?,
    totalActivities:     json['total_activities'] as int? ?? 0,
    completedActivities: json['completed_activities'] as int? ?? 0,
    createdAt:           DateTime.parse(json['created_at'] as String),
  );
}
