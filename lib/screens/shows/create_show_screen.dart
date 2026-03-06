// lib/screens/shows/create_show_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import 'package:dio/dio.dart';

enum ShowType { event, exhibition, music }

class CreateShowScreen extends StatefulWidget {
  const CreateShowScreen({super.key});

  @override
  State<CreateShowScreen> createState() => _CreateShowScreenState();
}

class _CreateShowScreenState extends State<CreateShowScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Shared fields
  ShowType? _showType;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  File? _coverImage;
  bool _isFree = true;
  bool _isOnline = false;
  bool _submitting = false;
  String _currency = 'NOK';

  // Event-specific
  String _eventType = 'other';
  String _eventCategory = 'event';

  // Exhibition-specific
  bool _isVirtual = false;
  final _virtualUrlCtrl = TextEditingController();

  // Music event types
  final _musicTypes = [
    'concert',
    'dj_set',
    'live_performance',
    'open_mic',
    'festival',
    'album_release',
  ];
  final _eventTypes = ['opening', 'workshop', 'talk', 'fair', 'other'];
  final _currencies = ['NOK', 'USD', 'EUR', 'GBP', 'SEK'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _linkCtrl.dispose();
    _virtualUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final initial = isEnd
        ? (_endDate ?? _startDate ?? DateTime.now())
        : (_startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.teal,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isEnd) {
          _endDate = picked;
        } else {
          _startDate = picked;
          _endDate ??= picked.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.teal,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickCover() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (file != null) setState(() => _coverImage = File(file.path));
  }

  DateTime _combineDateAndTime() {
    final date = _startDate ?? DateTime.now();
    final time = _startTime ?? const TimeOfDay(hour: 12, minute: 0);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<Map<String, String>?> _uploadCover({String folder = 'uploads'}) async {
    if (_coverImage == null) return null;
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_coverImage!.path),
      });
      final res = await _api.post(
        '${ApiConfig.uploadImage}?folder=$folder',
        data: formData,
      );
      final body = res.data;
      final data = body['data'] ?? body;
      return {
        'url': data['url'] ?? '',
        'publicId': data['publicId'] ?? '',
      };
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      _showError('Please select a date');
      return;
    }

    setState(() => _submitting = true);

    try {
      // Upload cover to Cloudinary with type-specific folder
      final folder = _showType == ShowType.exhibition
          ? 'exhibitions'
          : _showType == ShowType.music
              ? 'music'
              : 'events';
      final coverData = await _uploadCover(folder: folder);

      final dateTime = _combineDateAndTime();
      final price = double.tryParse(_priceCtrl.text) ?? 0;

      Map<String, dynamic> body;
      String endpoint;

      if (_showType == ShowType.exhibition) {
        endpoint = ApiConfig.exhibitions;
        body = {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'startDate': dateTime.toIso8601String(),
          'endDate': (_endDate ?? dateTime.add(const Duration(days: 7)))
              .toIso8601String(),
          'location': _locationCtrl.text.trim(),
          'isVirtual': _isVirtual,
          'virtualUrl': _virtualUrlCtrl.text.trim(),
          'ticketPrice': price,
          'isFree': _isFree,
          if (coverData != null) 'coverImage': coverData,
        };
      } else {
        // Event or Music
        endpoint = ApiConfig.events;
        body = {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'type': _eventType,
          'category': _showType == ShowType.music ? 'music' : _eventCategory,
          'date': dateTime.toIso8601String(),
          'endDate': (_endDate ?? dateTime.add(const Duration(days: 7)))
              .toIso8601String(),
          'location': _locationCtrl.text.trim(),
          'isOnline': _isOnline,
          'link': _linkCtrl.text.trim(),
          'price': price,
          'isFree': _isFree,
          'currency': _currency,
          if (coverData != null) 'coverImage': coverData,
        };
      }

      final res = await _api.post(endpoint, data: body);
      final resBody = res.data;
      final success = resBody['success'] == true;

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Show created successfully!'),
            backgroundColor: AppColors.teal,
          ),
        );
      } else {
        _showError(resBody['error'] ?? 'Failed to create show');
      }
    } catch (e) {
      if (mounted) _showError('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _showType == null ? 'New Show' : _typeTitle(),
          style: const TextStyle(
            fontSize: AppFontSize.lg,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_showType != null)
            TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.teal,
                      ),
                    )
                  : const Text(
                      'Publish',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: _showType == null ? _buildTypePicker() : _buildForm(),
      ),
    );
  }

  String _typeTitle() {
    switch (_showType!) {
      case ShowType.event:
        return 'New Event';
      case ShowType.exhibition:
        return 'New Exhibition';
      case ShowType.music:
        return 'New Music Event';
    }
  }

  // ── Type Picker ──
  Widget _buildTypePicker() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'What are you creating?',
            style: TextStyle(
              fontSize: AppFontSize.xxl,
              fontWeight: FontWeight.w300,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose the type of show you want to add',
            style: TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _typeCard(
            icon: Icons.event_rounded,
            title: 'Event',
            subtitle: 'Opening, workshop, talk, art fair',
            color: const Color(0xFF2dd4a0),
            bgColor: const Color(0xFF0d3b2e),
            onTap: () => setState(() {
              _showType = ShowType.event;
              _eventCategory = 'event';
              _eventType = 'other';
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          _typeCard(
            icon: Icons.museum_rounded,
            title: 'Exhibition',
            subtitle: 'Gallery show, solo or group exhibition',
            color: const Color(0xFF60a5fa),
            bgColor: const Color(0xFF1e2d4a),
            onTap: () => setState(() => _showType = ShowType.exhibition),
          ),
          const SizedBox(height: AppSpacing.md),
          _typeCard(
            icon: Icons.music_note_rounded,
            title: 'Music Event',
            subtitle: 'Concert, DJ set, live performance, festival',
            color: const Color(0xFFc084fc),
            bgColor: const Color(0xFF2d1b4e),
            onTap: () => setState(() {
              _showType = ShowType.music;
              _eventCategory = 'music';
              _eventType = 'concert';
            }),
          ),
        ],
      ),
    );
  }

  Widget _typeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(child: Icon(icon, color: color, size: 26)),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppFontSize.xs,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Form ──
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          100,
        ),
        children: [
          // Cover image
          _buildCoverPicker(),
          const SizedBox(height: AppSpacing.xl),

          // Title
          _label('Title'),
          TextFormField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration:
                const InputDecoration(hintText: 'Give your show a name'),
            validator: (v) =>
                v != null && v.trim().isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Description
          _label('Description'),
          TextFormField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.text),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell people what to expect...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Type-specific fields
          if (_showType == ShowType.event) _buildEventFields(),
          if (_showType == ShowType.music) _buildMusicFields(),
          if (_showType == ShowType.exhibition) _buildExhibitionFields(),

          // Date & Time
          _label('Date & Time'),
          Row(
            children: [
              Expanded(
                child: _dateTile(
                  label: _startDate != null
                      ? DateFormat('MMM d, y').format(_startDate!)
                      : 'Start date',
                  icon: Icons.calendar_today_rounded,
                  onTap: () => _pickDate(isEnd: false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _dateTile(
                  label:
                      _startTime != null ? _startTime!.format(context) : 'Time',
                  icon: Icons.access_time_rounded,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _dateTile(
            label: _endDate != null
                ? 'Ends ${DateFormat('MMM d, y').format(_endDate!)}'
                : 'End date (optional)',
            icon: Icons.event_rounded,
            onTap: () => _pickDate(isEnd: true),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Location
          _label(_showType == ShowType.exhibition && _isVirtual
              ? 'Virtual URL'
              : 'Location'),
          if (_showType == ShowType.exhibition && _isVirtual)
            TextFormField(
              controller: _virtualUrlCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'https://...',
                prefixIcon:
                    Icon(Icons.link_rounded, color: AppColors.textMuted),
              ),
            )
          else
            TextFormField(
              controller: _locationCtrl,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Venue or address',
                prefixIcon: Icon(Icons.location_on_outlined,
                    color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Price
          _label('Pricing'),
          _buildPriceSection(),
          const SizedBox(height: AppSpacing.lg),

          // Online toggle (events only)
          if (_showType != ShowType.exhibition) ...[
            _toggleRow(
              'Online event',
              'This event takes place online',
              _isOnline,
              (v) => setState(() => _isOnline = v),
            ),
            if (_isOnline) ...[
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _linkCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  hintText: 'Event link (Zoom, YouTube, etc.)',
                  prefixIcon:
                      Icon(Icons.link_rounded, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Submit button ──
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.textInverse,
                disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    )
                  : const Text(
                      'Publish Show',
                      style: TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cover picker ──
  Widget _buildCoverPicker() {
    return GestureDetector(
      onTap: _pickCover,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.borderLight,
            style: _coverImage == null ? BorderStyle.solid : BorderStyle.none,
          ),
          image: _coverImage != null
              ? DecorationImage(
                  image: FileImage(_coverImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Add cover image',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: AppFontSize.xxs,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Event type fields ──
  Widget _buildEventFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Event Type'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _eventTypes.map((t) {
            final label = t[0].toUpperCase() + t.substring(1);
            final active = _eventType == t;
            return GestureDetector(
              onTap: () => setState(() => _eventType = t),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontSize: AppFontSize.xs,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? AppColors.textInverse
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Music type fields ──
  Widget _buildMusicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Music Type'),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _musicTypes.map((t) {
            final label = t.replaceAll('_', ' ');
            final display = label[0].toUpperCase() + label.substring(1);
            final active = _eventType == t;
            return GestureDetector(
              onTap: () => setState(() => _eventType = t),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFc084fc) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: active ? const Color(0xFFc084fc) : AppColors.border,
                  ),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: AppFontSize.xs,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Exhibition fields ──
  Widget _buildExhibitionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _toggleRow(
          'Virtual exhibition',
          'This exhibition is online only',
          _isVirtual,
          (v) => setState(() => _isVirtual = v),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Price section ──
  Widget _buildPriceSection() {
    return Column(
      children: [
        _toggleRow(
          'Free entry',
          'No ticket price',
          _isFree,
          (v) => setState(() => _isFree = v),
        ),
        if (!_isFree) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              // Currency picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currency,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.text, fontSize: 14),
                    items: _currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _currency = v ?? 'NOK'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(hintText: '0'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Helpers ──
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppFontSize.xs,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppFontSize.xxs,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal,
          ),
        ],
      ),
    );
  }
}
