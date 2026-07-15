import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.info,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (type) {
      case StatusBadgeType.success:
        return (AppColors.bridgeSuccess, AppColors.bridgeSuccess.withOpacity(0.15));
      case StatusBadgeType.error:
        return (AppColors.bridgeError, AppColors.bridgeError.withOpacity(0.15));
      case StatusBadgeType.warning:
        return (AppColors.bridgeWarning, AppColors.bridgeWarning.withOpacity(0.15));
      case StatusBadgeType.info:
        return (AppColors.bridgePrimary, AppColors.bridgePrimary.withOpacity(0.15));
    }
  }
}

enum StatusBadgeType { success, error, warning, info }