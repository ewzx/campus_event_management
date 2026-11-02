import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/registration_service.dart';
import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../../../core/formatters.dart';
import '../../../models/event.dart';
import 'announcements_page.dart';
import 'create_event_page.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Future<void> _editEvent() async {
    final updated = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventPage(eventToEdit: widget.event),
      ),
    );

    if (updated != null && mounted) {
      // Send the edited event back to the list page.
      Navigator.pop(context, updated);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('This will delete "${widget.event.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Tell the previous page that this event was deleted.
      Navigator.pop(context, 'deleted');
    }
  }

  Widget _registrationTile(Map<String, dynamic> r) {
    final id = (r['participantId'] ?? '') as String;
    final shortId = id.length > 8 ? id.substring(0, 8) : id;

    final registeredAt = r['registeredAt'];
    final time = registeredAt is Timestamp
        ? '${formatDate(registeredAt.toDate())}, '
        '${formatTime(registeredAt.toDate())}'
        : '';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text('Participant $shortId'),
        subtitle: Text(time),
        trailing: Chip(label: Text('${r['status'] ?? ''}')),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(event.imageUrl),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(
                  Icons.calendar_today,
                  '${formatDate(event.dateTime)}, ${formatTime(event.dateTime)}',
                ),
                _infoRow(Icons.location_on, event.venue),
                _infoRow(
                  Icons.people,
                  '${event.registeredCount} / ${event.capacity} registered',
                ),
                const SizedBox(height: 6),
                Text(event.description),
                const Divider(height: 40),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Registration open'),
                  subtitle: const Text('Turn off to stop new registrations'),
                  value: event.registrationOpen,
                  onChanged: (value) {
                    setState(() {
                      event.registrationOpen = value;
                    });
                    EventService().updateEvent(event);
                  },
                ),
                const Divider(height: 40),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: RegistrationService().getRegistrations(event.eventId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final registrations = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registered participants (${registrations.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (registrations.isEmpty)
                          const Text('No registrations yet.'),
                        for (final r in registrations) _registrationTile(r),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AnnouncementsPage(event: widget.event),
                        ),
                      );
                    },
                    icon: const Icon(Icons.campaign),
                    label: const Text('Announcements'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _editEvent,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit event'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}