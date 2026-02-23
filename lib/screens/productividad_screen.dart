import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/responsive.dart';

/// Dashboard de productividad con métricas
class ProductividadScreen extends StatefulWidget {
  const ProductividadScreen({super.key});

  @override
  State<ProductividadScreen> createState() => _ProductividadScreenState();
}

class _ProductividadScreenState extends State<ProductividadScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metricas = {};

  /// Llamado al volver a esta pestaña o al recuperar conexión.
  void refresh() => _cargarMetricas();

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
          SnackBar(content: Text('Error al cargar métricas: $e')),
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
                            const SnackBar(
                              content: Text('Notificación de prueba enviada. Revisa tu bandeja de notificaciones.'),
                              backgroundColor: Colors.green,
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
                            const SnackBar(
                              content: Text('Notificación de prueba enviada. Revisa tu bandeja de notificaciones.'),
                              backgroundColor: Colors.green,
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
                            const SnackBar(
                              content: Text('Notificación de prueba enviada. Revisa tu bandeja de notificaciones.'),
                              backgroundColor: Colors.green,
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
    final isTablet = Responsive.isTablet(context);
    
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
                  // Métricas principales
                  if (isTablet)
                    Row(
                      children: [
                        Expanded(child: _buildMetricaCard('Hoy', _metricas['completadasHoy'], Icons.today, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricaCard('Semana', _metricas['completadasSemana'], Icons.calendar_view_week, Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricaCard('Total', _metricas['total'], Icons.list, Colors.purple)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMetricaCard('Hoy', _metricas['completadasHoy'], Icons.today, Colors.blue),
                        const SizedBox(height: 16),
                        _buildMetricaCard('Semana', _metricas['completadasSemana'], Icons.calendar_view_week, Colors.green),
                        const SizedBox(height: 16),
                        _buildMetricaCard('Total', _metricas['total'], Icons.list, Colors.purple),
                      ],
                    ),
                  const SizedBox(height: 24),
                  
                  // Distribución por estado
                  Card(
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
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Alertas',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[900],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_metricas['deadlinesProximos'] > 0)
                              _buildAlertaItem(
                                Icons.calendar_today,
                                '${_metricas['deadlinesProximos']} deadlines próximos (3 días)',
                                Colors.orange,
                              ),
                            if (_metricas['bloqueadas'] > 0)
                              _buildAlertaItem(
                                Icons.pause_circle,
                                '${_metricas['bloqueadas']} actividades bloqueadas > 7 días',
                                Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Ratio Bandeja → Hoy
                  Card(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (_metricas['ratioBandejaHoy'] as double? ?? 0.0) / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _metricas['ratioBandejaHoy'] > 50 ? Colors.green : Colors.orange,
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

  Widget _buildMetricaCard(String titulo, int valor, IconData icono, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icono, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              titulo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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
              color: Colors.grey[200],
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Colors.grey;
      case EstadoActividad.hoy:
        return Colors.blue;
      case EstadoActividad.manana:
        return Colors.orange;
      case EstadoActividad.programado:
        return Colors.purple;
      case EstadoActividad.pendientes:
        return Colors.red;
      case EstadoActividad.completada:
        return Colors.green;
    }
  }

  IconData _getEstadoIcon(EstadoActividad estado) {
    switch (estado) {
      case EstadoActividad.bandeja:
        return Icons.inbox;
      case EstadoActividad.hoy:
        return Icons.today;
      case EstadoActividad.manana:
        return Icons.event;
      case EstadoActividad.programado:
        return Icons.calendar_today;
      case EstadoActividad.pendientes:
        return Icons.pause_circle;
      case EstadoActividad.completada:
        return Icons.check_circle;
    }
  }
}
