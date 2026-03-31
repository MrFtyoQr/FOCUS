import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/app_snackbar.dart';
import '../utils/estado_actividad_colors.dart';
import '../utils/responsive.dart';

/// Paleta pastel para esta pantalla (evita acentos muy saturados).
class _ProductividadColors {
  // Light mode: tonos coloridos pero suaves.
  static const metricHoyLight = Color(0xFF4F7FD1);
  static const metricSemanaLight = Color(0xFF4DAA72);
  static const metricTotalLight = Color(0xFF8C6BCB);

  // Dark mode: acentos pastel para evitar brillo/neón.
  static const metricHoyDark = Color(0xFF8FB4E0);
  static const metricSemanaDark = Color(0xFFA8DCC8);
  static const metricTotalDark = Color(0xFFC4B8E8);

  /// Fondos claros para tarjetas Hoy / Semana / Total (solo light mode).
  static const metricCardBgHoyLight = Color(0xFFF2F6FC);
  static const metricCardBgSemanaLight = Color(0xFFF2F8F4);
  static const metricCardBgTotalLight = Color(0xFFF5F2FA);

  /// Distribución por estado y Flujo Bandeja → Hoy (solo light mode).
  static const sectionCardLight = Color(0xFFF7F7F7);

  /// Alertas (light más visible; dark se mantiene suave).
  static const alertBgLight = Color(0xFFF7E7B5);
  static const alertAccentLight = Color(0xFFD4A03A);
  static const alertTextLight = Color(0xFF5A4622);

  static const alertBgDark = Color(0xFFF5E6D4);
  static const alertAccentDark = Color(0xFFD4A574);
  /// Texto sobre fondo de alerta en dark.
  static const alertTextDark = Color(0xFF4A3428);

  static const progressGoodLight = Color(0xFF4DAA72);
  static const progressWarnLight = Color(0xFFE78A4E);
  static const progressGoodDark = Color(0xFF9BC9A8);
  static const progressWarnDark = Color(0xFFE8C4A0);

}

/// Dashboard de productividad con métricas
class ProductividadScreen extends StatefulWidget {
  const ProductividadScreen({super.key});

  @override
  State<ProductividadScreen> createState() => _ProductividadScreenState();
}

class _ProductividadScreenState extends State<ProductividadScreen> {
  Color _alertBg() {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertBgLight
        : _ProductividadColors.alertBgDark;
  }

  Color _alertAccent() {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertAccentLight
        : _ProductividadColors.alertAccentDark;
  }

  Color _alertText() {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.alertTextLight
        : _ProductividadColors.alertTextDark;
  }

