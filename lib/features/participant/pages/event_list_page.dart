import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'my_registered_events_page.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _keyword = '';

  // Get events from Cloud Firestore.
  final CollectionReference<Map<String, dynamic>> _eventsRef =
      FirebaseFirestore.instance.collection('events');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      value = value.toDate();
    }

    if (value is! DateTime) {
      return 'Date not available';
    }

    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    final day = value.day;
    final month = months[value.month - 1];
    final year = value.year;

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, '
        '$hour:$minute $period';
  }

  IconData _getEventIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('photography') ||
        lowerTitle.contains('photo')) {
      return Icons.camera_alt;
    }

    if (lowerTitle.contains('sport')) {
      return Icons.sports_basketball;
    }

    return Icons.computer;
  }
  void _showEventDetails(Map<String, dynamic> event) {
    final capacity = (event['capacity'] as num?)?.toInt() ?? 0;
    final registered =
        (event['registeredCount'] as num?)?.toInt() ?? 0;
    final available = (capacity - registered).clamp(0, capacity);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(event['title']?.toString() ?? 'Untitled Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${_formatDate(event['startTime'])}'),
                const SizedBox(height: 8),
                Text(
                  'Location: ${event['location'] ?? 'Not specified'}',
                ),
                const SizedBox(height: 8),
                Text('Available places: $available'),
                const SizedBox(height: 16),
                Text(
                  event['description']?.toString() ??
                      'No description available.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: available <= 0
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      _registerForEvent(event);
                    },
              icon: const Icon(Icons.app_registration),
              label: const Text('Register'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _registerForEvent(
      Map<String, dynamic> event) async {
    final user = FirebaseAuth.instance.currentUser;
    final eventId = event['id']?.toString();

    if (user == null || eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to register. Please try again.'),
        ),
      );
      return;
    }

    try {
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(eventId);

      final registrationRef =
          eventRef.collection('registrations').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Read both documents before making any changes.
        final eventSnapshot = await transaction.get(eventRef);
        final registrationSnapshot =
            await transaction.get(registrationRef);

        if (!eventSnapshot.exists) {
          throw Exception('EVENT_NOT_FOUND');
        }

        if (registrationSnapshot.exists) {
          throw Exception('ALREADY_REGISTERED');
        }

        final data = eventSnapshot.data()!;
        final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
        final registered =
            (data['registeredCount'] as num?)?.toInt() ?? 0;

        if (data['status'] != 'open') {
          throw Exception('EVENT_CLOSED');
        }

        if (registered >= capacity) {
          throw Exception('EVENT_FULL');
        }

        // Save the participant's registration.
        transaction.set(registrationRef, {
          'eventId': eventId,
          'eventTitle': data['title'] ?? 'Untitled Event',
          'participantId': user.uid,
          'registeredAt': FieldValue.serverTimestamp(),
          'status': 'registered',
        });

        // Update the number of registered participants.
        transaction.update(eventRef, {
          'registeredCount': registered + 1,
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final error = e.toString();
      String message;

      if (error.contains('ALREADY_REGISTERED')) {
        message = 'You have already registered for this event.';
      } else if (error.contains('EVENT_FULL')) {
        message = 'Sorry, this event is full.';
      } else if (error.contains('EVENT_CLOSED')) {
        message = 'Registration for this event is closed.';
      } else if (error.contains('EVENT_NOT_FOUND')) {
        message = 'This event could not be found.';
      } else if (error.contains('permission-denied')) {
        message =
            'Permission denied. Please check your Firestore security rules.';
      } else {
        message = 'Registration failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'My Registered Events',
            icon: const Icon(Icons.event_available),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const MyRegisteredEventsPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _keyword = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search events by name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _keyword = '';
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _eventsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Firestore error: ${snapshot.error}');
                      debugPrint('Firestore stack trace: ${snapshot.stackTrace}');

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Unable to load events.\n\n'
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                            ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final events = snapshot.data?.docs
                            .map((doc) => {
                              ...doc.data(),
                              'id': doc.id,
                            })
                            .where((event) {
                      final title =
                          event['title']?.toString().toLowerCase() ?? '';

                      return title.contains(_keyword);
                    }).toList() ??
                        <Map<String, dynamic>>[];

                    // Sort events by start time.
                    events.sort((a, b) {
                      final aTime = a['startTime'] is Timestamp
                          ? (a['startTime'] as Timestamp).toDate()
                          : DateTime(2100);

                      final bTime = b['startTime'] is Timestamp
                          ? (b['startTime'] as Timestamp).toDate()
                          : DateTime(2100);

                      return aTime.compareTo(bTime);
                    });

                    if (events.isEmpty) {
                      return const Center(
                        child: Text('No events found.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 20,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];

                        final title =
                            event['title']?.toString() ??
                                'Untitled Event';

                        final capacity =
                            (event['capacity'] as num?)?.toInt() ?? 0;

                        final registered =
                            (event['registeredCount'] as num?)
                                    ?.toInt() ??
                                0;

                        final available =
                            (capacity - registered).clamp(0, capacity);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _showEventDetails(event),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getEventIcon(title),
                                      size: 42,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Date: '
                                          '${_formatDate(event['startTime'])}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Location: '
                                          '${event['location'] ?? 'Not specified'}',
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          available > 0
                                              ? '$available places available'
                                              : 'Fully booked',
                                          style: TextStyle(
                                            color: available > 0
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
