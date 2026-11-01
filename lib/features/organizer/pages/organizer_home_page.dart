import 'package:flutter/material.dart';

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
  // Temporary in-memory list. Firestore will replace this later.
  final List<Event> _events = [];

  Future<void> _openCreateEvent() async {
    final created = await Navigator.push<Event>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );

    if (created != null && mounted) {
      setState(() => _events.insert(0, created));
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

    if (!mounted) return;

    setState(() {
      if (result == 'deleted') {
        _events.remove(event);
      } else if (result is Event) {
        final index = _events.indexOf(event);
        _events[index] = result;
      }
    });
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
          child: _events.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No events yet. Tap "Create Event" to add your first one.',
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return OrganizerEventCard(
                event: event,
                onTap: () => _openDetails(event),
              );
            },
          ),
        ),
      ),
    );
  }
}
