// lib/screens/upload/upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chip.dart';

const _categories = [
  'Painting', 'Sculpture', 'Photography', 'Digital', 'Drawing',
  'Print', 'Mixed Media', 'Installation', 'Textile', 'Ceramic',
];

const _mediums = [
  'Oil', 'Acrylic', 'Watercolor', 'Charcoal', 'Ink', 'Pastel',
  'Graphite', 'Digital', 'Photography', 'Bronze', 'Clay', 'Wood',
  'Mixed Media', 'Other',
];

const _styles = [
  'Abstract', 'Realism', 'Impressionism', 'Minimalism', 'Surrealism',
  'Pop Art', 'Contemporary', 'Expressionism', 'Cubism', 'Street Art',
  'Folk Art', 'Figurative', 'Conceptual',
];

const _currencies = [
  {'code': 'USD', 'symbol': '\$', 'label': 'USD (\$)'},
  {'code': 'EUR', 'symbol': '€', 'label': 'EUR (€)'},
  {'code': 'GBP', 'symbol': '£', 'label': 'GBP (£)'},
  {'code': 'NOK', 'symbol': 'kr', 'label': 'NOK (kr)'},
  {'code': 'SEK', 'symbol': 'kr', 'label': 'SEK (kr)'},
  {'code': 'CAD', 'symbol': '\$', 'label': 'CAD (\$)'},
  {'code': 'AUD', 'symbol': '\$', 'label': 'AUD (\$)'},
  {'code': 'JPY', 'symbol': '¥', 'label': 'JPY (¥)'},
  {'code': 'CHF', 'symbol': 'Fr', 'label': 'CHF (Fr)'},
];

const _units = [
  {'code': 'cm', 'label': 'cm'},
  {'code': 'in', 'label': 'inches'},
  {'code': 'mm', 'label': 'mm'},
];

