// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? displayName;
  final String? username;
  final String? slug;
  final String role;
  final String? avatar;
  final String? coverImage;
  final String? bio;
  final String? location;
  final String website;
  final bool verified;
  final Map<String, String> socialLinks;
  final List<String> mediums;
  final List<String> styles;
  final bool isAvailableForCommission;
  final int followerCount;
  final int followingCount;
  final int artworkCount;
  final bool isFeatured;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.displayName,
    this.username,
    this.slug,
    this.role = 'collector',
    this.avatar,
    this.coverImage,
    this.bio,
    this.location,
    this.website = '',
    this.verified = false,
    this.socialLinks = const {},
    this.mediums = const [],
    this.styles = const [],
    this.isAvailableForCommission = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.artworkCount = 0,
    this.isFeatured = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      displayName: json['displayName'],
      username: json['username'],
      slug: json['slug'],
      role: json['role'] ?? 'collector',
      avatar: json['avatar'],
      coverImage: json['coverImage'],
      bio: json['bio'],
      location: json['location'],
      website: json['website'] ?? '',
      verified: json['verified'] ?? json['isVerified'] ?? false,
      socialLinks: Map<String, String>.from(json['socialLinks'] ?? {}),
      mediums: List<String>.from(json['mediums'] ?? []),
      styles: List<String>.from(json['styles'] ?? []),
      isAvailableForCommission: json['isAvailableForCommission'] ?? false,
      followerCount: json['followerCount'] ?? json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      artworkCount: json['artworkCount'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  String get displayLabel => displayName ?? username ?? name ?? email;
}