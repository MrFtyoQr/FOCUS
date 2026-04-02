import '../../shared/models/project.dart';

/// Proyecto de área / asignado a un AA (`areaId` presente).
bool isTeamProject(ProjectModel p) =>
    p.areaId != null && p.areaId!.trim().isNotEmpty;

/// Proyecto personal (sin área ni AA asignado).
bool isPersonalProject(ProjectModel p) => !isTeamProject(p);

/// Mapa id → proyecto para resolver actividades.
Map<String, ProjectModel> projectMap(Iterable<ProjectModel> projects) =>
    {for (final p in projects) p.id: p};
