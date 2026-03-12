// lib/screens/artwork/artwork_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/artwork_model.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tab_provider.dart';
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
  int _currentImageIndex = 0;

  void _navigateToArtist() {
    final artist = widget.artwork.artist;
    if (artist == null) return;
    final profileId = artist.id;
    if (profileId.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final myId = (auth.user?.id ?? '').toString();
    if (myId.isNotEmpty && profileId == myId) {
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      context.read<TabProvider>().switchToTab(4);
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ArtistProfileScreen(userId: profileId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final hasMultipleImages = artwork.images.length > 1;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
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
                    itemCount: artwork.images.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: artwork.images[i].url,
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
                      children: List.generate(artwork.images.length, (i) {
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
                    artwork.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),

                  // ── Year ───────────────────────────────────────────────────
                  if (artwork.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${artwork.year}',
                      style: const TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w300),
                    ),
                  ],

                  // ── Artist ─────────────────────────────────────────────────
                  if (artwork.artist != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    GestureDetector(
                      onTap: _navigateToArtist,
                      behavior: HitTestBehavior.opaque,
                      child: Row(children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceDim,
                          backgroundImage: artwork.artist!.avatar != null
                              ? CachedNetworkImageProvider(
                                  artwork.artist!.avatar!)
                              : null,
                          child: artwork.artist!.avatar == null
                              ? Text(
                                  artwork.artist!.displayLabel.isNotEmpty
                                      ? artwork.artist!.displayLabel[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppColors.teal, fontSize: 14))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          artwork.artist!.displayLabel,
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

                  // ── Engagement ─────────────────────────────────────────────
                  Row(children: [
                    _stat(Icons.favorite, '${artwork.likesCount}',
                        Colors.red[300]!),
                    const SizedBox(width: 16),
                    _stat(Icons.visibility, '${artwork.views}',
                        AppColors.textMuted),
                    const SizedBox(width: 16),
                    _stat(Icons.comment_outlined, '${artwork.commentsCount}',
                        AppColors.textMuted),
                  ]),

                  // ── Price ──────────────────────────────────────────────────
                  if (artwork.forSale) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                          color: AppColors.tealBg,
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Row(children: [
                        Text(
                          '${_currencySymbol(artwork.currency)} ${artwork.price.toStringAsFixed(0)}',
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
                  if (artwork.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      artwork.description,
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
                  _buildDetailsGrid(artwork),

                  // ── Tags ───────────────────────────────────────────────────
                  if (artwork.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: artwork.tags.map((t) => _tag(t)).toList(),
                    ),
                  ],

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
      final unit = d.unit ?? 'cm';
      if (parts.isNotEmpty) {
        details.add(_DetailItem(
            label: 'Dimensions', value: '${parts.join(' × ')} $unit'));
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
                      child: Text(
                        d.label,
                        style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        d.value,
                        style: const TextStyle(
                            fontSize: AppFontSize.sm,
                            color: AppColors.text,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _stat(IconData icon, String value, Color color) {
    return Row(children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(
              fontSize: AppFontSize.sm, color: AppColors.textSecondary)),
    ]);
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

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});
}
