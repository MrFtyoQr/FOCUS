class AreaModel {
  final String  id;
  final String  name;
  final String  description;
  final String  createdBy;
  final DateTime createdAt;

  const AreaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) => AreaModel(
    id:          json['id'] as String,
    name:        (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    createdBy:   (json['created_by'] ?? '') as String,
    createdAt:   DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name':        name,
    'description': description,
  };
}
