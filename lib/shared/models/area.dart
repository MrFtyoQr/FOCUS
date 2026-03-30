class AreaModel {
  final int     id;
  final String  name;
  final String  description;
  final int     adminId;
  final String  adminName;
  final int     membersCount;

  const AreaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.adminName,
    required this.membersCount,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
    id:           json['id'] as int,
    name:         (json['name'] ?? json['nombre'] ?? '') as String,
    description:  (json['description'] ?? json['descripcion'] ?? '') as String,
    adminId:      (json['admin'] ?? json['admin_id'] ?? 0) as int,
    adminName:    (json['admin_name'] ?? '') as String,
    membersCount: (json['members_count'] ?? 0) as int,
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
  };
}
