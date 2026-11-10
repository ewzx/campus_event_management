import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('new event has the correct default values', () {
    final event = Event(
      eventId: 'e1',
      title: 'Tech Talk',
      description: 'A talk about technology',
      venue: 'Hall A',
      dateTime: DateTime(2026, 11, 5, 9, 30),
      capacity: 50,
      organizerId: 'o1',
    );

    expect(event.registeredCount, 0);
    expect(event.registrationOpen, true);
    expect(event.imageUrl, '');
    expect(event.staffIds, isEmpty);
  });

  test('toMap and fromMap keep the same data', () {
    final event = Event(
      eventId: 'e1',
      title: 'Tech Talk',
      description: 'A talk about technology',
      venue: 'Hall A',
      dateTime: DateTime(2026, 11, 5, 9, 30),
      capacity: 50,
      organizerId: 'o1',
    );

    final map = event.toMap();
    map['startTime'] = Timestamp.fromDate(event.dateTime);
    final copy = Event.fromMap(map);

    expect(copy.eventId, 'e1');
    expect(copy.title, 'Tech Talk');
    expect(copy.venue, 'Hall A');
    expect(copy.capacity, 50);
    expect(copy.dateTime, DateTime(2026, 11, 5, 9, 30));
  });

  test('status is saved as open or closed', () {
    final open = Event(
      eventId: 'e1',
      title: 'Tech Talk',
      description: 'A talk',
      venue: 'Hall A',
      dateTime: DateTime(2026, 11, 5, 9, 30),
      capacity: 50,
      organizerId: 'o1',
    );
    final closed = Event(
      eventId: 'e2',
      title: 'Career Fair',
      description: 'A fair',
      venue: 'Hall B',
      dateTime: DateTime(2026, 11, 12, 14, 0),
      capacity: 100,
      registrationOpen: false,
      organizerId: 'o1',
    );

    expect(open.toMap()['status'], 'open');
    expect(closed.toMap()['status'], 'closed');
  });

  test('fromMap can read an event written by another member', () {
    final map = {
      'title': 'Campus Photography Workshop',
      'description': 'Learn photography',
      'location': 'APU Campus B-04-05',
      'startTime': Timestamp.fromDate(DateTime(2026, 11, 8, 10, 0)),
      'capacity': 40,
      'registeredCount': 30,
      'status': 'open',
    };

    final event = Event.fromMap(map, id: 'abc123');

    expect(event.eventId, 'abc123');
    expect(event.venue, 'APU Campus B-04-05');
    expect(event.registeredCount, 30);
    expect(event.registrationOpen, true);
    expect(event.organizerId, '');
  });
}