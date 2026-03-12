// lib/screens/profile/my_artworks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/artwork_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../artwork/artwork_detail_screen.dart';

class MyArtworksScreen extends StatefulWidget {
  const MyArtworksScreen({super.key});

  @override
  State<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends State<MyArtworksScreen> {
  final _api = ApiService();
  List<ArtworkModel> _artworks = [];
  bool _loading = true;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final myId = context.read<AuthProvider>().user!.id;
      debugPrint('MyId: $myId');
      final res = await _api.get(ApiConfig.userArtworks(myId));
      final list = res.data['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _artworks =
              list.map<ArtworkModel>((j) => ArtworkModel.fromJson(j)).toList();
        });
      }
    } catch (e) {
      debugPrint('MyArtworks load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmDelete(ArtworkModel artwork) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Artwork',
            style: TextStyle(color: AppColors.text)),
        content: Text(
          'Are you sure you want to delete "${artwork.title}"? This cannot be undone.',
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
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _delete(artwork);
  }

  Future<void> _delete(ArtworkModel artwork) async {
    setState(() => _deleting.add(artwork.id));
    try {
      await _api.delete(ApiConfig.artwork(artwork.id));
      if (mounted) {
        setState(() => _artworks.removeWhere((a) => a.id == artwork.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _deleting.remove(artwork.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Artworks',
            style: TextStyle(fontWeight: FontWeight.w300)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.teal, strokeWidth: 2))
          : _artworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDim,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Icon(Icons.palette_outlined,
                            size: 32, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text('No artworks yet',
                          style: TextStyle(
                              fontSize: AppFontSize.lg,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Upload your first artwork',
                          style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.teal,
                  backgroundColor: AppColors.surface,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    itemCount: _artworks.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 0, color: AppColors.borderLight),
                    itemBuilder: (_, i) => _buildRow(_artworks[i]),
                  ),
                ),
    );
  }

  Widget _buildRow(ArtworkModel artwork) {
    final isDeleting = _deleting.contains(artwork.id);
    final imageUrl =
        artwork.images.isNotEmpty ? artwork.images.first.url : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArtworkDetailScreen(artwork: artwork)),
      ).then((_) => _load()),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceDim),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceDim,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.textMuted),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (artwork.medium.isNotEmpty) ...[
                        Text(artwork.medium,
                            style: const TextStyle(
                                fontSize: AppFontSize.xs,
                                color: AppColors.textMuted)),
                        const Text('  ·  ',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                      _statusBadge(artwork.status),
                    ],
                  ),
                  if (artwork.forSale) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${artwork.currency} ${artwork.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: AppFontSize.xs,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            // Delete button
            isDeleting
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 22),
                    onPressed: () => _confirmDelete(artwork),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Color color;
    switch (status) {
      case 'published':
      case 'available':
        color = AppColors.teal;
        break;
      case 'sold':
        color = const Color(0xFF60a5fa);
        break;
      case 'draft':
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
