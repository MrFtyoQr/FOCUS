import 'package:flutter/material.dart';
import '../../shared/enums/activity_status.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final ActivityStatus status;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status.name);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical:   large ? 5  : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize:   large ? 12 : 10,
          fontWeight: FontWeight.w500,
          color:      color,
        ),
      ),
    );
  }
}
