
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/pages/auth_entry_page.dart';
import 'my_registered_events_page.dart';
import 'participant_announcements_page.dart';
import '../../../core/open_maps.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({super.key});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final CollectionReference<Map<String, dynamic>> _eventsRef =
      FirebaseFirestore.instance.collection('events');

  String _keyword = '';
  bool _isLoggingOut = false;

  String? get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Generate a unique ticket ID.
  String _generateTicketId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    final random = Random.secure();

    return 'TKT-${List.generate(
      16,
      (_) => chars[random.nextInt(chars.length)],
    ).join()}';
  }

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

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

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

  // Safely decode Base64 images.
  Uint8List? _decodeImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return null;
    }

    try {
      return base64Decode(imageData);
    } catch (e) {
      debugPrint('Image decoding error: $e');
      return null;
    }
  }

  // Format event date and time.
  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      value = value.toDate();
    }

    if (value is! DateTime) {
      return 'Date not available';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final day = value.day;
    final month = months[value.month - 1];
    final year = value.year;

    final hour = value.hour % 12 == 0
        ? 12
        : value.hour % 12;

    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour:$minute $period';
  }

  // Get a suitable icon based on event title.
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

  // Get available event places.
  int _getAvailablePlaces(Map<String, dynamic> event) {
    final capacity =
        (event['capacity'] as num?)?.toInt() ?? 0;

    final registered =
        (event['registeredCount'] as num?)?.toInt() ?? 0;

    return (capacity - registered).clamp(0, capacity);
  }

  // Check whether registration is open.
  bool _isRegistrationOpen(Map<String, dynamic> event) {
    return event['status'] == 'open';
  }

  // Check whether the event is full.
  bool _isEventFull(Map<String, dynamic> event) {
    return _getAvailablePlaces(event) <= 0;
  }

  // Display event details.
  void _showEventDetails(Map<String, dynamic> event) {
    final available = _getAvailablePlaces(event);
    final isOpen = _isRegistrationOpen(event);

    final imageBytes = _decodeImage(
      event['imageUrl']?.toString(),
    );

    final eventId = event['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;

        final dialogWidth = screenSize.width > 560
            ? 500.0
            : screenSize.width * 0.9;

        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenSize.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      20,
                      24,
                      12,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        event['title']?.toString() ??
                            'Untitled Event',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (imageBytes != null) ...[
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: dialogContext,
                                  barrierColor: Colors.black87,
                                  builder: (imageContext) {
                                    final imageScreenSize =
                                        MediaQuery.of(imageContext)
                                            .size;

                                    return Dialog(
                                      backgroundColor:
                                          Colors.transparent,
                                      insetPadding:
                                          const EdgeInsets.all(16),
                                      child: SizedBox(
                                        width:
                                            imageScreenSize.width *
                                                0.9,
                                        height:
                                            imageScreenSize.height *
                                                0.8,
                                        child: Stack(
                                          children: [
                                            Center(
                                              child:
                                                  InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4.0,
                                                child: Image.memory(
                                                  imageBytes,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: IconButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                  imageContext,
                                                ),
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 200,
                                  child: Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'Tap image to enlarge',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else if (
                            (event['imageUrl']?.toString() ?? '')
                                .isNotEmpty
                          ) ...[
                            Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          Text(
                            'Date: ${_formatDate(event['startTime'])}',
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Location: ${event['location'] ?? 'Not specified'}',
                          ),

                          // Open event location in Google Maps.
                          if ((event['location']
                                      ?.toString()
                                      .trim() ??
                                  '')
                              .isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  openInMaps(
                                    dialogContext,
                                    event['location'].toString(),
                                  );
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Open in Maps'),
                              ),
                            ),

                          const SizedBox(height: 8),
                          Text(
                            'Available places: $available',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Registration status: '
                            '${!isOpen ? 'Closed' : available <= 0 ? 'Full' : 'Open'}',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            event['description']?.toString() ??
                                'No description available.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      16,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                        FutureBuilder<bool>(
                          future: _hasRegistered(eventId),
                          builder: (context, snapshot) {
                            final alreadyRegistered =
                                snapshot.data == true;

                            final checking =
                                snapshot.connectionState ==
                                    ConnectionState.waiting;

                            return ElevatedButton.icon(
                              onPressed: checking ||
                                      alreadyRegistered ||
                                      available <= 0 ||
                                      !isOpen
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                      _registerForEvent(event);
                                    },
                              icon: const Icon(
                                Icons.app_registration,
                              ),
                              label: Text(
                                checking
                                    ? 'Checking...'
                                    : alreadyRegistered
                                        ? 'Already Registered'
                                        : !isOpen
                                            ? 'Registration Closed'
                                            : available <= 0
                                                ? 'Fully Booked'
                                                : 'Register',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Check whether the participant has already registered.
  Future<bool> _hasRegistered(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || eventId.isEmpty) {
      return false;
    }

    final registration = await _eventsRef
        .doc(eventId)
        .collection('registrations')
        .doc(user.uid)
        .get();

    return registration.exists;
  }

  // Register for an event and generate a ticket ID.
  Future<void> _registerForEvent(
    Map<String, dynamic> event,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    final eventId = event['id']?.toString();

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in with a registered account.',
          ),
        ),
      );
      return;
    }

    if (eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to register. Please try again.',
          ),
        ),
      );
      return;
    }

    try {
      final eventRef = _eventsRef.doc(eventId);

      final registrationRef = eventRef
          .collection('registrations')
          .doc(user.uid);

      // Generate ticket ID before the transaction.
      final ticketId = _generateTicketId();

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final eventSnapshot =
              await transaction.get(eventRef);

          final registrationSnapshot =
              await transaction.get(registrationRef);

          if (!eventSnapshot.exists) {
            throw Exception('EVENT_NOT_FOUND');
          }

          if (registrationSnapshot.exists) {
            throw Exception('ALREADY_REGISTERED');
          }

          final data = eventSnapshot.data()!;

          final capacity =
              (data['capacity'] as num?)?.toInt() ?? 0;

          final registered =
              (data['registeredCount'] as num?)?.toInt() ?? 0;

          if (data['status'] != 'open') {
            throw Exception('EVENT_CLOSED');
          }

          if (registered >= capacity) {
            throw Exception('EVENT_FULL');
          }

          transaction.set(registrationRef, {
            'eventId': eventId,
            'eventTitle': data['title'] ?? 'Untitled Event',
            'participantId': user.uid,
            'ticketId': ticketId,
            'registeredAt': FieldValue.serverTimestamp(),
            'status': 'registered',
            'checkInStatus': false,
            'checkInTime': null,
          });

          transaction.update(eventRef, {
            'registeredCount': registered + 1,
          });
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Your ticket is ready.',
          ),
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
        debugPrint('Registration error: $e');
        message = 'Registration failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggingOut) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Announcements',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ParticipantAnnouncementsPage(),
                ),
              );
            },
          ),
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
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            children: [
              // Search bar.
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

              // Event list.
              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _eventsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint(
                        'Firestore error: ${snapshot.error}',
                      );

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
                              final title = event['title']
                                      ?.toString()
                                      .toLowerCase() ??
                                  '';

                              return title.contains(_keyword);
                            })
                            .toList() ??
                        <Map<String, dynamic>>[];

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
                        20,
                        0,
                        20,
                        20,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];

                        final title = event['title']?.toString() ??
                            'Untitled Event';

                        final available =
                            _getAvailablePlaces(event);

                        final isOpen =
                            _isRegistrationOpen(event);

                        final imageBytes = _decodeImage(
                          event['imageUrl']?.toString(),
                        );

                        final eventId =
                            event['id']?.toString() ?? '';

                        return StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _currentUserId == null
                              ? null
                              : _eventsRef
                                  .doc(eventId)
                                  .collection('registrations')
                                  .doc(_currentUserId)
                                  .snapshots(),
                          builder: (context, registrationSnapshot) {
                            final alreadyRegistered =
                                registrationSnapshot.data?.exists ??
                                    false;

                            String statusText;

                            if (alreadyRegistered) {
                              statusText = 'Already Registered';
                            } else if (!isOpen) {
                              statusText = 'Registration Closed';
                            } else if (available <= 0) {
                              statusText = 'Fully Booked';
                            } else {
                              statusText =
                                  '$available places available';
                            }

                            final statusColor = alreadyRegistered
                                ? Colors.blue.shade700
                                : isOpen && available > 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700;

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: 16,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    _showEventDetails(event),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Event image.
                                      Container(
                                        width: 90,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: imageBytes != null
                                            ? Image.memory(
                                                imageBytes,
                                                width: 90,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Icon(
                                                    _getEventIcon(title),
                                                    size: 42,
                                                    color: Colors.blue
                                                        .shade700,
                                                  );
                                                },
                                              )
                                            : Icon(
                                                _getEventIcon(title),
                                                size: 42,
                                                color: Colors.blue
                                                    .shade700,
                                              ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Event information.
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Date: ${_formatDate(event['startTime'])}',
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Location: ${event['location'] ?? 'Not specified'}',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
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
