import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_event_management/features/organizer/pages/create_event_page.dart';
import 'package:campus_event_management/features/organizer/widgets/organizer_event_card.dart';
import 'package:campus_event_management/models/event.dart';

Event sampleEvent({bool open = true}) {
  return Event(
    eventId: 'e1',
    title: 'Tech Talk',
    description: 'A talk about technology',
    venue: 'Hall A',
    dateTime: DateTime(2026, 11, 5, 9, 30),
    capacity: 50,
    registeredCount: 12,
    registrationOpen: open,
    organizerId: 'o1',
  );
}

void main() {
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

  testWidgets('edit mode fills the form with the existing event',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: CreateEventPage(eventToEdit: sampleEvent())),
        );

        expect(find.text('Edit Event'), findsOneWidget);
        expect(find.text('Save Changes'), findsOneWidget);
        expect(find.text('Tech Talk'), findsOneWidget);
        expect(find.text('Hall A'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
      });

  testWidgets('event card shows the event details and Open status',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: OrganizerEventCard(event: sampleEvent())),
          ),
        );

        expect(find.text('Tech Talk'), findsOneWidget);
        expect(find.text('Hall A'), findsOneWidget);
        expect(find.text('5 November 2026, 9:30 AM'), findsOneWidget);
        expect(find.text('12 / 50 registered'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
      });

  testWidgets('event card shows Closed when registration is off',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrganizerEventCard(event: sampleEvent(open: false)),
            ),
          ),
        );

        expect(find.text('Closed'), findsOneWidget);
      });
}