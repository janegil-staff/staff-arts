// lib/models/event_model.dart

class EventModel {
  final String id;
  final String organizerId;
  final Map<String, dynamic>? organizer;
  final String title;
  final String? description;
  final String type;
  final String category;
  final String? coverImageUrl;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final bool isOnline;
  final String? link;
  final int? maxAttendees;
  final int rsvpCount;
  final bool hasRsvp;
  final double price;
  final bool isFree;
  final String currency;
  final DateTime? createdAt;

  EventModel({
    required this.id,
    required this.organizerId,
    this.organizer,
    required this.title,
    this.description,
    this.type = 'other',
    this.category = 'event',
    this.coverImageUrl,
    required this.date,
    this.endDate,
    this.location = '',
    this.isOnline = false,
    this.link,
    this.maxAttendees,
    this.rsvpCount = 0,
    this.hasRsvp = false,
    this.price = 0,
    this.isFree = true,
    this.currency = 'NOK',
    this.createdAt,
  });

  bool get isUpcoming => date.isAfter(DateTime.now());

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final organizerRaw = json['organizer'];
    return EventModel(
      id: json['id'] ?? json['_id'] ?? '',
      organizerId: organizerRaw is Map
          ? (organizerRaw['id'] ?? organizerRaw['_id'] ?? '')
          : (organizerRaw ?? ''),
      organizer:
          organizerRaw is Map ? Map<String, dynamic>.from(organizerRaw) : null,
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'other',
      category: json['category'] ?? 'event',
      coverImageUrl: json['coverImage']?['url'],
      date: DateTime.parse(json['date']),
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      location: json['location'] ?? '',
      isOnline: json['isOnline'] ?? false,
      link: json['link'],
      maxAttendees: json['maxAttendees'],
      rsvpCount: (json['rsvps'] as List?)?.length ?? 0,
      hasRsvp: json['hasRsvp'] ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isFree: json['isFree'] ?? true,
      currency: json['currency'] ?? 'NOK',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
