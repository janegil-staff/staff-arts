// lib/screens/shows/shows_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ShowsScreen extends StatelessWidget {
  const ShowsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Nav Buttons ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                _navButton(context, '📅', 'Events', 0),
                const SizedBox(width: AppSpacing.sm),
                _navButton(context, '🖼️', 'Exhibitions', 0),
                const SizedBox(width: AppSpacing.sm),
                _navButton(context, '🎵', 'Music', 0),
              ],
            ),
          ),

          // ── Timeline ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🎭', style: TextStyle(fontSize: 40)),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No shows yet',
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Create an event, exhibition, or music show',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── FAB ──
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // TODO: Navigate to CreateShow
          },
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.textInverse,
          icon: const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          label: const Text(
            'New Show',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navButton(BuildContext context, String icon, String label, int count) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to sub-screen
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSize.xs,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}