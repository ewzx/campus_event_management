
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/pages/auth_entry_page.dart';
import '../services/event_service.dart';
import '../../../models/event.dart';
import '../widgets/organizer_event_card.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';

class OrganizerHomePage extends StatefulWidget {
  const OrganizerHomePage({super.key});

  @override
  State<OrganizerHomePage> createState() =>
      _OrganizerHomePageState();
}

class _OrganizerHomePageState extends State<OrganizerHomePage> {
  final EventService _service = EventService();

  bool _isLoggingOut = false;

  // Log out the current user.
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    // Hide the current page and dispose Firestore listeners.
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Wait for the loading page to replace the current UI.
      await WidgetsBinding.instance.endOfFrame;

      // Sign out from Firebase Authentication.
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Clear the navigation stack and return to Welcome Page.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthEntryPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventPage(),
      ),
    );

    if (created == null || !mounted) return;

    try {
      await _service.addEvent(created);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${created.title}" created successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );

      debugPrint('Create event error: $e');
    }
  }

  Future<void> _openDetails(Event event) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
      ),
    );

    try {
      if (result == 'deleted') {
        await _service.deleteEvent(event.eventId);
      } else if (result is Event) {
        await _service.updateEvent(result);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while logging out.
    // This removes the Firestore StreamBuilder from the widget tree.
    if (_isLoggingOut) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access your events.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: StreamBuilder<List<Event>>(
            stream: _service.getMyEvents(user.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final events = [...snapshot.data!];

              events.sort(
                (a, b) => a.dateTime.compareTo(b.dateTime),
              );

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
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  90,
                ),
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
