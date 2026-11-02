import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/event_service.dart';
import '../../../models/event.dart';
import '../widgets/organizer_event_card.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';

class OrganizerHomePage extends StatefulWidget {
  const OrganizerHomePage({super.key});

  @override
  State<OrganizerHomePage> createState() => _OrganizerHomePageState();
}

class _OrganizerHomePageState extends State<OrganizerHomePage> {
  final EventService _service = EventService();

  Future<void> _openCreateEvent() async {
    final created = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );

    if (created != null) {
      await _service.addEvent(created);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${created.title}" created')),
      );
    }
  }

  Future<void> _openDetails(Event event) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(builder: (context) => EventDetailPage(event: event)),
    );

    if (result == 'deleted') {
      await _service.deleteEvent(event.eventId);
    } else if (result is Event) {
      await _service.updateEvent(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<List<Event>>(
            stream: _service.getMyEvents(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!;
              events.sort((a, b) => a.dateTime.compareTo(b.dateTime));

              if (events.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No events yet. Tap "Create Event" to add your first one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return OrganizerEventCard(
                    event: event,
                    onTap: () => _openDetails(event),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
