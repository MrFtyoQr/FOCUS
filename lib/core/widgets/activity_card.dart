import 'package:flutter/material.dart';
import '../../shared/models/activity.dart';
import '../../shared/enums/activity_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activity.isCompleted
                ? AppColors.teal.withValues(alpha: 0.3)
                : AppColors.surfaceBorder,
            width: 0.5,
          ),
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
                          ? TextDecoration.lineThrough : null,
                      color: activity.isCompleted
                          ? AppColors.textSecondary : AppColors.textPrimary,
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
                style: AppTextStyles.bodySecondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (activity.isAssigned) ...[
                  _AssignedBadge(assignedBy: activity.assignedByName ?? ''),
                  const SizedBox(width: 6),
                ],
                if (activity.projectName != null)
                  _ProjectChip(name: activity.projectName!),
                const Spacer(),
                if (activity.targetDate != null)
                  Text(
                    _formatDate(activity.targetDate!),
                    style: AppTextStyles.caption,
                  ),
                if (onComplete != null && !activity.isCompleted) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onComplete,
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
    final color = AppColors.statusColor(status.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _AssignedBadge extends StatelessWidget {
  final String assignedBy;
  const _AssignedBadge({required this.assignedBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Asignada · $assignedBy',
        style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w500,
          color: AppColors.purpleLight,
        ),
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String name;
  const _ProjectChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
