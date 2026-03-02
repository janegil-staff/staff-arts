// lib/widgets/app_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool small;

  const AppChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 14,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.teal : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.sm,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}