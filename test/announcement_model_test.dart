import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/models/announcement.dart';

void main() {
  test('announcement keeps the same data after toMap and fromMap', () {
    final announcement = Announcement(
      announcementId: 'a1',
      eventId: 'e1',
      createdBy: 'o1',
      message: 'Venue has changed',
      createdAt: DateTime(2026, 11, 3, 15, 30),
    );

    final map = announcement.toMap();
    map['createdAt'] = Timestamp.fromDate(announcement.createdAt);
    final copy = Announcement.fromMap(map);

    expect(copy.announcementId, 'a1');
    expect(copy.eventId, 'e1');
    expect(copy.message, 'Venue has changed');
    expect(copy.createdAt, DateTime(2026, 11, 3, 15, 30));
  });
}