import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String announcementId;
  final String eventId;
  final String createdBy; // the organizer's uid
  final String message;
  final DateTime createdAt;

  Announcement({
    required this.announcementId,
    required this.eventId,
    required this.createdBy,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'eventId': eventId,
      'createdBy': createdBy,
      'message': message,
      'createdAt': createdAt,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      announcementId: map['announcementId'],
      eventId: map['eventId'],
      createdBy: map['createdBy'],
      message: map['message'],
      // Once Firestore is connected, change this line to:
      // (map['createdAt'] as Timestamp).toDate()
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}