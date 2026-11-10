
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/registration_service.dart';
import '../services/event_service.dart';
import '../../../core/formatters.dart';
import '../../../models/event.dart';
import 'announcements_page.dart';
import 'create_event_page.dart';
import '../../../core/open_maps.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final EventService _eventService = EventService();

  bool _updatingRegistration = false;
  bool _deletingEvent = false;

  // Edit event.
  Future<void> _editEvent() async {
    final updated = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventPage(
          eventToEdit: widget.event,
        ),
      ),
    );

    if (updated != null && mounted) {
      Navigator.pop(context, updated);
    }
  }

  // Update registration status.
  Future<void> _toggleRegistration(bool value) async {
    final event = widget.event;
    final oldValue = event.registrationOpen;

    setState(() {
      _updatingRegistration = true;
      event.registrationOpen = value;
    });

    try {
      await _eventService.updateEvent(event);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Registration is now open.'
                : 'Registration is now closed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        event.registrationOpen = oldValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingRegistration = false;
        });
      }
    }
  }

  // Confirm and delete event.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          'Are you sure you want to delete "${widget.event.title}"?\n\n'
          'All registrations and announcements will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingEvent = true;
    });

    try {
      await _eventService.deleteEvent(widget.event.eventId);

      if (!mounted) return;

      // Return to the organizer event list.
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingEvent = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Display a registration record.
  Widget _registrationTile(Map<String, dynamic> r) {
    final id = (r['participantId'] ?? '') as String;

    final shortId = id.length > 8
        ? id.substring(0, 8)
        : id;

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
        trailing: Chip(
          label: Text('${r['status'] ?? ''}'),
        ),
      ),
    );
  }

  // Display event information.
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  // Build event detail page.
  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),

          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Event image.
                if (event.imageUrl.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(16),

                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    base64Decode(event.imageUrl),
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(event.imageUrl),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Center(
                    child: Text(
                      'Tap image to enlarge',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Event title.
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Event date and time.
                _infoRow(
                  Icons.calendar_today,
                  '${formatDate(event.dateTime)}, '
                  '${formatTime(event.dateTime)}',
                ),
<<<<<<< HEAD

                // Event location.
                _infoRow(
                  Icons.location_on,
                  event.venue,
                ),

                // Registration count.
=======
                _infoRow(Icons.location_on, event.venue),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openInMaps(context, event.venue),
                    icon: const Icon(Icons.map),
                    label: const Text('Open in Maps'),
                  ),
                ),
>>>>>>> e4704c24f45e7b17e09f55aee1bb3d02cf15dccd
                _infoRow(
                  Icons.people,
                  '${event.registeredCount} / ${event.capacity} registered',
                ),

                // Event description.
                const SizedBox(height: 6),
                Text(event.description),

                const Divider(height: 40),

                // Registration status.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Registration open'),
                  subtitle: const Text(
                    'Turn off to stop new registrations',
                  ),
                  value: event.registrationOpen,
                  onChanged: _updatingRegistration
                      ? null
                      : _toggleRegistration,
                ),

                const Divider(height: 40),

                // Registered participants.
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: RegistrationService()
                      .getRegistrations(event.eventId),

                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final registrations = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registered participants '
                          '(${registrations.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (registrations.isEmpty)
                          const Text('No registrations yet.'),

                        for (final r in registrations)
                          _registrationTile(r),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Announcements.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementsPage(
                            event: widget.event,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.campaign),
                    label: const Text('Announcements'),
                  ),
                ),

                const SizedBox(height: 12),

                // Edit event.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _deletingEvent ? null : _editEvent,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit event'),
                  ),
                ),

                const SizedBox(height: 12),

                // Delete event.
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deletingEvent
                        ? null
                        : _confirmDelete,
                    icon: _deletingEvent
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      _deletingEvent
                          ? 'Deleting...'
                          : 'Delete event',
                    ),
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
