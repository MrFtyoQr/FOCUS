import '../../shared/models/activity.dart';
import '../../shared/models/project.dart';
import '../../shared/models/user.dart';
import '../../shared/enums/activity_status.dart';
import '../../shared/enums/user_role.dart';

class MockData {
  MockData._();

  static final _now = DateTime.now();

  // ── Usuario actual ────────────────────────────────────────────────────────
  static final currentUser = UserModel(
    id: 1, email: 'carlos@treetech.mx',
    firstName: 'Carlos', lastName: 'Mendoza',
    role: UserRole.adminArea,
    areaId: 1, areaName: 'Desarrollo',
    onboardingCompleted: true,
  );

  // ── Equipo ────────────────────────────────────────────────────────────────
  static final teamMembers = <UserModel>[
    currentUser,
    UserModel(id: 2, email: 'ana@treetech.mx', firstName: 'Ana',     lastName: 'García',   role: UserRole.trabajador, areaId: 1, areaName: 'Desarrollo'),
    UserModel(id: 3, email: 'luis@treetech.mx', firstName: 'Luis',   lastName: 'Torres',   role: UserRole.trabajador, areaId: 1, areaName: 'Desarrollo'),
    UserModel(id: 4, email: 'maria@treetech.mx', firstName: 'María', lastName: 'Pérez',    role: UserRole.trabajador, areaId: 1, areaName: 'Desarrollo'),
    UserModel(id: 5, email: 'roberto@treetech.mx', firstName: 'Roberto', lastName: 'Sánchez', role: UserRole.trabajador, areaId: 2, areaName: 'Diseño'),
  ];

