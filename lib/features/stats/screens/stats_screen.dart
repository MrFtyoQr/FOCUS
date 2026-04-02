import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../projects/providers/projects_provider.dart';
import '../../../shared/enums/user_role.dart';
import '../../../core/utils/activity_scope.dart';
import '../../../core/utils/project_kind.dart';
import '../../../shared/enums/activity_status.dart';
import '../../../shared/models/activity.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/activity_status_colors.dart';
import '../../../core/utils/paleta_pasteles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/responsive.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return switch (user.role) {
      UserRole.superAdmin => const _SuperAdminStats(),
      UserRole.adminArea => const _AdminAreaStats(),
      UserRole.trabajador => const _WorkerProductividadScreen(),
      UserRole.personal => const _WorkerProductividadScreen(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paleta pastel (misma intención que el legacy ProductividadScreen).
// ─────────────────────────────────────────────────────────────────────────────
class _ProductividadColors {
  static const metricHoyLight = Color(0xFF4F7FD1);
  static const metricSemanaLight = Color(0xFF4DAA72);
  static const metricTotalLight = Color(0xFF8C6BCB);
  static const metricHoyDark = Color(0xFF8FB4E0);
  static const metricSemanaDark = Color(0xFFA8DCC8);
  static const metricTotalDark = Color(0xFFC4B8E8);
  static const metricCardBgHoyLight = Color(0xFFF2F6FC);
  static const metricCardBgSemanaLight = Color(0xFFF2F8F4);
  static const metricCardBgTotalLight = Color(0xFFF5F2FA);
  static const sectionCardLight = Color(0xFFF7F7F7);
  static const alertBgLight = Color(0xFFF7E7B5);
  static const alertAccentLight = Color(0xFFD4A03A);
  static const alertTextLight = Color(0xFF5A4622);
  static const alertBgDark = Color(0xFFF5E6D4);
  static const alertAccentDark = Color(0xFFD4A574);
  static const alertTextDark = Color(0xFF4A3428);
}

/// Solo actividades sin proyecto (`projectId` nulo o vacío).
List<ActivityModel> personalActivities(List<ActivityModel> todas) =>
    todas.where((a) => a.isSinProyecto).toList();

/// Actividades del área que no están dentro de un proyecto.
List<ActivityModel> areaActivitiesSinProyecto(
  List<ActivityModel> todas,
  String areaId,
) {
  if (areaId.isEmpty) return [];
  return todas
      .where((a) => a.isSinProyecto && a.areaId == areaId)
      .toList();
}

String _initialName(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t[0].toUpperCase();
}

/// Color del anillo / barra según tasa (paleta de estados).
Color _productividadRateColor(BuildContext context, double rate) {
  final b = Theme.of(context).brightness;
  if (rate >= 80) {
    return ActivityStatusColors.forStatus(
      ActivityStatus.completada,
      brightness: b,
    );
  }
  if (rate >= 60) {
    return ActivityStatusColors.forStatus(
      ActivityStatus.manana,
      brightness: b,
    );
  }
  return ActivityStatusColors.forStatus(
    ActivityStatus.pendientes,
    brightness: b,
  );
}

int _countOverdueActivities(List<ActivityModel> list) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return list.where((a) {
    if (a.isCompleted) return false;
    final t = a.targetDate;
    if (t == null) return false;
    final td = DateTime(t.year, t.month, t.day);
    return td.isBefore(today);
  }).length;
}

