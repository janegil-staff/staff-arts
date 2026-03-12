// lib/screens/artwork/artwork_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:staff_art/providers/artwork_provider.dart';
import '../../models/artwork_model.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../profile/artist_profile_screen.dart';

String _currencySymbol(String code) {
  const symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'NOK': 'kr',
    'SEK': 'kr',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'JPY': '¥',
    'CHF': 'Fr',
  };
  return symbols[code] ?? code;
}

class ArtworkDetailScreen extends StatefulWidget {
  final ArtworkModel artwork;
  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final _api = ApiService();
  late ArtworkModel _artwork;
  int _currentImageIndex = 0;
  bool _likeLoading = false;
  bool _saveLoading = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _artwork = widget.artwork;
    _fetchFresh();
  }

  // Fetch fresh artwork from backend so views, isLiked, isSaved are current
  Future<void> _fetchFresh() async {
    setState(() => _refreshing = true);
    try {
      final res = await _api.get(ApiConfig.artwork(_artwork.id));
      final data = res.data['data'] ?? res.data;
      if (mounted) {
        setState(() => _artwork = ArtworkModel.fromJson(data));
      }
    } catch (e) {
      debugPrint('ArtworkDetail refresh error: $e');
    }
    if (mounted) setState(() => _refreshing = false);
  }

  void _navigateToArtist() {
    final artist = _artwork.artist;
    if (artist == null) return;
    final profileId = artist.id;
    if (profileId.isEmpty) return;

    final myId = (context.read<AuthProvider>().user?.id ?? '').toString();
    if (myId.isNotEmpty && profileId == myId) {
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      context.read<TabProvider>().switchToTab(4);
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ArtistProfileScreen(userId: profileId)),
    );
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;
    setState(() => _likeLoading = true);
    final wasLiked = _artwork.isLiked;
    // Optimistic update
    setState(() {
      _artwork = _artwork.copyWith(
        isLiked: !wasLiked,
        likesCount:
            wasLiked ? _artwork.likesCount - 1 : _artwork.likesCount + 1,
      );
    });
    try {
      await _api.post(ApiConfig.artworkLike(_artwork.id));
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _artwork = _artwork.copyWith(
            isLiked: wasLiked,
            likesCount:
                wasLiked ? _artwork.likesCount + 1 : _artwork.likesCount - 1,
          );
        });
      }
    }
    if (mounted) setState(() => _likeLoading = false);
  }

  Future<void> _toggleSave() async {
    if (_saveLoading) return;
    setState(() => _saveLoading = true);
    final wasSaved = _artwork.isSaved;
    setState(() {
      _artwork = _artwork.copyWith(
        isSaved: !wasSaved,
        savesCount:
            wasSaved ? _artwork.savesCount - 1 : _artwork.savesCount + 1,
      );
    });
    try {
      await _api.post(ApiConfig.artworkSave(_artwork.id));
    } catch (_) {
      if (mounted) {
        setState(() {
          _artwork = _artwork.copyWith(
            isSaved: wasSaved,
            savesCount:
                wasSaved ? _artwork.savesCount + 1 : _artwork.savesCount - 1,
          );
        });
      }
    }
    if (mounted) setState(() => _saveLoading = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Artwork',
            style: TextStyle(color: AppColors.text)),
        content: Text(
          'Are you sure you want to delete "${_artwork.title}"? This cannot be undone.',
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
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.delete(ApiConfig.artwork(_artwork.id));
      if (mounted) {
        context.read<ArtworkProvider>().removeArtwork(_artwork.id);
        Navigator.of(context).pop();
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
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CommentsSheet(artworkId: _artwork.id),
    ).then((_) {
      // Refresh comment count after sheet closes
      _fetchFresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = _artwork.images.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.teal),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ──────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 400,
                  child: PageView.builder(
                    itemCount: _artwork.images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _artwork.images[i].url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceDim),
                    ),
                  ),
                ),
                if (hasMultipleImages)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_artwork.images.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i
                                ? AppColors.teal
                                : AppColors.textMuted.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────────────
                  Text(
                    _artwork.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),

                  // ── Year ───────────────────────────────────────────────────
                  if (_artwork.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_artwork.year}',
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w300),
                    ),
                  ],

                  // ── Artist ─────────────────────────────────────────────────
                  if (_artwork.artist != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: _navigateToArtist,
                      behavior: HitTestBehavior.opaque,
                      child: Row(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceDim,
                          backgroundImage: _artwork.artist!.avatar != null
                              ? CachedNetworkImageProvider(
                                  _artwork.artist!.avatar!)
                              : null,
                          child: _artwork.artist!.avatar == null
                              ? Text(
                                  _artwork.artist!.displayLabel.isNotEmpty
                                      ? _artwork.artist!.displayLabel[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.teal, fontSize: 14))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _artwork.artist!.displayLabel,
                          style: const TextStyle(
                              fontSize: AppFontSize.md,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.teal),
                      ]),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // ── Engagement row ─────────────────────────────────────────
                  Row(
                    children: [
                      _EngagementButton(
                        icon: _artwork.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        count: _artwork.likesCount,
                        color: _artwork.isLiked
                            ? Colors.red[400]!
                            : AppColors.textMuted,
                        loading: _likeLoading,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _EngagementButton(
                        icon: Icons.visibility_outlined,
                        count: _artwork.views,
                        color: AppColors.textMuted,
                        onTap: null,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _EngagementButton(
                        icon: Icons.comment_outlined,
                        count: _artwork.commentsCount,
                        color: AppColors.textMuted,
                        onTap: _openComments,
                      ),
                      const Spacer(),
                      _EngagementButton(
                        icon: _artwork.isSaved
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        count: _artwork.savesCount,
                        color: _artwork.isSaved
                            ? AppColors.teal
                            : AppColors.textMuted,
                        loading: _saveLoading,
                        onTap: _toggleSave,
                      ),
                    ],
                  ),

                  // ── Price ──────────────────────────────────────────────────
                  if (_artwork.forSale) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                          color: AppColors.tealBg,
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [
                        Text(
                          '${_currencySymbol(_artwork.currency)} ${_artwork.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: AppFontSize.xl,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12)),
                          child: const Text('Buy Now'),
                        ),
                      ]),
                    ),
                  ],

                  // ── Description ────────────────────────────────────────────
                  if (_artwork.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _artwork.description,
                      style: const TextStyle(
                          fontSize: AppFontSize.md,
                          color: AppColors.textSecondary,
                          height: 1.6),
                    ),
                  ],

                  // ── Details ────────────────────────────────────────────────
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Details',
                    style: TextStyle(
                        fontSize: AppFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailsGrid(_artwork),

                  // ── Tags ───────────────────────────────────────────────────
                  if (_artwork.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _artwork.tags.map((t) => _tag(t)).toList(),
                    ),
                  ],

                  // ── Delete (owner only) ────────────────────────────────────
                  Builder(builder: (context) {
                    final myId = context.read<AuthProvider>().user?.id ?? '';
                    final artistId = _artwork.artist?.id ?? '';
                    if (myId.isEmpty || artistId != myId) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error, size: 18),
                          label: const Text('Delete Artwork',
                              style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(ArtworkModel artwork) {
    final details = <_DetailItem>[];
    if (artwork.medium.isNotEmpty) {
      details.add(_DetailItem(label: 'Medium', value: artwork.medium));
    }
    if (artwork.style.isNotEmpty) {
      details.add(_DetailItem(label: 'Style', value: artwork.style));
    }
    if (artwork.categories.isNotEmpty) {
      details.add(
          _DetailItem(label: 'Category', value: artwork.categories.join(', ')));
    }
    if (artwork.year != null) {
      details.add(_DetailItem(label: 'Year', value: '${artwork.year}'));
    }
    if (artwork.dimensions != null) {
      final d = artwork.dimensions!;
      final parts = <String>[];
      if (d.width != null) parts.add('W ${d.width}');
      if (d.height != null) parts.add('H ${d.height}');
      if (d.depth != null) parts.add('D ${d.depth}');
      if (parts.isNotEmpty) {
        details.add(_DetailItem(
            label: 'Dimensions', value: '${parts.join(' × ')} ${d.unit}'));
      }
    }
    if (details.isEmpty) return const SizedBox.shrink();
    return Column(
      children: details
          .map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(d.label,
                          style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w400)),
                    ),
                    Expanded(
                      child: Text(d.value,
                          style: const TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.text,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border)),
      child: Text(label,
          style: const TextStyle(
              fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
    );
  }
}

// ─── Engagement Button ────────────────────────────────────────────────────────

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _EngagementButton({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: color),
                  )
                : Icon(icon, size: 22, color: color),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: onTap != null ? AppColors.text : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comments Sheet ───────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final String artworkId;
  const _CommentsSheet({required this.artworkId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/api/artworks/${widget.artworkId}/comments');
      final list = res.data['data'] as List? ?? [];
      setState(() => _comments = List<Map<String, dynamic>>.from(list));
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() => _sending = true);
    try {
      final res = await _api.post('/api/artworks/${widget.artworkId}/comments',
          data: {'text': text});
      final comment = res.data['data'] as Map<String, dynamic>;
      setState(() => _comments.insert(0, comment));
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Comments',
                style: TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 0, color: AppColors.borderLight),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.teal, strokeWidth: 2))
                  : _comments.isEmpty
                      ? const Center(
                          child: Text('No comments yet',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: AppColors.borderLight),
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            final sender = c['user'] ?? c['sender'] ?? {};
                            final name = sender is Map
                                ? (sender['displayName'] ??
                                    sender['name'] ??
                                    'Unknown')
                                : 'Unknown';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.surfaceDim,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.teal),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.text)),
                                        const SizedBox(height: 2),
                                        Text(c['text'] ?? '',
                                            style: const TextStyle(
                                                fontSize: AppFontSize.sm,
                                                color: AppColors.textSecondary,
                                                height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 0, color: AppColors.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: AppFontSize.sm),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _sending
                              ? AppColors.teal.withValues(alpha: 0.4)
                              : AppColors.teal),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.arrow_upward_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});
}
