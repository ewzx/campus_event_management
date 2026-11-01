import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/models/event.dart';

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

    final copy = Event.fromMap(event.toMap());

    expect(copy.eventId, 'e1');
    expect(copy.title, 'Tech Talk');
    expect(copy.venue, 'Hall A');
    expect(copy.capacity, 50);
    expect(copy.dateTime, DateTime(2026, 11, 5, 9, 30));
  });
}