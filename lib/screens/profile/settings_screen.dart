// lib/screens/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../auth/legal_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  bool _pushNotifications = true;
  bool _savingRole = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w300)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          _sectionHeader('Account'),
          _settingsGroup([
            _menuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => _showChangePasswordSheet(context),
            ),
            _divider(),
            _menuItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Account',
              color: AppColors.error,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ]),

          // ── Role ──────────────────────────────────────────────────────────
          _sectionHeader('I am a...'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _savingRole
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(
                          color: AppColors.teal, strokeWidth: 2),
                    ),
                  )
                : Row(
                    children: [
                      _roleChip(context, 'Artist', 'artist', user?.role),
                      const SizedBox(width: 8),
                      _roleChip(context, 'Collector', 'collector', user?.role),
                      const SizedBox(width: 8),
                      _roleChip(context, 'Gallery', 'gallery', user?.role),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Text(
              'Changing your role updates how others see your profile.',
              style: const TextStyle(
                  fontSize: AppFontSize.xs, color: AppColors.textMuted),
            ),
          ),

          // ── Notifications ─────────────────────────────────────────────────
          _sectionHeader('Notifications'),
          _settingsGroup([
            _toggleItem(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
          ]),

          // ── About ─────────────────────────────────────────────────────────
          _sectionHeader('About'),
          _settingsGroup([
            _menuItem(
              icon: Icons.info_outline_rounded,
              label: 'App Version',
              trailing: const Text(
                '1.0.0',
                style: TextStyle(
                    fontSize: AppFontSize.sm, color: AppColors.textMuted),
              ),
              onTap: null,
            ),
            _divider(),
            _menuItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LegalScreen(type: LegalType.privacy))),
            ),
            _divider(),
            _menuItem(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const LegalScreen(type: LegalType.terms))),
            ),
          ]),

          // ── Sign out ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: TextButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                    fontSize: AppFontSize.md,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Role chip ─────────────────────────────────────────────────────────────

  Widget _roleChip(
      BuildContext context, String label, String value, String? currentRole) {
    final active = currentRole == value;
    return GestureDetector(
      onTap: active ? null : () => _changeRole(context, value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Future<void> _changeRole(BuildContext context, String newRole) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title:
            const Text('Change Role', style: TextStyle(color: AppColors.text)),
        content: Text(
          'Switch your role to ${newRole[0].toUpperCase()}${newRole.substring(1)}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Confirm', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _savingRole = true);
    try {
      await _api.patch(ApiConfig.user(userId), data: {'role': newRole});
      await auth.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Role updated to ${newRole[0].toUpperCase()}${newRole.substring(1)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update role: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _savingRole = false);
  }

  // ── Change password ───────────────────────────────────────────────────────

  void _showChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomPadding = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Change Password',
                      style: TextStyle(
                          fontSize: AppFontSize.lg,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text)),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textMuted),
                        onPressed: () => setSheetState(
                            () => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.isNotEmpty ? null : 'Required',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textMuted),
                        onPressed: () =>
                            setSheetState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) =>
                        v != null && v.length >= 8 ? null : 'Min 8 characters',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText: 'Confirm new password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: AppColors.textMuted),
                    ),
                    validator: (v) =>
                        v == newCtrl.text ? null : 'Passwords do not match',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final auth = context.read<AuthProvider>();
                        final userId = auth.user?.id;
                        if (userId == null) return;
                        try {
                          await ApiService().patch(
                            ApiConfig.user(userId),
                            data: {
                              'currentPassword': currentCtrl.text,
                              'newPassword': newCtrl.text,
                            },
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Password updated successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed: $e'),
                                  backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Delete account ────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account',
            style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;
    try {
      await _api.delete(ApiConfig.user(userId));
      if (mounted) auth.logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: AppFontSize.xxs,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    final itemColor = color ?? AppColors.text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: AppFontSize.md, color: itemColor)),
            ),
            trailing ??
                (onTap != null
                    ? const Text('›',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 16))
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: AppFontSize.md, color: AppColors.text)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 0, indent: AppSpacing.lg, endIndent: AppSpacing.lg);
}
