import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../utils/estado_actividad_colors.dart';
import '../utils/paleta_pasteles.dart';

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
    final isLight = theme.brightness == Brightness.light;
    final slidableForeground = isLight
        ? const Color(0xFFF3F5FA)
        : PaletaPasteles.slidableCompletarPrimerPlano;

    return Slidable(
      key: ValueKey(actividad.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onComplete?.call(),
            backgroundColor: PaletaPasteles.slidableCompletarFondo(
              Theme.of(context).brightness,
            ),
            foregroundColor: slidableForeground,
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
            backgroundColor: PaletaPasteles.slidableMoverFondo(
              Theme.of(context).brightness,
            ),
            foregroundColor: slidableForeground,
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
                        _getColorFromString(context, proyecto!.color),
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
                        actividad.estado == EstadoActividad.programado
                            ? EstadoActividadColors.forEstado(
                                EstadoActividad.programado,
                                brightness: theme.brightness,
                              )
                            : (_isDeadlineProximo(actividad.fechaObjetivo!)
                                ? PaletaPasteles.fechaUrgente(theme.brightness)
                                : PaletaPasteles.fechaNormal(theme.brightness)),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
    final theme = Theme.of(context);
    final base = EstadoActividadColors.forEstado(
      actividad.estado,
      brightness: theme.brightness,
    );
    final onSurf = theme.colorScheme.onSurface;
    final t = theme.brightness == Brightness.dark ? 0.32 : 0.06;
    final color = Color.lerp(base, onSurf, t)!;
    final fillA = theme.brightness == Brightness.dark ? 0.14 : 0.18;
    final borderA = theme.brightness == Brightness.dark ? 0.26 : 0.38;
    final textA = theme.brightness == Brightness.dark ? 0.82 : 0.9;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: fillA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: borderA), width: 1),
      ),
      child: Text(
        actividad.estado.nombre,
        style: TextStyle(
          color: color.withValues(alpha: textA),
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
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getTituloConProyecto() {
    if (proyecto != null && numeroActividadProyecto != null) {
      return 'Actividad $numeroActividadProyecto del proyecto ${proyecto!.nombre}';
    }
    return actividad.titulo;
  }

  Color _getColorFromString(BuildContext context, String? colorHex) {
    return PaletaPasteles.proyectoColorByMode(
      colorHex,
      Theme.of(context).brightness,
    );
  }

  bool _isDeadlineProximo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = fecha.difference(ahora).inDays;
    return diferencia >= 0 && diferencia <= 3;
  }
}

