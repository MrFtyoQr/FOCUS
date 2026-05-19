import 'package:flutter/material.dart';
import '../../shared/models/activity.dart';
import '../../shared/enums/activity_status.dart';
import '../utils/activity_status_colors.dart';

/// Muestra estados disponibles (excepto completada) para mover la actividad.
Future<void> mostrarMoverActividadBottomSheet(
  BuildContext context,
  ActivityModel activity,
  Future<void> Function(ActivityStatus nuevoEstado) onMover,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final brightness = Theme.of(ctx).brightness;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mover a',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ...ActivityStatus.values
                  .where((s) => s != ActivityStatus.completada)
                  .map((estado) {
                final color =
                    ActivityStatusColors.forStatus(estado, brightness: brightness);
                final icon = _iconFor(estado);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Text(
                      estado.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: estado == activity.status
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await onMover(estado);
                          },
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

IconData _iconFor(ActivityStatus s) {
  return switch (s) {
    ActivityStatus.bandeja => Icons.inbox_outlined,
    ActivityStatus.hoy => Icons.today_outlined,
    ActivityStatus.manana => Icons.event_outlined,
    ActivityStatus.programado => Icons.schedule_outlined,
    ActivityStatus.pendientes => Icons.pause_circle_outline,
    ActivityStatus.completada => Icons.check_circle_outline,
  };
}
