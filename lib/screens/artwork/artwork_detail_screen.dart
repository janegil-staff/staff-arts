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
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: artwork.images.length,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: artwork.images[i].url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceDim),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artwork.title,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text)),

                  // Artist — tappable
                  if (artwork.artist != null) ...[
                    const SizedBox(height: AppSpacing.sm),
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
                        Text(artwork.artist!.displayLabel,
                            style: const TextStyle(
                                fontSize: AppFontSize.md,
                                color: AppColors.teal,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.teal),
                      ]),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Engagement
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

                  // Price
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

                  // Description
                  if (artwork.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(artwork.description,
                        style: const TextStyle(
                            fontSize: AppFontSize.md,
                            color: AppColors.textSecondary,
                            height: 1.6)),
                  ],

                  // Tags
                  if (artwork.medium.isNotEmpty ||
                      artwork.style.isNotEmpty ||
                      artwork.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (artwork.medium.isNotEmpty) _tag(artwork.medium),
                        if (artwork.style.isNotEmpty) _tag(artwork.style),
                        ...artwork.tags.map((t) => _tag(t)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
