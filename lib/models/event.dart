import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String eventId;
  final String title;
  final String description;
  final String venue;
  final DateTime dateTime;
  final String imageUrl;
  final int capacity;
  final int registeredCount;
  bool registrationOpen;
  final String organizerId;
  final List<String> staffIds;

  Event({
    required this.eventId,
    required this.title,
    required this.description,
    required this.venue,
    required this.dateTime,
    this.imageUrl = '',
    required this.capacity,
    this.registeredCount = 0,
    this.registrationOpen = true,
    required this.organizerId,
    this.staffIds = const [],
  });

  // Turns Event into Map to save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'location': venue,
      'startTime': dateTime,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'status': registrationOpen ? 'open' : 'closed',
      'organizerId': organizerId,
      'staffIds': staffIds,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map, {String? id}) {
    return Event(
      eventId: id ?? map['eventId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      venue: map['location'] ?? '',
      dateTime: (map['startTime'] as Timestamp).toDate(),
      imageUrl: map['imageUrl'] ?? '',
      capacity: map['capacity'] ?? 0,
      registeredCount: map['registeredCount'] ?? 0,
      registrationOpen: (map['status'] ?? 'open') == 'open',
      organizerId: map['organizerId'] ?? '',
      staffIds: List<String>.from(map['staffIds'] ?? []),
    );
  }
}