const _depthCategories = ['Sculpture', 'Installation', 'Ceramic', 'Mixed Media', 'Textile'];

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _api = ApiService();
  final _picker = ImagePicker();

  // Form state
  final List<XFile> _images = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _yearController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _priceController = TextEditingController();

  String _category = '';
  String _medium = '';
  String _style = '';
  String _dimUnit = 'cm';
  bool _forSale = false;
  String _currency = 'USD';
  bool _uploading = false;
  String _progress = '';

  bool get _showDepth => _depthCategories.contains(_category);

  Map<String, String> get _activeCurrency {
    return _currencies.firstWhere(
      (c) => c['code'] == _currency,
      orElse: () => _currencies.first,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _yearController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = 8 - _images.length;
    if (remaining <= 0) {
      _showAlert('Limit reached', 'Maximum 8 images allowed');
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 80, limit: remaining);
      if (picked.isNotEmpty) {
        setState(() {
          _images.addAll(picked.take(remaining));
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Map<String, dynamic>? _buildDimensions() {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_widthController.text);
    if (h == null && w == null) return null;
    final dims = <String, dynamic>{'unit': _dimUnit};
    if (h != null) dims['height'] = h;
    if (w != null) dims['width'] = w;
    if (_showDepth) {
      final d = double.tryParse(_depthController.text);
      if (d != null) dims['depth'] = d;
    }
    return dims;
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return _showAlert('Required', 'Enter a title');
    if (_images.isEmpty) return _showAlert('Required', 'Add at least one image');
    if (_forSale) {
      final price = double.tryParse(_priceController.text);
      if (price == null) return _showAlert('Required', 'Enter a valid price');
    }

    setState(() {
      _uploading = true;
      _progress = '';
    });

    try {
      // 1. Upload images to Cloudinary via backend
      final uploadedImages = <Map<String, dynamic>>[];
      for (var i = 0; i < _images.length; i++) {
        setState(() => _progress = 'Uploading image ${i + 1} of ${_images.length}...');

        final file = _images[i];
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
          'folder': 'artworks',
        });

        final res = await _api.post(ApiConfig.uploadImage, data: formData);
        final data = res.data['data'] ?? res.data;
        uploadedImages.add({
          'url': data['url'],
          'publicId': data['publicId'],
          'width': data['width'],
          'height': data['height'],
        });
      }

      // 2. Create artwork
      setState(() => _progress = 'Saving artwork...');

      final yearText = _yearController.text.trim();
      await _api.post(ApiConfig.artworks, data: {
        'title': title,
        'description': _descController.text.trim(),
        'images': uploadedImages,
        'category': _category,
        'medium': _medium,
        'style': _style,
        if (yearText.isNotEmpty) 'year': int.tryParse(yearText),
        'dimensions': _buildDimensions(),
        'forSale': _forSale,
        'price': _forSale ? double.tryParse(_priceController.text) ?? 0 : 0,
        'currency': _currency,
      });

      // 3. Reset form
      _resetForm();

      if (!mounted) return;
      _showAlert('Success', 'Artwork uploaded!');
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return;
      String msg = 'Something went wrong';
      if (e is DioException) {
        msg = e.response?.data?['error'] ?? e.message ?? msg;
      }
      _showAlert('Upload failed', msg);
    }

    setState(() {
      _uploading = false;
      _progress = '';
    });
  }

  void _resetForm() {
    setState(() {
      _images.clear();
      _titleController.clear();
      _descController.clear();
      _yearController.clear();
      _heightController.clear();
      _widthController.clear();
      _depthController.clear();
      _priceController.clear();
      _category = '';
      _medium = '';
      _style = '';
      _dimUnit = 'cm';
      _forSale = false;
      _currency = 'USD';
    });
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.text)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Center(
        child: Text('Sign in to upload artwork', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Text('✕', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('New Artwork', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // ── Images ──
            _label('Images'),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('+', style: TextStyle(fontSize: 28, color: AppColors.teal)),
                          SizedBox(height: 2),
                          Text('Add', style: TextStyle(fontSize: 12, color: AppColors.teal)),
                        ],
                      ),
                    ),
                  ),
                  // Thumbnails
                  ..._images.asMap().entries.map((entry) {
                    final i = entry.key;
                    final img = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.file(File(img.path), width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(i),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                                child: const Center(
                                  child: Text('✕', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // ── Title ──
            _label('Title'),
            _input(_titleController, 'Artwork title'),

            // ── Description ──
            _label('Description'),
            _input(_descController, 'Tell us about this piece...', maxLines: 4),

            // ── Year ──
            _label('Year'),
            _input(_yearController, '2025', keyboardType: TextInputType.number),

            // ── Category ──
            _label('Category'),
            _chipRow(_categories, _category, (v) => setState(() => _category = _category == v ? '' : v)),

            // ── Medium ──
            _label('Medium'),
            _chipRow(_mediums, _medium, (v) => setState(() => _medium = _medium == v ? '' : v)),

            // ── Style ──
            _label('Style'),
            _chipRow(_styles, _style, (v) => setState(() => _style = _style == v ? '' : v)),

            // ── Dimensions ──
            _label('Dimensions'),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('Optional — helps collectors assess the piece', style: TextStyle(fontSize: AppFontSize.xs, color: AppColors.textMuted)),
            ),
            _chipRow(
              _units.map((u) => u['label']!).toList(),
              _units.firstWhere((u) => u['code'] == _dimUnit)['label']!,
              (label) {
                final unit = _units.firstWhere((u) => u['label'] == label);
                setState(() => _dimUnit = unit['code']!);
              },
              small: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _dimField('H', _heightController),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('×', style: TextStyle(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                ),
                _dimField('W', _widthController),
                if (_showDepth) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('×', style: TextStyle(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                  ),
                  _dimField('D', _depthController),
                ],
              ],
            ),

            // ── For Sale ──
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('List for sale', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.text, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text('Set a price for collectors', style: TextStyle(fontSize: AppFontSize.xs, color: AppColors.textMuted)),
                    ],
                  ),
                  Switch(
                    value: _forSale,
                    onChanged: (v) => setState(() => _forSale = v),
                    activeColor: AppColors.teal,
                    activeTrackColor: AppColors.tealBg,
                    inactiveThumbColor: AppColors.textMuted,
                    inactiveTrackColor: AppColors.border,
                  ),
                ],
              ),
            ),

            // ── Sale Fields ──
            if (_forSale) ...[
              _label('Currency'),
              _chipRow(
                _currencies.map((c) => c['label']!).toList(),
                _activeCurrency['label']!,
                (label) {
                  final cur = _currencies.firstWhere((c) => c['label'] == label);
                  setState(() => _currency = cur['code']!);
                },
              ),
              _label('Price (${_activeCurrency['symbol']})'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Text(_activeCurrency['symbol']!, style: const TextStyle(fontSize: AppFontSize.lg, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: AppColors.text, fontSize: AppFontSize.md),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent, filled: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    Text(_currency, style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],

            // ── Submit ──
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.6)),
                child: _uploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse)),
                          const SizedBox(width: AppSpacing.sm),
                          Text(_progress.isNotEmpty ? _progress : 'Uploading...'),
                        ],
                      )
                    : const Text('Upload Artwork'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(text, style: const TextStyle(fontSize: AppFontSize.sm, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _input(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.text, fontSize: AppFontSize.md),
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _chipRow(List<String> items, String selected, void Function(String) onTap, {bool small = false}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppChip(label: item, active: selected == item, onTap: () => onTap(item), small: small),
          );
        }).toList(),
      ),
    );
  }

  Widget _dimField(String label, TextEditingController controller) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: AppFontSize.xs, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text, fontSize: AppFontSize.md),
                decoration: const InputDecoration(
                  hintText: '0', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent, filled: true, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Text(_dimUnit, style: const TextStyle(fontSize: AppFontSize.xs, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
