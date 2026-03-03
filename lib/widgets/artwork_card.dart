// lib/widgets/artwork_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artwork_model.dart';
import '../theme/app_theme.dart';

String _currencySymbol(String code) {
  const symbols = {
    'USD': '\$',
    'EUR': '\u20ac',
    'GBP': '\u00a3',
    'NOK': 'kr',
    'SEK': 'kr',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'JPY': '\u00a5',
    'CHF': 'Fr',
  };
  return symbols[code] ?? code;
}

class ArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback? onTap;
  final double? width;

  const ArtworkCard({
    super.key,
    required this.artwork,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: CachedNetworkImage(
                  imageUrl: artwork.mainImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceDim),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceDim,
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              artwork.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
            if (artwork.artist != null) ...[
              const SizedBox(height: 2),
              Text(
                artwork.artist!.displayName ?? artwork.artist!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSize.xs,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (artwork.forSale && artwork.price > 0) ...[
              const SizedBox(height: 2),
              Text(
                '${_currencySymbol(artwork.currency)} ${artwork.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                ),
              ),
            ] else if (artwork.forSale) ...[
              const SizedBox(height: 2),
              const Text(
                'Price on request',
                style: TextStyle(
                  fontSize: AppFontSize.xs,
                  color: AppColors.teal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Featured card for horizontal carousel
class FeaturedArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final double cardWidth;
  final VoidCallback? onTap;

  const FeaturedArtworkCard({
    super.key,
    required this.artwork,
    required this.cardWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: cardWidth,
              height: cardWidth * 1.15,
              child: CachedNetworkImage(
                imageUrl: artwork.mainImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceDim),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceDim),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.md,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  if (artwork.artist != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      artwork.artist!.displayName ?? artwork.artist!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (artwork.forSale && artwork.price > 0)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
                child: Text(
                  '${_currencySymbol(artwork.currency)} ${artwork.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
