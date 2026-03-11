// lib/screens/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  late final TextEditingController _location;
  late final TextEditingController _website;
  late final TextEditingController _instagram;
  late final TextEditingController _twitter;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _displayName = TextEditingController(text: user.displayName ?? '');
    _username = TextEditingController(text: user.username ?? '');
    _bio = TextEditingController(text: user.bio ?? '');
    _location = TextEditingController(text: user.location ?? '');
    _website = TextEditingController(text: user.website);
    _instagram = TextEditingController(text: user.socialLinks['instagram'] ?? '');
    _twitter = TextEditingController(text: user.socialLinks['twitter'] ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    _location.dispose();
    _website.dispose();
    _instagram.dispose();
    _twitter.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final body = {
        if (_displayName.text.trim().isNotEmpty)
          'displayName': _displayName.text.trim(),
        if (_username.text.trim().isNotEmpty)
          'username': _username.text.trim(),
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
        'website': _website.text.trim(),
        'socialLinks': {
          if (_instagram.text.trim().isNotEmpty)
            'instagram': _instagram.text.trim(),
          if (_twitter.text.trim().isNotEmpty)
            'twitter': _twitter.text.trim(),
        },
      };

      final res = await _api.patch(ApiConfig.user(user.id), data: body);
      if (res.data['success'] == true) {
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w300)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.teal))
                  : const Text('Save',
                      style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                          fontSize: AppFontSize.md)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _sectionHeader('BASIC INFO'),
            _field(
              controller: _displayName,
              label: 'Display Name',
              hint: 'Your public name',
            ),
            _field(
              controller: _username,
              label: 'Username',
              hint: 'e.g. janegil',
              prefix: '@',
              validator: (v) {
                if (v != null && v.isNotEmpty &&
                    !RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v)) {
                  return 'Only letters, numbers, _ . - allowed';
                }
                return null;
              },
            ),
            _field(
              controller: _bio,
              label: 'Bio',
              hint: 'Tell the world about yourself',
              maxLines: 4,
            ),
            _field(
              controller: _location,
              label: 'Location',
              hint: 'e.g. Oslo, Norway',
            ),
            _field(
              controller: _website,
              label: 'Website',
              hint: 'https://yoursite.com',
              keyboard: TextInputType.url,
            ),

            _sectionHeader('SOCIAL LINKS'),
            _field(
              controller: _instagram,
              label: 'Instagram',
              hint: 'username',
              prefix: 'instagram.com/',
            ),
            _field(
              controller: _twitter,
              label: 'X / Twitter',
              hint: 'username',
              prefix: 'x.com/',
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
      child: Text(label,
          style: const TextStyle(
              fontSize: AppFontSize.xxs,
              letterSpacing: 2.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? prefix,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            validator: validator,
            style: const TextStyle(
                fontSize: AppFontSize.md, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixText: prefix,
              prefixStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.md),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide:
                    const BorderSide(color: AppColors.teal, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
