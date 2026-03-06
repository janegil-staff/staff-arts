// lib/models/artwork_model.dart

// ─── ArtworkArtist ────────────────────────────────────────────────────────────
// Typed artist object so widgets can use .name, .displayName, .avatar directly

class ArtworkArtist {
  final String id;
  final String? name;
  final String? displayName;
  final String? avatar;
  final String? slug;

  ArtworkArtist({
    required this.id,
    this.name,
    this.displayName,
    this.avatar,
    this.slug,
  });

  String get displayLabel => displayName ?? name ?? '';

  factory ArtworkArtist.fromJson(Map<String, dynamic> json) {
    return ArtworkArtist(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      displayName: json['displayName'],
      avatar: json['avatar'],
      slug: json['slug'],
    );
  }
}

// ─── ArtworkImage ─────────────────────────────────────────────────────────────

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

  Map<String, dynamic> toJson() => {
        'url': url,
        'publicId': publicId,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (blurUrl != null) 'blurUrl': blurUrl,
      };
}

// ─── ArtworkDimensions ────────────────────────────────────────────────────────

class ArtworkDimensions {
  final double? width;
  final double? height;
  final double? depth;
  final String unit;

  ArtworkDimensions({this.width, this.height, this.depth, this.unit = 'in'});

  factory ArtworkDimensions.fromJson(Map<String, dynamic> json) {
    return ArtworkDimensions(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      depth: (json['depth'] as num?)?.toDouble(),
      unit: json['unit'] ?? 'in',
    );
  }
}

// ─── ArtworkModel ─────────────────────────────────────────────────────────────

class ArtworkModel {
  final String id;
  final String artistId;
  final ArtworkArtist? artist;
  final String title;
  final String description;
  final List<ArtworkImage> images;

  // Classification
  final String medium;
  final String style;
  final String subject;
  final List<String> materials;
  final List<String> categories;
  final List<String> tags;
  final List<String> aiTags;
  final String aiDescription;
  final String mood;
  final List<String> dominantColors;

  // Physical
  final ArtworkDimensions? dimensions;
  final int? year;
  final String edition;

  // Sale
  final bool forSale;
  final double price;
  final String currency;
  final bool isOriginal;
  final bool isPrint;
  final bool isDigital;
  final String shippingInfo;

  // Engagement
  final int views;
  final int likesCount;
  final int savesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;

  // Status
  final String status;
  final bool isFeatured;

  // Exhibition
  final String? exhibitionId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.materials = const [],
    this.categories = const [],
    this.tags = const [],
    this.aiTags = const [],
    this.aiDescription = '',
    this.mood = '',
    this.dominantColors = const [],
    this.dimensions,
    this.year,
    this.edition = '',
    this.forSale = false,
    this.price = 0,
    this.currency = 'USD',
    this.isOriginal = true,
    this.isPrint = false,
    this.isDigital = false,
    this.shippingInfo = '',
    this.views = 0,
    this.likesCount = 0,
    this.savesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.status = 'published',
    this.isFeatured = false,
    this.exhibitionId,
    this.createdAt,
    this.updatedAt,
  });

  // Both getters so widgets can use either
  String get mainImageUrl => images.isNotEmpty ? images.first.url : '';
  String get thumbnailUrl => mainImageUrl;
  String get blurHash => images.isNotEmpty ? (images.first.blurUrl ?? '') : '';

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    final artistRaw = json['artist'];
    return ArtworkModel(
      id: json['id'] ?? json['_id'] ?? '',
      artistId: artistRaw is Map
          ? (artistRaw['id'] ?? artistRaw['_id'] ?? '')
          : (artistRaw?.toString() ?? ''),
      artist: artistRaw is Map
          ? ArtworkArtist.fromJson(Map<String, dynamic>.from(artistRaw))
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List? ?? [])
          .map((i) => ArtworkImage.fromJson(i as Map<String, dynamic>))
          .toList(),
      medium: json['medium'] ?? '',
      style: json['style'] ?? '',
      subject: json['subject'] ?? '',
      materials: List<String>.from(json['materials'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      aiTags: List<String>.from(json['aiTags'] ?? []),
      aiDescription: json['aiDescription'] ?? '',
      mood: json['mood'] ?? '',
      dominantColors: List<String>.from(json['dominantColors'] ?? []),
      dimensions: json['dimensions'] != null
          ? ArtworkDimensions.fromJson(json['dimensions'])
          : null,
      year: json['year'],
      edition: json['edition'] ?? '',
      forSale: json['forSale'] ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'USD',
      isOriginal: json['isOriginal'] ?? true,
      isPrint: json['isPrint'] ?? false,
      isDigital: json['isDigital'] ?? false,
      shippingInfo: json['shippingInfo'] ?? '',
      views: json['views'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      savesCount: json['savesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      status: json['status'] ?? 'published',
      isFeatured: json['isFeatured'] ?? false,
      exhibitionId: json['exhibition'] is String ? json['exhibition'] : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}