Map<String, dynamic> _computeProductividadMetricas(
  List<ActivityModel> todasActividades,
) {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final inicioSemana =
        inicioDia.subtract(Duration(days: ahora.weekday - 1));

    final completadasHoy = todasActividades.where((a) {
      if (a.status != ActivityStatus.completada) return false;
      final t = a.completedAt ?? a.updatedAt;
      return !t.isBefore(inicioDia);
    }).length;

    final completadasSemana = todasActividades.where((a) {
      if (a.status != ActivityStatus.completada) return false;
      final t = a.completedAt ?? a.updatedAt;
      return !t.isBefore(inicioSemana);
    }).length;

    final porEstado = <ActivityStatus, int>{};
    for (final estado in ActivityStatus.values) {
      porEstado[estado] =
          todasActividades.where((a) => a.status == estado).length;
    }

    final deadlineProximo = ahora.add(const Duration(days: 3));
    final deadlinesProximos = todasActividades.where((a) {
      final f = a.targetDate;
      return f != null &&
          f.isAfter(ahora) &&
          f.isBefore(deadlineProximo) &&
          a.status != ActivityStatus.completada;
    }).length;

    final hace7Dias = ahora.subtract(const Duration(days: 7));
    final bloqueadas = todasActividades.where((a) {
      return a.status == ActivityStatus.pendientes &&
          a.updatedAt.isBefore(hace7Dias);
    }).length;

    final totalActividades = todasActividades.length;
    final porcentajesDistribucion = <ActivityStatus, double>{};
    for (final estado in ActivityStatus.values) {
      final c = porEstado[estado] ?? 0;
      porcentajesDistribucion[estado] = totalActividades > 0
          ? (c / totalActividades * 100)
          : 0.0;
    }

    return {
      'completadasHoy': completadasHoy,
      'completadasSemana': completadasSemana,
      'porEstado': porEstado,
      'porcentajesDistribucion': porcentajesDistribucion,
      'deadlinesProximos': deadlinesProximos,
      'bloqueadas': bloqueadas,
      'total': totalActividades,
    };
  }

/// Bloque de métricas reutilizable (Productividad). [todas] debe ser solo
/// actividades sin proyecto ([personalActivities]).
class _ProductividadMetricsColumn extends StatelessWidget {
  const _ProductividadMetricsColumn({required this.todas});

  final List<ActivityModel> todas;

