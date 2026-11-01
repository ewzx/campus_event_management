import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/features/organizer/pages/announcements_page.dart';
import 'package:campus_event_management/features/organizer/pages/create_event_page.dart';
import 'package:campus_event_management/features/organizer/pages/organizer_home_page.dart';
import 'package:campus_event_management/models/event.dart';

void main() {
  testWidgets('organizer home shows a message when there are no events',
          (tester) async {
        await tester.pumpWidget(const MaterialApp(home: OrganizerHomePage()));

        expect(find.text('My Events'), findsOneWidget);
        expect(
          find.text('No events yet. Tap "Create Event" to add your first one.'),
          findsOneWidget,
        );
      });

  testWidgets('create event form shows errors when it is empty',
          (tester) async {
        await tester.pumpWidget(const MaterialApp(home: CreateEventPage()));

        final saveButton = find.widgetWithText(FilledButton, 'Create Event');
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await tester.pump();

        expect(find.text('Please enter a title'), findsOneWidget);
        expect(find.text('Please enter a description'), findsOneWidget);
        expect(find.text('Please enter a venue'), findsOneWidget);
        expect(find.text('Enter a whole number greater than 0'), findsOneWidget);
        expect(
          find.text('Please choose both a date and a time'),
          findsOneWidget,
        );
      });

  testWidgets('create event form rejects a capacity of 0', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateEventPage()));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Capacity (number of seats)'),
      '0',
    );

    final saveButton = find.widgetWithText(FilledButton, 'Create Event');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Enter a whole number greater than 0'), findsOneWidget);
  });

  testWidgets('announcements page rejects an empty message', (tester) async {
    final event = Event(
      eventId: 'e1',
      title: 'Tech Talk',
      description: 'A talk',
      venue: 'Hall A',
      dateTime: DateTime(2026, 11, 5, 9, 30),
      capacity: 50,
      organizerId: 'o1',
    );

    await tester.pumpWidget(MaterialApp(home: AnnouncementsPage(event: event)));

    await tester.tap(find.widgetWithText(FilledButton, 'Send announcement'));
    await tester.pump();

    expect(find.text('Please write a message first'), findsOneWidget);
  });

  testWidgets('announcements page shows a sent message', (tester) async {
    final event = Event(
      eventId: 'e2',
      title: 'Career Fair',
      description: 'A fair',
      venue: 'Hall B',
      dateTime: DateTime(2026, 11, 12, 14, 0),
      capacity: 100,
      organizerId: 'o1',
    );

    await tester.pumpWidget(MaterialApp(home: AnnouncementsPage(event: event)));

    await tester.enterText(find.byType(TextField), 'Venue has changed');
    await tester.tap(find.widgetWithText(FilledButton, 'Send announcement'));
    await tester.pump();

    expect(find.text('Venue has changed'), findsOneWidget);
  });
}