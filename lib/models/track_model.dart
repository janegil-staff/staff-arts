// lib/models/track_model.dart

class TrackModel {
  final String id;
  final String title;
  final String artistId;
  final Map<String, dynamic>? artist;
  final String? artistName;
  final String audioUrl;
  final String? coverUrl;
  final int? duration; // seconds
  final String? genre;
  final int plays;
  final DateTime? createdAt;

  TrackModel({
    required this.id,
    required this.title,
    required this.artistId,
    this.artist,
    this.artistName,
    required this.audioUrl,
    this.coverUrl,
    this.duration,
    this.genre,
    this.plays = 0,
    this.createdAt,
  });

  String get durationFormatted {
    if (duration == null) return '';
    final m = duration! ~/ 60;
    final s = duration! % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    final artistRaw = json['artist'];
    return TrackModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      artistId: artistRaw is Map
          ? (artistRaw['id'] ?? artistRaw['_id'] ?? '')
          : (artistRaw ?? ''),
      artist:
          artistRaw is Map ? Map<String, dynamic>.from(artistRaw) : null,
      artistName: json['artistName'],
      audioUrl: json['audioUrl'] ?? '',
      coverUrl: json['coverUrl'],
      duration: json['duration'],
      genre: json['genre'],
      plays: json['plays'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
