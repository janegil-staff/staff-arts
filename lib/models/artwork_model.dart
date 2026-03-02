// lib/models/artwork_model.dart
class ArtworkImage {
  final String url;
  final String publicId;
  final int? width;
  final int? height;
  final String? blurUrl;

  ArtworkImage({
    required this.url,
    required this.publicId,
    this.width,
    this.height,
    this.blurUrl,
  });

  factory ArtworkImage.fromJson(Map<String, dynamic> json) {
    return ArtworkImage(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
      width: json['width'],
      height: json['height'],
      blurUrl: json['blurUrl'],
    );
  }
}

class ArtworkModel {
  final String id;
  final String artistId;
  final ArtistSummary? artist;
  final String title;
  final String description;
  final List<ArtworkImage> images;
  final String medium;
  final String style;
  final String subject;
  final List<String> categories;
  final List<String> tags;
  final bool forSale;
  final double price;
  final String currency;
  final int views;
  final int likesCount;
  final int savesCount;
  final int commentsCount;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;

  ArtworkModel({
    required this.id,
    required this.artistId,
    this.artist,
    required this.title,
    this.description = '',
    required this.images,
    this.medium = '',
    this.style = '',
    this.subject = '',
    this.categories = const [],
    this.tags = const [],
    this.forSale = false,
    this.price = 0,
    this.currency = 'USD',
    this.views = 0,
    this.likesCount = 0,
    this.savesCount = 0,
    this.commentsCount = 0,
    this.status = 'published',
    this.isFeatured = false,
    required this.createdAt,
  });

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    // Handle artist being either a string ID or populated object
    String artistId;
    ArtistSummary? artist;
    final artistField = json['artist'] ?? json['artistId'];
    if (artistField is String) {
      artistId = artistField;
    } else if (artistField is Map<String, dynamic>) {
      artistId = artistField['_id'] ?? '';
      artist = ArtistSummary.fromJson(artistField);
    } else {
      artistId = '';
    }

    return ArtworkModel(
      id: json['_id'] ?? '',
      artistId: artistId,
      artist: artist,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List? ?? [])
          .map((i) => ArtworkImage.fromJson(i))
          .toList(),
      medium: json['medium'] ?? '',
      style: json['style'] ?? '',
      subject: json['subject'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      forSale: json['forSale'] ?? false,
      price: (json['price'] ?? json['pricing']?['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      views: json['views'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      savesCount: json['savesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      status: json['status'] ?? 'published',
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get mainImageUrl => images.isNotEmpty ? images.first.url : '';
}

class ArtistSummary {
  final String id;
  final String name;
  final String? displayName;
  final String? avatar;
  final String? slug;
  final String? username;

  ArtistSummary({
    required this.id,
    required this.name,
    this.displayName,
    this.avatar,
    this.slug,
    this.username,
  });

  factory ArtistSummary.fromJson(Map<String, dynamic> json) {
    return ArtistSummary(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'],
      avatar: json['avatar'],
      slug: json['slug'],
      username: json['username'],
    );
  }
}