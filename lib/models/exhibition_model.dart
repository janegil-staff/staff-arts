// lib/models/exhibition_model.dart

class ExhibitionModel {
  final String id;
  final String organizerId;
  final Map<String, dynamic>? organizer;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final List<String> artworkIds;
  final List<Map<String, dynamic>> artists;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final bool isVirtual;
  final String virtualUrl;
  final double ticketPrice;
  final bool isFree;
  final int attendeeCount;
  final bool isAttending;
  final String status;
  final bool isFeatured;
  final DateTime? createdAt;

  ExhibitionModel({
    required this.id,
    required this.organizerId,
    this.organizer,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.artworkIds = const [],
    this.artists = const [],
    required this.startDate,
    required this.endDate,
    this.location = '',
    this.isVirtual = false,
    this.virtualUrl = '',
    this.ticketPrice = 0,
    this.isFree = true,
    this.attendeeCount = 0,
    this.isAttending = false,
    this.status = 'upcoming',
    this.isFeatured = false,
    this.createdAt,
  });

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';

  factory ExhibitionModel.fromJson(Map<String, dynamic> json) {
    final organizerRaw = json['organizer'];

    final artistsList = (json['artists'] as List? ?? [])
        .map((a) => a is Map ? Map<String, dynamic>.from(a) : <String, dynamic>{})
        .toList();

    return ExhibitionModel(
      id: json['id'] ?? json['_id'] ?? '',
      organizerId: organizerRaw is Map
          ? (organizerRaw['id'] ?? organizerRaw['_id'] ?? '')
          : (organizerRaw ?? ''),
      organizer:
          organizerRaw is Map ? Map<String, dynamic>.from(organizerRaw) : null,
      title: json['title'] ?? '',
      description: json['description'],
      coverImageUrl: json['coverImage']?['url'],
      artworkIds: (json['artworks'] as List? ?? [])
          .map((a) => a is Map ? (a['id'] ?? a['_id'] ?? '') : a.toString())
          .cast<String>()
          .toList(),
      artists: artistsList,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      location: json['location'] ?? '',
      isVirtual: json['isVirtual'] ?? false,
      virtualUrl: json['virtualUrl'] ?? '',
      ticketPrice: (json['ticketPrice'] as num?)?.toDouble() ?? 0,
      isFree: json['isFree'] ?? true,
      attendeeCount: (json['attendees'] as List?)?.length ?? 0,
      isAttending: json['isAttending'] ?? false,
      status: json['status'] ?? 'upcoming',
      isFeatured: json['isFeatured'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
