import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Widget de tarjeta para mostrar una actividad en las listas
class ActividadCard extends StatelessWidget {
  final Actividad actividad;
  final Proyecto? proyecto;
  final Persona? personaAsignada;
  final int? numeroActividadProyecto; // Número de actividad dentro del proyecto
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;
  final VoidCallback? onLongPress;

  const ActividadCard({
    super.key,
    required this.actividad,
    this.proyecto,
    this.personaAsignada,
    this.numeroActividadProyecto,
    this.onTap,
    this.onComplete,
    this.onMove,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Slidable(
      key: ValueKey(actividad.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onComplete?.call(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Completar',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onMove?.call(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.swap_horiz,
            label: 'Mover',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y badge de estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getTituloConProyecto(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildEstadoBadge(context),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips de información
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (proyecto != null)
                      _buildChip(
                        context,
                        Icons.folder_outlined,
                        proyecto!.nombre,
                        _getColorFromString(proyecto!.color),
                      ),
                    if (personaAsignada != null)
                      _buildChip(
                        context,
                        Icons.person_outline,
                        personaAsignada!.nombre,
                        theme.colorScheme.primary,
                      ),
                    if (actividad.fechaObjetivo != null)
                      _buildChip(
                        context,
                        Icons.calendar_today,
                        DateFormat('dd/MM/yyyy').format(actividad.fechaObjetivo!),
                        _isDeadlineProximo(actividad.fechaObjetivo!)
                            ? Colors.orange
                            : theme.colorScheme.secondary,
                      ),
                    if (actividad.tieneAdjuntos)
                      _buildChip(
                        context,
                        Icons.attach_file,
                        'Adjuntos',
                        theme.colorScheme.tertiary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Última actualización
                Text(
                  'Actualizado: ${dateFormat.format(actividad.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(BuildContext context) {
    final color = _getEstadoColor(actividad.estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        actividad.estado.nombre,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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

  String _getTituloConProyecto() {
    if (proyecto != null && numeroActividadProyecto != null) {
      return 'Actividad $numeroActividadProyecto del proyecto ${proyecto!.nombre}';
    }
    return actividad.titulo;
  }

  Color _getColorFromString(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) {
      return Colors.grey;
    }
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  bool _isDeadlineProximo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = fecha.difference(ahora).inDays;
    return diferencia >= 0 && diferencia <= 3;
  }
}