  Color _flowProgressColor(double ratio) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (ratio > 50) {
      return isLight
          ? _ProductividadColors.progressGoodLight
          : _ProductividadColors.progressGoodDark;
    }
    return isLight
        ? _ProductividadColors.progressWarnLight
        : _ProductividadColors.progressWarnDark;
  }

  bool _isLoading = true;
  Map<String, dynamic> _metricas = {};

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseService().database;
      final ahora = DateTime.now();
      final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
      final inicioSemana = inicioDia.subtract(Duration(days: ahora.weekday - 1));
      
      // Obtener todas las actividades
      final todasActividades = <Actividad>[];
      for (var estado in EstadoActividad.values) {
        todasActividades.addAll(await db.getActividadesPorEstado(estado));
      }
      
      // Completadas hoy
      final completadasHoy = todasActividades.where((a) {
        return a.estado == EstadoActividad.completada &&
            a.updatedAt.isAfter(inicioDia);
      }).length;
      
      // Completadas esta semana
      final completadasSemana = todasActividades.where((a) {
        return a.estado == EstadoActividad.completada &&
            a.updatedAt.isAfter(inicioSemana);
      }).length;
      
      // Distribución por estado
      final porEstado = <EstadoActividad, int>{};
      for (var estado in EstadoActividad.values) {
        porEstado[estado] = todasActividades.where((a) => a.estado == estado).length;
      }
      
      // Deadlines próximos (próximos 3 días)
      final deadlineProximo = ahora.add(const Duration(days: 3));
      final deadlinesProximos = todasActividades.where((a) {
        return a.fechaObjetivo != null &&
            a.fechaObjetivo!.isAfter(ahora) &&
            a.fechaObjetivo!.isBefore(deadlineProximo) &&
            a.estado != EstadoActividad.completada;
      }).length;
      
      // Actividades bloqueadas (pendientes > 7 días)
      final hace7Dias = ahora.subtract(const Duration(days: 7));
      final bloqueadas = todasActividades.where((a) {
        return a.estado == EstadoActividad.pendientes &&
            a.updatedAt.isBefore(hace7Dias);
      }).length;
      
      // Ratio Bandeja → Hoy
      final enBandeja = porEstado[EstadoActividad.bandeja] ?? 0;
      final enHoy = porEstado[EstadoActividad.hoy] ?? 0;
      final ratioBandejaHoy = enBandeja > 0 ? (enHoy / enBandeja * 100) : 0.0;
      
      // Calcular porcentajes reales por estado
      // Para cada estado: % = (completadas que pasaron por ese estado) / (total en ese estado + completadas de ese estado)
      final porcentajesPorEstado = <EstadoActividad, double>{};
      
      for (var estado in EstadoActividad.values) {
        if (estado == EstadoActividad.completada) continue;
        
        final totalEnEstado = porEstado[estado] ?? 0;
        
        // Para "Hoy": calcular basado en completadas hoy vs total en "Hoy"
        if (estado == EstadoActividad.hoy) {
          // Completadas hoy que podrían haber estado en "Hoy"
          final completadasHoyDeHoy = todasActividades.where((a) {
            return a.estado == EstadoActividad.completada &&
                a.updatedAt.isAfter(inicioDia);
          }).length;
          
          // Porcentaje: completadas hoy / (en estado hoy + completadas hoy)
          final totalRelevante = totalEnEstado + completadasHoyDeHoy;
          porcentajesPorEstado[estado] = totalRelevante > 0
              ? (completadasHoyDeHoy / totalRelevante * 100).clamp(0.0, 100.0)
              : 0.0;
        } else {
          // Para otros estados: porcentaje basado en distribución
          // Simplificado: mostrar qué porcentaje del total representa este estado
          final totalActividades = todasActividades.length;
          porcentajesPorEstado[estado] = totalActividades > 0
              ? (totalEnEstado / totalActividades * 100).clamp(0.0, 100.0)
              : 0.0;
        }
      }
      
      setState(() {
        _metricas = {
          'completadasHoy': completadasHoy,
          'completadasSemana': completadasSemana,
          'porEstado': porEstado,
          'porcentajesPorEstado': porcentajesPorEstado,
          'deadlinesProximos': deadlinesProximos,
          'bloqueadas': bloqueadas,
          'ratioBandejaHoy': ratioBandejaHoy,
          'total': todasActividades.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error('Error al cargar métricas: $e'),
        );
      }
    }
  }

  void _mostrarMenuNotificaciones() {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Probar Notificaciones',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.wb_sunny),
                      title: const Text('Revisión Matutina (8 AM)'),
                      subtitle: const Text('Mover actividades de Mañana a Hoy'),
                      onTap: () async {
                        Navigator.pop(context);
                        final notificationService = NotificationService();
                        await notificationService.mostrarNotificacionPrueba('8am');
                        await notificationService.probarNotificacion8AM();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppSnackBar.exito(
                              'Notificación de prueba enviada. Revisa tu bandeja de notificaciones.',
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_twilight),
                      title: const Text('Revisión de Mediodía (1 PM)'),
                      subtitle: const Text('Actividades pendientes en Hoy'),
                      onTap: () async {
                        Navigator.pop(context);
                        final notificationService = NotificationService();
                        await notificationService.mostrarNotificacionPrueba('1pm');
                        await notificationService.probarNotificacion1PM();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppSnackBar.exito(
                              'Notificación de prueba enviada. Revisa tu bandeja de notificaciones.',
                            ),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight),
                      title: const Text('Revisión Nocturna (9 PM)'),
                      subtitle: const Text('Ajustar actividades pendientes'),
                      onTap: () async {
                        Navigator.pop(context);
                        final notificationService = NotificationService();
                        await notificationService.mostrarNotificacionPrueba('9pm');
                        await notificationService.probarNotificacion9PM();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppSnackBar.exito(
                              'Notificación de prueba enviada. Revisa tu bandeja de notificaciones.',
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Información'),
                      subtitle: const Text('Las notificaciones se programan automáticamente cada día a las 8 AM, 1 PM y 9 PM'),
                      onTap: () => Navigator.pop(context),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productividad'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _mostrarMenuNotificaciones,
            tooltip: 'Probar notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMetricas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarMetricas,
              child: ListView(
                padding: EdgeInsets.all(Responsive.getHorizontalPadding(context)),
                children: [
                  const SizedBox(height: 8),
                  // Métricas principales (siempre en fila)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMetricaCard(
                          'Hoy',
                          _metricas['completadasHoy'],
                          Icons.today,
                          _ProductividadColors.metricHoyLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricaCard(
                          'Semana',
                          _metricas['completadasSemana'],
                          Icons.calendar_view_week,
                          _ProductividadColors.metricSemanaLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricaCard(
                          'Total',
                          _metricas['total'],
                          Icons.list,
                          _ProductividadColors.metricTotalLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Distribución por estado
                  Card(
                    color: _sectionCardColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distribución por Estado',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...(_metricas['porEstado'] as Map<EstadoActividad, int>?)
                                  ?.entries
                                  .where((e) => e.key != EstadoActividad.completada)
                                  .map((entry) => _buildEstadoBar(entry.key, entry.value, _metricas['total'] as int))
                                  .toList() ??
                              [],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Alertas
                  if (_metricas['deadlinesProximos'] > 0 || _metricas['bloqueadas'] > 0)
                    Card(
                      color: _alertBg(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: _alertAccent()),
                                const SizedBox(width: 8),
                                Text(
                                  'Alertas',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _alertText(),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_metricas['deadlinesProximos'] > 0)
                              _buildAlertaItem(
                                Icons.calendar_today,
                                '${_metricas['deadlinesProximos']} deadlines próximos (3 días)',
                                _alertAccent(),
                              ),
                            if (_metricas['bloqueadas'] > 0)
                              _buildAlertaItem(
                                Icons.pause_circle_outline,
                                '${_metricas['bloqueadas']} actividades bloqueadas > 7 días',
                                EstadoActividadColors.forEstado(
                                  EstadoActividad.pendientes,
                                  brightness: Theme.of(context).brightness,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Ratio Bandeja → Hoy
                  Card(
                    color: _sectionCardColor(context),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flujo Bandeja → Hoy',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ratio de actividades movidas de Bandeja a Hoy',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.25,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82)
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_metricas['ratioBandejaHoy'] as double? ?? 0.0) / 100,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _flowProgressColor(
                                _metricas['ratioBandejaHoy'] as double? ?? 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_metricas['ratioBandejaHoy'] as double? ?? 0.0).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color? _sectionCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _ProductividadColors.sectionCardLight
        : null;
  }

  Color _metricCardBackground(String titulo, Color accent, Brightness brightness) {
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

  Widget _buildMetricaCard(String titulo, int valor, IconData icono, Color color) {
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
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.84)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoBar(EstadoActividad estado, int cantidad, int total) {
    // Obtener porcentaje calculado previamente
    final porcentajesPorEstado = _metricas['porcentajesPorEstado'] as Map<EstadoActividad, double>?;
    final porcentaje = porcentajesPorEstado?[estado] ?? 0.0;
    final color = _getEstadoColor(estado);
    
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
                    estado.nombre,
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: porcentaje / 100,
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

  Widget _buildAlertaItem(IconData icono, String texto, Color color) {
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
                    color: _alertText(),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(EstadoActividad estado) {
    return EstadoActividadColors.forEstado(
      estado,
      brightness: Theme.of(context).brightness,
    );
  }

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox_outlined;
      case EstadoActividad.hoy:
        return Icons.today_outlined;
      case EstadoActividad.manana:
        return Icons.event_outlined;
      case EstadoActividad.programado:
        return Icons.schedule_outlined;
      case EstadoActividad.pendientes:
        return Icons.pause_circle_outline;
      case EstadoActividad.completada:
        return Icons.star_outline;
    }
  }
}
