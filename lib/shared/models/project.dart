class ProjectModel {
  final String  id;
  final String  name;
  final String  description;
  final String? status;
  final String? targetDate;
  final String? areaId;
  final String? areaName;
  /// Administrador de área asignado (líder del equipo del proyecto).
  final String? areaAdminName;
  /// Quién creó el proyecto (proyectos personales por usuario).
  final String? createdById;
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
    this.areaAdminName,
    this.createdById,
    required this.createdAt,
    this.color               = '#7F77DD',
    this.progress            = 0.0,
    this.completedActivities = 0,
    this.totalActivities     = 0,
  });

  static String? _idOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) return value['id'] as String?;
    return null;
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id:          json['id'] as String,
    name:        (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    status:      json['status'] as String?,
    targetDate:  json['target_date'] as String?,
    areaId:      _idOrNull(json['area']),
    areaName:    json['area_name'] as String? ??
        (json['area'] is Map
            ? (json['area'] as Map)['name'] as String?
            : null),
    areaAdminName: json['area_admin_name'] as String?,
    createdById: _idOrNull(json['created_by']),
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
    if (areaId != null)         'area':        areaId,
    if (areaAdminName != null)  'area_admin_name': areaAdminName,
    if (createdById != null)    'created_by':      createdById,
  };

  ProjectModel copyWith({
    String? areaName,
    String? areaAdminName,
  }) {
    return ProjectModel(
      id: id,
      name: name,
      description: description,
      status: status,
      targetDate: targetDate,
      areaId: areaId,
      areaName: areaName ?? this.areaName,
      areaAdminName: areaAdminName ?? this.areaAdminName,
      createdById: createdById,
      createdAt: createdAt,
      color: color,
      progress: progress,
      completedActivities: completedActivities,
      totalActivities: totalActivities,
    );
  }
}
