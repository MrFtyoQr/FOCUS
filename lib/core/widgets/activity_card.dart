import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/models/activity.dart';
import '../../shared/enums/activity_status.dart';
import '../utils/activity_status_colors.dart';
import '../utils/paleta_pasteles.dart';
import '../theme/app_text_styles.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  /// Abre flujo para cambiar de estado (p. ej. bottom sheet «Mover»).
  final VoidCallback? onMove;
  /// Hex `#RRGGBB` del proyecto (opcional; mejora el chip sin tocar el modelo).
  final String? projectColorHex;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onComplete,
    this.onMove,
    this.projectColorHex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final statusColor = ActivityStatusColors.forStatus(
      activity.status,
      brightness: brightness,
    );
    final surface = scheme.surfaceContainerLow;
    final borderColor = activity.isCompleted
        ? statusColor.withValues(alpha: 0.35)
        : scheme.outlineVariant;

    final card = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.deferToChild,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.title,
                    style: AppTextStyles.heading3.copyWith(
                      decoration: activity.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: activity.isCompleted
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: activity.status),
              ],
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (activity.assignedToId != null)
                  _AssigneeChip(
                    assigneeName: activity.assignedToName ?? 'Usuario',
                  ),
                if (activity.projectId != null &&
                    (activity.projectName ?? '').trim().isNotEmpty)
                  _ProjectChip(
                    name: activity.projectName!.trim(),
                    colorHex: projectColorHex,
                  )
                else if (activity.projectId != null)
                  _ProjectChip(
                    name: 'Proyecto',
                    colorHex: projectColorHex,
                  ),
                if (activity.targetDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _formatDate(activity.targetDate!),
                      style: AppTextStyles.caption.copyWith(
                        color: activity.status == ActivityStatus.programado
                            ? ActivityStatusColors.forStatus(
                                ActivityStatus.programado,
                                brightness: brightness,
                              )
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            if (activity.ownerName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Creada por ${activity.ownerName}',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    final useSlidable = !activity.isCompleted &&
        (onMove != null || onComplete != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: useSlidable
          ? Slidable(
              key: ValueKey('slidable_${activity.id}'),
              startActionPane: onComplete != null
                  ? ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.46,
                      children: [
                        SlidableAction(
                          onPressed: (ctx) {
                            Slidable.of(ctx)?.close();
                            onComplete!();
                          },
                          backgroundColor: PaletaPasteles.slidableCompletarFondo(
                              brightness),
                          foregroundColor: PaletaPasteles
                              .slidableCompletarPrimerPlano(brightness),
                          icon: Icons.check_circle_outline,
                          label: 'Completar',
                          spacing: 4,
                        ),
                      ],
                    )
                  : null,
              endActionPane: onMove != null
                  ? ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.38,
                      children: [
                        SlidableAction(
                          onPressed: (ctx) {
                            Slidable.of(ctx)?.close();
                            onMove!();
                          },
                          backgroundColor:
                              PaletaPasteles.slidableMoverFondo(brightness),
                          foregroundColor: PaletaPasteles.slidableMoverPrimerPlano(
                              brightness),
                          icon: Icons.drive_file_move_outline,
                          label: 'Mover',
                          spacing: 4,
                        ),
                      ],
                    )
                  : null,
              child: card,
            )
          : card,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

class _StatusBadge extends StatelessWidget {
  final ActivityStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color =
        ActivityStatusColors.forStatus(status, brightness: brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}

class _AssigneeChip extends StatelessWidget {
  final String assigneeName;
  const _AssigneeChip({required this.assigneeName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            'Para $assigneeName',
            style: AppTextStyles.label.copyWith(color: c),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String name;
  final String? colorHex;
  const _ProjectChip({required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final c = PaletaPasteles.proyectoColorByMode(colorHex, brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: AppTextStyles.label.copyWith(color: c),
      ),
    );
  }
}
