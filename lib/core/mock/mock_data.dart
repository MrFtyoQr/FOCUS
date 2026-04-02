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
    id: 'uuid-user-1', email: 'carlos@treetech.mx',
    firstName: 'Carlos', lastName: 'Mendoza',
    role: UserRole.adminArea,
    areaId: 'uuid-area-1', areaName: 'Desarrollo',
    onboardingCompleted: true,
  );

  /// Sesión mock de Super Admin (login con email que contenga `superadmin`, p. ej. `superadmin@treetech.mx`).
  static final superAdminUser = UserModel(
    id: 'uuid-superadmin-1',
    email: 'superadmin@treetech.mx',
    firstName: 'Patricia',
    lastName: 'Ruiz',
    role: UserRole.superAdmin,
    onboardingCompleted: true,
  );

  /// Cuenta solo uso personal (`MOCK_ACT_AS=personal` o login `personal@...`).
  static final personalOnlyUser = UserModel(
    id: 'uuid-personal-1',
    email: 'personal@ejemplo.com',
    firstName: 'Mia',
    lastName: 'Solo',
    role: UserRole.personal,
    onboardingCompleted: true,
  );

  /// Admins de área que el Super Admin gestiona en Equipo (uno por área en el mock).
  static final areaAdminsList = <UserModel>[
    currentUser,
    UserModel(
      id: 'uuid-aa-2',
      email: 'laura.martinez@treetech.mx',
      firstName: 'Laura',
      lastName: 'Martínez',
      role: UserRole.adminArea,
      areaId: 'uuid-area-2',
      areaName: 'Diseño',
      onboardingCompleted: true,
    ),
    UserModel(
      id: 'uuid-aa-3',
      email: 'sofia.aa@treetech.mx',
      firstName: 'Sofía',
      lastName: 'López',
      role: UserRole.adminArea,
      areaId: 'uuid-area-3',
      areaName: 'Marketing',
      onboardingCompleted: true,
    ),
  ];

  // ── Equipo ────────────────────────────────────────────────────────────────
  static final teamMembers = <UserModel>[
    currentUser,
    UserModel(id: 'uuid-user-2', email: 'ana@treetech.mx',     firstName: 'Ana',     lastName: 'García',   role: UserRole.trabajador, areaId: 'uuid-area-1', areaName: 'Desarrollo'),
    UserModel(id: 'uuid-user-3', email: 'luis@treetech.mx',    firstName: 'Luis',    lastName: 'Torres',   role: UserRole.trabajador, areaId: 'uuid-area-1', areaName: 'Desarrollo'),
    UserModel(id: 'uuid-user-4', email: 'maria@treetech.mx',   firstName: 'María',   lastName: 'Pérez',    role: UserRole.trabajador, areaId: 'uuid-area-1', areaName: 'Desarrollo'),
    UserModel(id: 'uuid-user-5', email: 'roberto@treetech.mx', firstName: 'Roberto', lastName: 'Sánchez',  role: UserRole.trabajador, areaId: 'uuid-area-2', areaName: 'Diseño'),
  ];

  // ── Actividades ───────────────────────────────────────────────────────────
  static List<ActivityModel> get activities => [
    ActivityModel(
      id: 'uuid-act-1', title: 'Revisar propuesta de cliente Gamma',
      description: 'Analizar requerimientos y enviar cotización al equipo de ventas.',
      status: ActivityStatus.bandeja,
      ownerId: 'uuid-user-1', ownerName: 'Carlos Mendoza',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    ActivityModel(
      id: 'uuid-act-2', title: 'Reunión de sincronía del equipo',
      description: 'Daily 10am — revisar blockers del sprint actual.',
      status: ActivityStatus.hoy,
      ownerId: 'uuid-user-1', ownerName: 'Carlos Mendoza',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 'uuid-act-3', title: 'Entregar reporte mensual de productividad',
      description: 'Incluir métricas del equipo y comparativa con mes anterior.',
      status: ActivityStatus.hoy,
      ownerId: 'uuid-user-2', ownerName: 'Ana García',
      assignedToId: 'uuid-user-1', assignedToName: 'Carlos Mendoza',
      assignedById: 'uuid-user-2', assignedByName: 'Ana García',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      projectId: 'uuid-proj-2', projectName: 'Dashboard Analytics',
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 3)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 'uuid-act-4', title: 'Code review — módulo de autenticación',
      description: 'Revisar PRs #47 y #49. Verificar manejo de JWT y refresh silencioso.',
      status: ActivityStatus.manana,
      ownerId: 'uuid-user-1', ownerName: 'Carlos Mendoza',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      projectId: 'uuid-proj-1', projectName: 'App Móvil v2.0',
      targetDate: _now.add(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now,
    ),
    ActivityModel(
      id: 'uuid-act-5', title: 'Diseñar mockups de pantalla de estadísticas',
      description: 'Figma: flujo de productividad individual y por área.',
      status: ActivityStatus.manana,
      ownerId: 'uuid-user-5', ownerName: 'Roberto Sánchez',
      assignedToId: 'uuid-user-5', assignedToName: 'Roberto Sánchez',
      assignedById: 'uuid-user-1', assignedByName: 'Carlos Mendoza',
      areaId: 'uuid-area-2', areaName: 'Diseño',
      projectId: 'uuid-proj-2', projectName: 'Dashboard Analytics',
      targetDate: _now.add(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now,
    ),
    ActivityModel(
      id: 'uuid-act-6', title: 'Preparar presentación Q2 para directivos',
      description: 'Slides con avance de proyectos, KPIs y próximos objetivos.',
      status: ActivityStatus.programado,
      ownerId: 'uuid-user-1', ownerName: 'Carlos Mendoza',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      targetDate: _now.add(const Duration(days: 7)),
      createdAt: _now.subtract(const Duration(days: 4)),
      updatedAt: _now.subtract(const Duration(days: 4)),
    ),
    ActivityModel(
      id: 'uuid-act-7', title: 'Fix: crash en pantalla de proyectos (Android)',
      description: 'NullPointerException al navegar con proyecto sin descripción.',
      status: ActivityStatus.pendientes,
      ownerId: 'uuid-user-3', ownerName: 'Luis Torres',
      assignedToId: 'uuid-user-1', assignedToName: 'Carlos Mendoza',
      assignedById: 'uuid-user-3', assignedByName: 'Luis Torres',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      projectId: 'uuid-proj-1', projectName: 'App Móvil v2.0',
      targetDate: _now.subtract(const Duration(days: 2)),
      createdAt: _now.subtract(const Duration(days: 5)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 'uuid-act-8', title: 'Configurar pipeline CI/CD en GitHub Actions',
      description: 'Build automático, tests y deploy a staging en cada PR.',
      status: ActivityStatus.completada,
      ownerId: 'uuid-user-1', ownerName: 'Carlos Mendoza',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      projectId: 'uuid-proj-3', projectName: 'API REST v3',
      completedAt: _now.subtract(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 6)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 'uuid-act-9',
      title: 'Actualizar wiki de onboarding',
      description: 'Checklist para nuevos ingresos al equipo (sin proyecto).',
      status: ActivityStatus.completada,
      ownerId: 'uuid-user-2', ownerName: 'Ana García',
      areaId: 'uuid-area-1', areaName: 'Desarrollo',
      completedAt: _now.subtract(const Duration(days: 2)),
      createdAt: _now.subtract(const Duration(days: 10)),
      updatedAt: _now.subtract(const Duration(days: 2)),
    ),
    // SA — solo tablero personal
    ActivityModel(
      id: 'uuid-act-sa-1',
      title: 'Revisión de contratos con proveedores',
      description: 'Tareas administrativas personales del SA.',
      status: ActivityStatus.bandeja,
      ownerId: superAdminUser.id,
      ownerName: superAdminUser.fullName,
      projectId: 'uuid-proj-sa-personal',
      projectName: 'Gestión directiva',
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now.subtract(const Duration(days: 1)),
    ),
    ActivityModel(
      id: 'uuid-act-sa-2',
      title: 'Llamada con inversionistas',
      description: 'Follow-up Q1.',
      status: ActivityStatus.hoy,
      ownerId: superAdminUser.id,
      ownerName: superAdminUser.fullName,
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now,
    ),
    // AA — proyecto personal (sin área)
    ActivityModel(
      id: 'uuid-act-aa-p1',
      title: 'Curso de liderazgo (personal)',
      description: 'Módulo 3 — feedback.',
      status: ActivityStatus.programado,
      ownerId: 'uuid-user-1',
      ownerName: 'Carlos Mendoza',
      projectId: 'uuid-proj-aa-personal',
      projectName: 'Desarrollo profesional',
      targetDate: _now.add(const Duration(days: 14)),
      createdAt: _now.subtract(const Duration(days: 3)),
      updatedAt: _now,
    ),
    // Cuenta personal
    ActivityModel(
      id: 'uuid-act-pers-1',
      title: 'Comprar regalos',
      description: 'Lista de cumpleaños.',
      status: ActivityStatus.bandeja,
      ownerId: personalOnlyUser.id,
      ownerName: personalOnlyUser.fullName,
      createdAt: _now,
      updatedAt: _now,
    ),
    ActivityModel(
      id: 'uuid-act-pers-2',
      title: 'Renovar gimnasio',
      description: '',
      status: ActivityStatus.hoy,
      ownerId: personalOnlyUser.id,
      ownerName: personalOnlyUser.fullName,
      targetDate: _now,
      createdAt: _now.subtract(const Duration(days: 1)),
      updatedAt: _now,
    ),
    ActivityModel(
      id: 'uuid-act-pers-3',
      title: 'Ordenar documentos fiscales',
      description: 'En carpeta del proyecto personal.',
      status: ActivityStatus.manana,
      ownerId: personalOnlyUser.id,
      ownerName: personalOnlyUser.fullName,
      projectId: 'uuid-proj-mia-personal',
      projectName: 'Mi organización',
      targetDate: _now.add(const Duration(days: 1)),
      createdAt: _now.subtract(const Duration(days: 2)),
      updatedAt: _now,
    ),
  ];

  // ── Proyectos ─────────────────────────────────────────────────────────────
  static final projects = <ProjectModel>[
    ProjectModel(
      id: 'uuid-proj-1', name: 'App Móvil v2.0',
      description: 'Rediseño completo con arquitectura Riverpod + GoRouter.',
      status: 'active',
      areaId: 'uuid-area-1',
      areaName: 'Desarrollo',
      areaAdminName: 'Carlos Mendoza',
      createdAt: _now.subtract(const Duration(days: 30)),
    ),
    ProjectModel(
      id: 'uuid-proj-2', name: 'Dashboard Analytics',
      description: 'Panel de métricas y KPIs en tiempo real para todos los roles.',
      status: 'active',
      areaId: 'uuid-area-1',
      areaName: 'Desarrollo',
      areaAdminName: 'Carlos Mendoza',
      createdAt: _now.subtract(const Duration(days: 15)),
    ),
    ProjectModel(
      id: 'uuid-proj-3', name: 'API REST v3',
      description: 'Migración y refactor completo del backend a Django + PostgreSQL.',
      status: 'active',
      areaId: 'uuid-area-1',
      areaName: 'Desarrollo',
      areaAdminName: 'Carlos Mendoza',
      createdAt: _now.subtract(const Duration(days: 60)),
    ),
    ProjectModel(
      id: 'uuid-proj-4',
      name: 'Identidad visual 2026',
      description: 'Manual de marca y componentes UI para rebranding.',
      status: 'active',
      areaId: 'uuid-area-2',
      areaName: 'Diseño',
      areaAdminName: 'Laura Martínez',
      createdAt: _now.subtract(const Duration(days: 10)),
    ),
    ProjectModel(
      id: 'uuid-proj-sa-personal',
      name: 'Gestión directiva',
      description: 'Proyectos personales del Super Admin (sin área asignada).',
      status: 'active',
      createdById: superAdminUser.id,
      createdAt: _now.subtract(const Duration(days: 20)),
      completedActivities: 0,
      totalActivities: 1,
    ),
    ProjectModel(
      id: 'uuid-proj-aa-personal',
      name: 'Desarrollo profesional',
      description: 'Proyecto personal del AA (sin vínculo a área).',
      status: 'active',
      createdById: 'uuid-user-1',
      createdAt: _now.subtract(const Duration(days: 60)),
      completedActivities: 0,
      totalActivities: 1,
    ),
    ProjectModel(
      id: 'uuid-proj-mia-personal',
      name: 'Mi organización',
      description: 'Proyecto personal de cuenta solo usuario.',
      status: 'active',
      createdById: personalOnlyUser.id,
      createdAt: _now.subtract(const Duration(days: 5)),
    ),
    ProjectModel(
      id: 'uuid-proj-ta-ana',
      name: 'Apuntes personales',
      description: 'Proyecto personal de Ana (TA).',
      status: 'active',
      createdById: 'uuid-user-2',
      createdAt: _now.subtract(const Duration(days: 12)),
    ),
  ];

  // ── Stats personales (trabajador) ────────────────────────────────────────
  static final myStats = <String, dynamic>{
    'total': 45,
    'completed': 38,
    'pending': 3,
    'overdue': 2,
    'completion_rate': 84.4,
    'avg_completion_days': 2.3,
  };

  /// Métricas de actividades **sin proyecto** para un `areaId` (misma regla que Productividad).
  static Map<String, int> orphanMetricsForArea(String areaId) {
    final list = activities
        .where((a) => a.isSinProyecto && a.areaId == areaId)
        .toList();
    final total = list.length;
    final completed = list.where((a) => a.isCompleted).length;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var overdue = 0;
    for (final a in list) {
      if (a.isCompleted) continue;
      final t = a.targetDate;
      if (t == null) continue;
      final td = DateTime(t.year, t.month, t.day);
      if (td.isBefore(today)) overdue++;
    }
    final pending = total - completed - overdue;
    return {
      'total': total,
      'completed': completed,
      'pending': pending < 0 ? 0 : pending,
      'overdue': overdue,
    };
  }

  /// Payload de `getAreaStats`: solo actividades de área **fuera de proyectos**.
  static Map<String, dynamic> buildAreaStatsForOrphans(String areaId) {
    final m = orphanMetricsForArea(areaId);
    final inArea = teamMembers.where((u) => u.areaId == areaId).toList();
    final areaName = inArea.isNotEmpty ? inArea.first.areaName ?? '' : '';
    final members = inArea.length;
    final tot = m['total']!;
    final comp = m['completed']!;
    return {
      'area_name': areaName,
      'members': members,
      'total': tot,
      'completed': comp,
      'pending': m['pending'],
      'overdue': m['overdue'],
      'completion_rate': tot == 0 ? 0.0 : comp / tot * 100,
    };
  }

  // ── Stats por trabajador (para adminArea) ─────────────────────────────────
  static final workerStats = <Map<String, dynamic>>[
    {
      'user_id': 'uuid-user-1', 'name': 'Carlos Mendoza', 'role': 'adminArea',
      'total': 20, 'completed': 17, 'pending': 2, 'overdue': 1,
      'completion_rate': 85.0,
    },
    {
      'user_id': 'uuid-user-2', 'name': 'Ana García', 'role': 'trabajador',
      'total': 18, 'completed': 15, 'pending': 2, 'overdue': 1,
      'completion_rate': 83.3,
    },
    {
      'user_id': 'uuid-user-3', 'name': 'Luis Torres', 'role': 'trabajador',
      'total': 22, 'completed': 19, 'pending': 3, 'overdue': 0,
      'completion_rate': 86.4,
    },
    {
      'user_id': 'uuid-user-4', 'name': 'María Pérez', 'role': 'trabajador',
      'total': 14, 'completed': 7, 'pending': 5, 'overdue': 2,
      'completion_rate': 50.0,
    },
  ];

  // ── Stats por área (superAdmin): mismos números que orphanMetricsForArea ──
  static List<Map<String, dynamic>> get allAreasStats {
    const meta = [
      {
        'area_id': 'uuid-area-1',
        'area_name': 'Desarrollo',
        'admin_name': 'Carlos Mendoza',
      },
      {
        'area_id': 'uuid-area-2',
        'area_name': 'Diseño',
        'admin_name': 'Roberto Sánchez',
      },
      {
        'area_id': 'uuid-area-3',
        'area_name': 'Marketing',
        'admin_name': 'Sofía López',
      },
      {
        'area_id': 'uuid-area-4',
        'area_name': 'Ventas',
        'admin_name': 'Diego Ramírez',
      },
    ];
    return meta.map((row) {
      final id = row['area_id']!;
      final m = orphanMetricsForArea(id);
      final members = teamMembers.where((u) => u.areaId == id).length;
      final tot = m['total']!;
      final comp = m['completed']!;
      return {
        ...row,
        'members': members,
        'total': tot,
        'completed': comp,
        'pending': m['pending'],
        'overdue': m['overdue'],
        'completion_rate': tot == 0 ? 0.0 : comp / tot * 100,
      };
    }).toList();
  }
}