  Color _alertBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertBgLight
        : _ProductividadColors.alertBgDark;
  }

  Color _alertAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertAccentLight
        : _ProductividadColors.alertAccentDark;
  }

  Color _alertText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertTextLight
        : _ProductividadColors.alertTextDark;
  }

  Color? _sectionCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.sectionCardLight
        : null;
  }

  Color _metricCardBackground(
    String titulo,
    Color accent,
    Brightness brightness,
  ) {
    if (brightness == Brightness.light) {
      switch (titulo) {
        case 'Hoy':
          return _ProductividadColors.metricCardBgHoyLight;
        case 'Semana':
          return _ProductividadColors.metricCardBgSemanaLight;
        case 'Total':
          return _ProductividadColors.metricCardBgTotalLight;
        default:
          return _ProductividadColors.metricCardBgHoyLight;
      }
    }
    return accent.withValues(alpha: 0.12);
  }

  Color _metricAccent(String titulo, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    switch (titulo) {
      case 'Hoy':
        return isLight
            ? _ProductividadColors.metricHoyLight
            : _ProductividadColors.metricHoyDark;
      case 'Semana':
        return isLight
            ? _ProductividadColors.metricSemanaLight
            : _ProductividadColors.metricSemanaDark;
      case 'Total':
      default:
        return isLight
            ? _ProductividadColors.metricTotalLight
            : _ProductividadColors.metricTotalDark;
    }
  }

  Widget _buildMetricaCard(
    BuildContext context,
    String titulo,
    int valor,
    IconData icono,
  ) {
    final brightness = Theme.of(context).brightness;
    final accent = _metricAccent(titulo, brightness);
    return Card(
      color: _metricCardBackground(titulo, accent, brightness),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 28, color: accent),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor.toString(),
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
              ),
            ),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 17,
                    color: brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.84)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBar(
    BuildContext context,
    Map<ActivityStatus, double> porcentajesPorEstado,
    ActivityStatus estado,
    int cantidad,
  ) {
    final porcentaje = porcentajesPorEstado[estado] ?? 0.0;
    final color = ActivityStatusColors.forStatus(
      estado,
      brightness: Theme.of(context).brightness,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getEstadoIcon(estado), size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    estado.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              Text(
                '$cantidad (${porcentaje.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (porcentaje / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaItem(
    BuildContext context,
    IconData icono,
    String texto,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _alertText(context),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEstadoIcon(ActivityStatus estado) {
    return switch (estado) {
      ActivityStatus.bandeja => Icons.inbox_outlined,
      ActivityStatus.hoy => Icons.today_outlined,
      ActivityStatus.manana => Icons.event_outlined,
      ActivityStatus.programado => Icons.schedule_outlined,
      ActivityStatus.pendientes => Icons.pause_circle_outline,
      ActivityStatus.completada => Icons.star_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final m = _computeProductividadMetricas(todas);
    final porEstado = m['porEstado'] as Map<ActivityStatus, int>? ?? {};
    final porcentajes =
        m['porcentajesDistribucion'] as Map<ActivityStatus, double>? ?? {};
    final deadlinesProximos = m['deadlinesProximos'] as int? ?? 0;
    final bloqueadas = m['bloqueadas'] as int? ?? 0;
    final total = m['total'] as int? ?? todas.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMetricaCard(
                context,
                'Hoy',
                m['completadasHoy'] as int? ?? 0,
                Icons.today,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricaCard(
                context,
                'Semana',
                m['completadasSemana'] as int? ?? 0,
                Icons.calendar_view_week,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricaCard(
                context,
                'Total',
                total,
                Icons.list,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          color: _sectionCardColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución de actividades',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...ActivityStatus.values.map(
                  (e) => _buildEstadoBar(
                    context,
                    porcentajes,
                    e,
                    porEstado[e] ?? 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (deadlinesProximos > 0 || bloqueadas > 0)
          Card(
            color: _alertBg(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _alertAccent(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alertas',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _alertText(context),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (deadlinesProximos > 0)
                    _buildAlertaItem(
                      context,
                      Icons.calendar_today,
                      '$deadlinesProximos deadlines próximos (3 días)',
                      _alertAccent(context),
                    ),
                  if (bloqueadas > 0)
                    _buildAlertaItem(
                      context,
                      Icons.pause_circle_outline,
                      '$bloqueadas actividades bloqueadas > 7 días',
                      ActivityStatusColors.forStatus(
                        ActivityStatus.pendientes,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Métricas personales (sin proyecto): anillo + KPIs + distribución + alertas.
class _PersonalProductividadSection extends StatelessWidget {
  const _PersonalProductividadSection({required this.activities});

  final List<ActivityModel> activities;

  Color? _sectionCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.sectionCardLight
        : null;
  }

  Color _alertBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertBgLight
        : _ProductividadColors.alertBgDark;
  }

  Color _alertAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertAccentLight
        : _ProductividadColors.alertAccentDark;
  }

  Color _alertText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertTextLight
        : _ProductividadColors.alertTextDark;
  }

  IconData _getEstadoIcon(ActivityStatus estado) {
    return switch (estado) {
      ActivityStatus.bandeja => Icons.inbox_outlined,
      ActivityStatus.hoy => Icons.today_outlined,
      ActivityStatus.manana => Icons.event_outlined,
      ActivityStatus.programado => Icons.schedule_outlined,
      ActivityStatus.pendientes => Icons.pause_circle_outline,
      ActivityStatus.completada => Icons.star_outline,
    };
  }

  Widget _buildEstadoBar(
    BuildContext context,
    Map<ActivityStatus, double> porcentajesPorEstado,
    ActivityStatus estado,
    int cantidad,
  ) {
    final porcentaje = porcentajesPorEstado[estado] ?? 0.0;
    final color = ActivityStatusColors.forStatus(
      estado,
      brightness: Theme.of(context).brightness,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getEstadoIcon(estado), size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    estado.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              Text(
                '$cantidad (${porcentaje.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (porcentaje / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaItem(
    BuildContext context,
    IconData icono,
    String texto,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _alertText(context),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = _computeProductividadMetricas(activities);
    final porEstado = m['porEstado'] as Map<ActivityStatus, int>? ?? {};
    final porcentajes =
        m['porcentajesDistribucion'] as Map<ActivityStatus, double>? ?? {};
    final deadlinesProximos = m['deadlinesProximos'] as int? ?? 0;
    final bloqueadas = m['bloqueadas'] as int? ?? 0;

    final total = activities.length;
    final completadas = porEstado[ActivityStatus.completada] ?? 0;
    final pendientesCnt = porEstado[ActivityStatus.pendientes] ?? 0;
    final vencidas = _countOverdueActivities(activities);
    final tasa =
        total == 0 ? 0.0 : (completadas / total * 100).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actividades personales',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _RingKpi(
            rate: tasa,
            label: 'Completado personal',
          ),
        ),
        const SizedBox(height: 16),
        _KpiCardGrid(items: [
          _KpiItem('Total', total, scheme.primary),
          _KpiItem(
            'Completadas',
            completadas,
            ActivityStatusColors.forStatus(
              ActivityStatus.completada,
              brightness: scheme.brightness,
            ),
          ),
          _KpiItem(
            'Pendientes',
            pendientesCnt,
            ActivityStatusColors.forStatus(
              ActivityStatus.pendientes,
              brightness: scheme.brightness,
            ),
          ),
          _KpiItem(
            'Vencidas',
            vencidas,
            PaletaPasteles.fechaUrgente(scheme.brightness),
          ),
        ]),
        const SizedBox(height: 24),
        Card(
          color: _sectionCardColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución de actividades',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...ActivityStatus.values.map(
                  (e) => _buildEstadoBar(
                    context,
                    porcentajes,
                    e,
                    porEstado[e] ?? 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (deadlinesProximos > 0 || bloqueadas > 0)
          Card(
            color: _alertBg(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _alertAccent(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alertas',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _alertText(context),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (deadlinesProximos > 0)
                    _buildAlertaItem(
                      context,
                      Icons.calendar_today,
                      '$deadlinesProximos deadlines próximos (3 días)',
                      _alertAccent(context),
                    ),
                  if (bloqueadas > 0)
                    _buildAlertaItem(
                      context,
                      Icons.pause_circle_outline,
                      '$bloqueadas actividades bloqueadas > 7 días',
                      ActivityStatusColors.forStatus(
                        ActivityStatus.pendientes,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkerProductividadScreen extends ConsumerWidget {
  const _WorkerProductividadScreen();

  void _mostrarMenuNotificaciones(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Probar notificaciones',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.wb_sunny),
                      title: const Text('Revisión matutina (8:00)'),
                      subtitle: const Text('Mover actividades de Mañana a Hoy'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppSnackBar.aviso(
                            'Notificaciones programadas no configuradas en esta versión.',
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_twilight),
                      title: const Text('Revisión de mediodía (13:00)'),
                      subtitle: const Text('Actividades pendientes en Hoy'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppSnackBar.aviso(
                            'Notificaciones programadas no configuradas en esta versión.',
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight),
                      title: const Text('Revisión nocturna (21:00)'),
                      subtitle: const Text('Ajustar actividades pendientes'),
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppSnackBar.aviso(
                            'Notificaciones programadas no configuradas en esta versión.',
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Información'),
                      subtitle: const Text(
                        'Cuando exista servicio de notificaciones, se podrán programar avisos diarios.',
                      ),
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(allActivitiesProvider);
    final asyncProj = ref.watch(projectsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Productividad')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Productividad')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text('$e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(allActivitiesProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (todas) => asyncProj.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Productividad')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Productividad')),
          body: const Center(child: Text('No se cargaron proyectos')),
        ),
        data: (projects) {
          final byId = projectMap(projects);
          final pers = personalActivitiesForStats(user, todas, byId);
          final team = user.isPersonalAccount
              ? <ActivityModel>[]
              : teamActivitiesForStats(user, todas, byId);
          final showTeam = !user.isPersonalAccount;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Productividad'),
              elevation: 0,
              actions: [
                if (!user.isPersonalAccount)
                  IconButton(
                    icon: const Icon(Icons.notifications_active),
                    tooltip: 'Notificaciones',
                    onPressed: () => _mostrarMenuNotificaciones(context),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(allActivitiesProvider);
                    ref.invalidate(projectsProvider);
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allActivitiesProvider);
                ref.invalidate(projectsProvider);
                await ref.read(allActivitiesProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                children: [
                  const _SectionTitle('Actividades personales'),
                  const SizedBox(height: 8),
                  _ProductividadMetricsColumn(todas: pers),
                  if (showTeam) ...[
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const _SectionTitle('Actividades de equipo'),
                    const SizedBox(height: 8),
                    _ProductividadMetricsColumn(todas: team),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ÁREA — vista de su equipo
// ─────────────────────────────────────────────────────────────────────────────
class _AdminAreaStats extends ConsumerWidget {
  const _AdminAreaStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(workerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(workerStatsProvider);
              ref.invalidate(allActivitiesProvider);
              ref.invalidate(projectsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (ctx, ref, _) {
                final act = ref.watch(allActivitiesProvider);
                final proj = ref.watch(projectsProvider);
                return act.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (todas) => proj.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (projects) {
                      final u = ref.watch(currentUserProvider);
                      if (u == null) return const SizedBox.shrink();
                      final byId = projectMap(projects);
                      final pers = personalActivitiesForStats(u, todas, byId);
                      final team = teamActivitiesForStats(u, todas, byId);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle('Actividades personales'),
                          const SizedBox(height: 8),
                          _ProductividadMetricsColumn(todas: pers),
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          const _SectionTitle('Actividades de equipo'),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              (u.areaName ?? '').isEmpty
                                  ? 'Proyectos de equipo asignados por tu organización.'
                                  : 'Área: ${u.areaName}. Incluye proyectos compartidos y tareas del equipo.',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                          _ProductividadMetricsColumn(todas: team),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Por trabajador (TA) ───────────────────────────────────────
            _SectionTitle('Rendimiento por equipos'),
            const SizedBox(height: 12),
            workerAsync.when(
              loading: () => const _LoadingCard(),
              error: (_, __) => const SizedBox.shrink(),
              data: (workers) => Column(
                children: workers
                    .map((w) => _WorkerBar(worker: w))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPER ADMIN — todas las áreas + drill-down
// ─────────────────────────────────────────────────────────────────────────────
class _SuperAdminStats extends ConsumerWidget {
  const _SuperAdminStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allAreasStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(allAreasStatsProvider);
              ref.invalidate(allActivitiesProvider);
              ref.invalidate(projectsProvider);
            },
          ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            _ErrorRetry(onRetry: () => ref.invalidate(allAreasStatsProvider)),
        data: (areas) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer(
                  builder: (ctx, ref, _) {
                    final act = ref.watch(allActivitiesProvider);
                    final proj = ref.watch(projectsProvider);
                    final me = ref.watch(currentUserProvider);
                    return act.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (todas) => proj.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (projects) {
                          if (me == null) return const SizedBox.shrink();
                          return _PersonalProductividadSection(
                            activities: personalActivitiesForStats(
                              me,
                              todas,
                              projectMap(projects),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _SectionTitle('Rendimiento por equipos'),
                const SizedBox(height: 4),
                Text(
                  'Comparativa por administrador de área — toca para detalle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                ...areas.map(
                  (a) {
                    final rate = (a['completion_rate'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => _AreaDetailSheet(area: a),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4),
                          child: Text(
                            _initialName(a['admin_name'] as String? ?? '?'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          a['admin_name'] as String? ?? '—',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          a['area_name'] as String? ?? '',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${rate.toStringAsFixed(0)}%',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

/// Indicador circular de tasa de completado
class _RingKpi extends StatelessWidget {
  final double rate;
  final String label;
  /// Texto aclaratorio bajo la etiqueta (p. ej. alcance de las métricas).
  final String? hint;
  const _RingKpi({
    required this.rate,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _productividadRateColor(context, rate);

    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140, height: 140,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 12,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${rate.toStringAsFixed(1)}%',
                    style: AppTextStyles.heading1.copyWith(
                      color: color, fontSize: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.bodySecondary
              .copyWith(color: scheme.onSurfaceVariant),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiItem {
  final String label;
  final dynamic value;
  final Color color;
  const _KpiItem(this.label, this.value, this.color);
}

/// Grid de tarjetas KPI (2 columnas)
class _KpiCardGrid extends StatelessWidget {
  final List<_KpiItem> items;
  const _KpiCardGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: item.color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.value}',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: item.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppTextStyles.caption
                    .copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Barra de progreso de un trabajador
class _WorkerBar extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _WorkerBar({required this.worker});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate  = (worker['completion_rate'] as num).toDouble();
    final color = _productividadRateColor(context, rate);
    final b = scheme.brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(worker['name'] as String,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface)),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                  label: 'Total',
                  value: worker['total'],
                  color: scheme.primary),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'Completadas',
                  value: worker['completed'],
                  color: ActivityStatusColors.forStatus(
                    ActivityStatus.completada,
                    brightness: b,
                  )),
              const SizedBox(width: 12),
              _MiniStat(
                  label: 'Vencidas',
                  value: worker['overdue'],
                  color: PaletaPasteles.fechaUrgente(b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return RichText(
      text: TextSpan(
        style: AppTextStyles.caption.copyWith(color: muted),
        children: [
          TextSpan(
            text: '$value ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextSpan(text: label),
        ],
      ),
    );
  }
}

/// Bottom sheet con detalle del área (para SuperAdmin drill-down)
class _AreaDetailSheet extends StatelessWidget {
  final Map<String, dynamic> area;
  const _AreaDetailSheet({required this.area});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = (area['completion_rate'] as num).toDouble();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(area['area_name'] as String,
              style: AppTextStyles.heading2
                  .copyWith(color: scheme.onSurface)),
          Text(
            'Admin: ${area['admin_name']}  •  ${area['members']} miembros',
            style: AppTextStyles.bodySecondary
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Center(
            child: _RingKpi(
              rate: rate,
              label: 'Completado del área',
              hint: 'Solo actividades que no están en un proyecto',
            ),
          ),
          const SizedBox(height: 20),
          _KpiCardGrid(items: [
            _KpiItem('Total', area['total'], scheme.primary),
            _KpiItem(
              'Completadas',
              area['completed'],
              ActivityStatusColors.forStatus(
                ActivityStatus.completada,
                brightness: scheme.brightness,
              ),
            ),
            _KpiItem(
              'Vencidas',
              area['overdue'],
              PaletaPasteles.fechaUrgente(scheme.brightness),
            ),
            _KpiItem(
              'Miembros',
              area['members'],
              ActivityStatusColors.forStatus(
                ActivityStatus.hoy,
                brightness: scheme.brightness,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // Pendiente: cuando el backend tenga el endpoint de workers por área
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: scheme.onSurfaceVariant, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El desglose por trabajador de esta área estará disponible cuando el backend exponga el endpoint correspondiente.',
                    style: AppTextStyles.caption
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de UI
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.heading2.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No se pudieron cargar las estadísticas'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}
