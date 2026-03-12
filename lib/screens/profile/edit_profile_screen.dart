// lib/screens/profile/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
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
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _uploadingCover = false;

  // Locally picked files (not yet uploaded)
  File? _pendingAvatar;
  File? _pendingCover;

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
    _instagram =
        TextEditingController(text: user.socialLinks['instagram'] ?? '');
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

  // ─── Pick & upload image ────────────────────────────────────────────────────

  Future<String?> _uploadFile(File file, String folder) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last;
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _api.post(
      '${ApiConfig.uploadImage}?folder=$folder',
      data: formData,
    );
    return res.data['data']?['url'] as String?;
  }

  Future<void> _pickAvatar() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _pendingAvatar = file;
      _uploadingAvatar = true;
    });
    try {
      final url = await _uploadFile(file, 'avatars');
      if (url != null && mounted) {
        final user = context.read<AuthProvider>().user!;
        await _api.patch(ApiConfig.user(user.id), data: {'avatar': url});
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
        setState(() => _pendingAvatar = null);
      }
    }
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  Future<void> _pickCover() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _pendingCover = file;
      _uploadingCover = true;
    });
    try {
      final url = await _uploadFile(file, 'covers');
      if (url != null && mounted) {
        final user = context.read<AuthProvider>().user!;
        await _api.patch(ApiConfig.user(user.id), data: {'coverImage': url});
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload cover: $e')),
        );
        setState(() => _pendingCover = null);
      }
    }
    if (mounted) setState(() => _uploadingCover = false);
  }

  // ─── Save text fields ───────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = context.read<AuthProvider>().user!;
      final body = {
        if (_displayName.text.trim().isNotEmpty)
          'displayName': _displayName.text.trim(),
        if (_username.text.trim().isNotEmpty) 'username': _username.text.trim(),
        'bio': _bio.text.trim(),
        'location': _location.text.trim(),
        'website': _website.text.trim(),
        'socialLinks': {
          if (_instagram.text.trim().isNotEmpty)
            'instagram': _instagram.text.trim(),
          if (_twitter.text.trim().isNotEmpty) 'twitter': _twitter.text.trim(),
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

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
            // ── Cover + Avatar ───────────────────────────────────────────
            _buildPhotoSection(user),

            _sectionHeader('BASIC INFO'),
            _field(
                controller: _displayName,
                label: 'Display Name',
                hint: 'Your public name'),
            _field(
              controller: _username,
              label: 'Username',
              hint: 'e.g. janegil',
              prefix: '@',
              validator: (v) {
                if (v != null &&
                    v.isNotEmpty &&
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
                hint: 'e.g. Oslo, Norway'),
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

  // ─── Photo section ──────────────────────────────────────────────────────────

  Widget _buildPhotoSection(user) {
    final coverUrl = user.coverImage as String?;
    final avatarUrl = user.avatar as String?;
    final initials = (user.displayName ?? user.name ?? '?')[0].toUpperCase();

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Cover photo ──────────────────────────────────────────────
          GestureDetector(
            onTap: _uploadingCover ? null : _pickCover,
            child: Container(
              height: 150,
              width: double.infinity,
              color: AppColors.surfaceDim,
              child: _buildCoverContent(coverUrl),
            ),
          ),

          // Cover edit icon
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: _uploadingCover
                ? const _UploadSpinner()
                : _editBadge(Icons.camera_alt_outlined),
          ),

          // ── Avatar ───────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: AppSpacing.lg,
            child: GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 3),
                      color: AppColors.surface,
                    ),
                    child: ClipOval(
                      child: _buildAvatarContent(avatarUrl, initials),
                    ),
                  ),
                  // Avatar edit icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _uploadingAvatar
                        ? const _UploadSpinner(size: 24)
                        : _editBadge(Icons.camera_alt_outlined, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverContent(String? coverUrl) {
    if (_pendingCover != null) {
      return Image.file(_pendingCover!,
          fit: BoxFit.cover, width: double.infinity);
    }
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(color: AppColors.surfaceDim),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.textMuted, size: 32),
          const SizedBox(height: 6),
          const Text('Add cover photo',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: AppFontSize.sm)),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(String? avatarUrl, String initials) {
    if (_pendingAvatar != null) {
      return Image.file(_pendingAvatar!, fit: BoxFit.cover);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceDim),
      );
    }
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Text(initials,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.teal)),
      ),
    );
  }

  Widget _editBadge(IconData icon, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg.withValues(alpha: 0.85),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.text),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

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
                borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
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

// ─── Upload spinner badge ─────────────────────────────────────────────────────

class _UploadSpinner extends StatelessWidget {
  final double size;
  const _UploadSpinner({this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg.withValues(alpha: 0.85),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: const CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.teal),
      ),
    );
  }
}
