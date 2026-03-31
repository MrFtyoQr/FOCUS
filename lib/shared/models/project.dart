class ProjectModel {
  final String  id;
  final String  name;
  final String  description;
  final String? status;
  final String? targetDate;
  final String? areaId;
  final String? areaName;
  final DateTime createdAt;

  // Campos de progreso (provistos por el backend o calculados localmente)
  final String color;
  final double progress;
  final int    completedActivities;
  final int    totalActivities;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    this.status,
    this.targetDate,
    this.areaId,
    this.areaName,
    required this.createdAt,
    this.color               = '#7F77DD',
    this.progress            = 0.0,
    this.completedActivities = 0,
    this.totalActivities     = 0,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id:          json['id'] as String,
    name:        (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    status:      json['status'] as String?,
    targetDate:  json['target_date'] as String?,
    areaId:      json['area'] as String?,
    areaName:    json['area_name'] as String?,
    createdAt:   DateTime.parse(json['created_at'] as String),
    color:               (json['color'] as String?)        ?? '#7F77DD',
    progress:            (json['progress'] as num?)?.toDouble() ?? 0.0,
    completedActivities: (json['completed_activities'] as int?) ?? 0,
    totalActivities:     (json['total_activities'] as int?)     ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
    if (status != null)     'status':      status,
    if (targetDate != null) 'target_date': targetDate,
    if (areaId != null)     'area':        areaId,
  };
}