  // ── Actividades ───────────────────────────────────────────────────────────
  static List<ActivityModel> get activities => [
    ActivityModel(
      id: 1, title: 'Revisar propuesta de cliente Gamma',
      description: 'Analizar requerimientos y enviar cotización al equipo de ventas.',
      status: ActivityStatus.bandeja,
      ownerId: 1, ownerName: 'Carlos Mendoza',
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    ActivityModel(
      id: 2, title: 'Reunión de sincronía del equipo',
      description: 'Daily 10am — revisar blockers del sprint actual.',
      status: ActivityStatus.hoy,
      ownerId: 1, ownerName: 'Carlos Mendoza',
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 3, title: 'Entregar reporte mensual de productividad',
      description: 'Incluir métricas del equipo y comparativa con mes anterior.',
      status: ActivityStatus.hoy,
      ownerId: 2, ownerName: 'Ana García',
      assignedToId: 1, assignedToName: 'Carlos Mendoza',
      assignedById: 2, assignedByName: 'Ana García',
      projectId: 2, projectName: 'Dashboard Analytics',
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 3)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 4, title: 'Code review — módulo de autenticación',
      description: 'Revisar PRs #47 y #49. Verificar manejo de JWT y refresh silencioso.',
      status: ActivityStatus.manana,
      ownerId: 1, ownerName: 'Carlos Mendoza',
      projectId: 1, projectName: 'App Móvil v2.0',
      targetDate: _now.add(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now,
    ),
    ActivityModel(
      id: 5, title: 'Diseñar mockups de pantalla de estadísticas',
      description: 'Figma: flujo de productividad individual y por área. Entregar a dev.',
      status: ActivityStatus.manana,
      ownerId: 5, ownerName: 'Roberto Sánchez',
      assignedToId: 5, assignedToName: 'Roberto Sánchez',
      assignedById: 1, assignedByName: 'Carlos Mendoza',
      projectId: 2, projectName: 'Dashboard Analytics',
      targetDate: _now.add(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now,
    ),
    ActivityModel(
      id: 6, title: 'Preparar presentación Q2 para directivos',
      description: 'Slides con avance de proyectos, KPIs y próximos objetivos del trimestre.',
      status: ActivityStatus.programado,
      ownerId: 1, ownerName: 'Carlos Mendoza',
      targetDate: _now.add(const Duration(days: 7)),
      createdAt: _now.subtract(const Duration(days: 4)),
      updatedAt: _now.subtract(const Duration(days: 4)),
    ),
    ActivityModel(
      id: 7, title: 'Fix: crash en pantalla de proyectos (Android)',
      description: 'NullPointerException al navegar con proyecto sin descripción asignada.',
      status: ActivityStatus.pendientes,
      ownerId: 3, ownerName: 'Luis Torres',
      assignedToId: 1, assignedToName: 'Carlos Mendoza',
      assignedById: 3, assignedByName: 'Luis Torres',
      projectId: 1, projectName: 'App Móvil v2.0',
      targetDate: _now.subtract(const Duration(days: 2)),
      createdAt: _now.subtract(const Duration(days: 5)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 8, title: 'Configurar pipeline CI/CD en GitHub Actions',
      description: 'Build automático, tests y deploy a staging en cada PR.',
      status: ActivityStatus.completada,
      ownerId: 1, ownerName: 'Carlos Mendoza',
      projectId: 3, projectName: 'API REST v3',
      completedAt: _now.subtract(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 6)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 9, title: 'Documentar endpoints de autenticación',
      description: 'Swagger/OpenAPI para login, refresh, logout y /me.',
      status: ActivityStatus.completada,
      ownerId: 3, ownerName: 'Luis Torres',
      projectId: 3, projectName: 'API REST v3',
      completedAt: _now.subtract(const Duration(days: 3)),
      createdAt: _now.subtract(const Duration(days: 8)),
      updatedAt: _now.subtract(const Duration(days: 3)),
    ),
  ];

  // ── Proyectos ─────────────────────────────────────────────────────────────
  static final projects = <ProjectModel>[
    ProjectModel(
      id: 1, name: 'App Móvil v2.0',
      description: 'Rediseño completo con arquitectura Riverpod + GoRouter.',
      color: '#7F77DD',
      ownerId: 1, ownerName: 'Carlos Mendoza',
      areaId: 1, areaName: 'Desarrollo',
      totalActivities: 15, completedActivities: 9,
      createdAt: _now.subtract(const Duration(days: 30)),
    ),
    ProjectModel(
      id: 2, name: 'Dashboard Analytics',
      description: 'Panel de métricas y KPIs en tiempo real para todos los roles.',
      color: '#1D9E75',
      ownerId: 2, ownerName: 'Ana García',
      areaId: 1, areaName: 'Desarrollo',
      totalActivities: 10, completedActivities: 3,
      createdAt: _now.subtract(const Duration(days: 15)),
    ),
    ProjectModel(
      id: 3, name: 'API REST v3',
      description: 'Migración y refactor completo del backend a FastAPI + PostgreSQL.',
      color: '#378ADD',
      ownerId: 3, ownerName: 'Luis Torres',
      areaId: 1, areaName: 'Desarrollo',
      totalActivities: 20, completedActivities: 17,
      createdAt: _now.subtract(const Duration(days: 60)),
    ),
  ];

  // ── Stats personales ──────────────────────────────────────────────────────
  static final myStats = <String, dynamic>{
    'total': 45,
    'completed': 38,
    'pending': 3,
    'overdue': 2,
    'completion_rate': 84.4,
    'avg_completion_days': 2.3,
  };

  // ── Stats de área (para adminArea) ────────────────────────────────────────
  static final areaStats = <String, dynamic>{
    'area_name': 'Desarrollo',
    'members': 4,
    'total': 74,
    'completed': 58,
    'pending': 10,
    'overdue': 6,
    'completion_rate': 78.4,
  };

  // ── Stats por trabajador (para adminArea) ─────────────────────────────────
  static final workerStats = <Map<String, dynamic>>[
    {
      'user_id': 1, 'name': 'Carlos Mendoza', 'role': 'adminArea',
      'total': 20, 'completed': 17, 'pending': 2, 'overdue': 1,
      'completion_rate': 85.0,
    },
    {
      'user_id': 2, 'name': 'Ana García', 'role': 'trabajador',
      'total': 18, 'completed': 15, 'pending': 2, 'overdue': 1,
      'completion_rate': 83.3,
    },
    {
      'user_id': 3, 'name': 'Luis Torres', 'role': 'trabajador',
      'total': 22, 'completed': 19, 'pending': 3, 'overdue': 0,
      'completion_rate': 86.4,
    },
    {
      'user_id': 4, 'name': 'María Pérez', 'role': 'trabajador',
      'total': 14, 'completed': 7, 'pending': 5, 'overdue': 2,
      'completion_rate': 50.0,
    },
  ];

  // ── Stats por área (para superAdmin) ─────────────────────────────────────
  static final allAreasStats = <Map<String, dynamic>>[
    {
      'area_id': 1, 'area_name': 'Desarrollo',
      'admin_name': 'Carlos Mendoza',
      'members': 4, 'total': 74, 'completed': 58, 'overdue': 6,
      'completion_rate': 78.4,
    },
    {
      'area_id': 2, 'area_name': 'Diseño',
      'admin_name': 'Roberto Sánchez',
      'members': 3, 'total': 35, 'completed': 28, 'overdue': 3,
      'completion_rate': 80.0,
    },
    {
      'area_id': 3, 'area_name': 'Marketing',
      'admin_name': 'Sofía López',
      'members': 5, 'total': 52, 'completed': 34, 'overdue': 9,
      'completion_rate': 65.4,
    },
    {
      'area_id': 4, 'area_name': 'Ventas',
      'admin_name': 'Diego Ramírez',
      'members': 6, 'total': 90, 'completed': 81, 'overdue': 2,
      'completion_rate': 90.0,
    },
  ];
}
