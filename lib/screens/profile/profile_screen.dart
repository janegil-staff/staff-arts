// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // ── Avatar & Info ──
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            children: [
              // Avatar
              if (user.avatar != null && user.avatar!.isNotEmpty)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(user.avatar!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      (user.displayName ?? user.name ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),

              // Name
              Text(
                user.displayLabel,
                style: const TextStyle(
                  fontSize: AppFontSize.xxl,
                  fontWeight: FontWeight.w300,
                  color: AppColors.text,
                ),
              ),

              // Username
              if (user.username != null) ...[
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textMuted,
                  ),
                ),
              ],

              // Role badge
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  user.role[0].toUpperCase() + user.role.substring(1),
                  style: const TextStyle(
                    fontSize: AppFontSize.xxs,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Bio
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],

              // Location
              if (user.location != null && user.location!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '📍 ${user.location}',
                  style: const TextStyle(
                    fontSize: AppFontSize.xs,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Stats Bar ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              _statItem('Followers', user.followerCount, showDivider: true),
              _statItem('Following', user.followingCount, showDivider: true),
              _statItem('Works', user.artworkCount, showDivider: false),
            ],
          ),
        ),

        // ── Edit Profile Button ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to EditProfile
            },
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: AppFontSize.md),
            ),
          ),
        ),

        // ── Menu Items ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              _menuItem('🎨', 'My Artworks', () {}),
              _divider(),
              _menuItem('📦', 'Orders', () {}),
              _divider(),
              _menuItem('✏️', 'Commissions', () {}),
              _divider(),
              _menuItem('💬', 'Messages', () {}),
              _divider(),
              _menuItem('⚙️', 'Settings', () {}),
            ],
          ),
        ),

        // ── Sign Out ──
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: TextButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, int count, {required bool showDivider}) {
    return Expanded(
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.borderLight),
                ),
              )
            : null,
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: AppFontSize.xl,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSize.xs,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  color: AppColors.text,
                ),
              ),
            ),
            const Text(
              '›',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 0, indent: AppSpacing.lg, endIndent: AppSpacing.lg);
  }
}