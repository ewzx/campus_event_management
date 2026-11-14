
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyRegisteredEventsPage extends StatelessWidget {
  const MyRegisteredEventsPage({super.key});

  String formatDate(dynamic value) {
    if (value == null) return 'Not available';

    DateTime date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return 'Not available';
    }

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  $hour:$minute $period';
  }

  // Display the participant's electronic ticket.
  void showTicket(
    BuildContext context,
    Map<String, dynamic> event,
    Map<String, dynamic> registration,
  ) {
    final ticketId =
        registration['ticketId']?.toString() ?? '';

    final eventId =
        registration['eventId']?.toString() ?? '';

    if (ticketId.isEmpty || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ticket information is unavailable for this registration.',
          ),
        ),
      );
      return;
    }

    // QR Code contains event ID and ticket ID only.
    final qrData = jsonEncode({
      'eventId': eventId,
      'ticketId': ticketId,
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.confirmation_number,
                  size: 42,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'EVENT E-TICKET',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event['title']?.toString() ?? 'Untitled Event',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${formatDate(event['startTime'])}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${event['location'] ?? 'Not specified'}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Generate QR Code.
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),

                const SizedBox(height: 12),
                const Text(
                  'Present this QR Code to the check-in staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Ticket ID',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  ticketId,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Close Ticket'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Registered Events'),
        ),
        body: const Center(
          child: Text('Please sign in to view your registrations.'),
        ),
      );
    }

    final eventsRef =
        FirebaseFirestore.instance.collection('events');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Registered Events'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: eventsRef.snapshots(),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.hasError) {
            return const Center(
              child: Text('Failed to load events. Please try again.'),
            );
          }

          if (eventSnapshot.connectionState ==
                  ConnectionState.waiting &&
              !eventSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final eventDocs = eventSnapshot.data?.docs ?? [];

          if (eventDocs.isEmpty) {
            return const Center(
              child: Text('No events are available yet.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final eventDoc in eventDocs)
                StreamBuilder<
                    DocumentSnapshot<Map<String, dynamic>>>(
                  stream: eventDoc.reference
                      .collection('registrations')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, registrationSnapshot) {
                    if (registrationSnapshot.hasError) {
                      return const SizedBox.shrink();
                    }

                    if (!registrationSnapshot.hasData ||
                        !registrationSnapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final event = eventDoc.data();

                    final registration =
                        registrationSnapshot.data!.data()!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: event['imageUrl'] != null &&
                                        event['imageUrl']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.memory(
                                        base64Decode(
                                          event['imageUrl'].toString(),
                                        ),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircleAvatar(
                                              child: Icon(
                                                Icons.event_available,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox(
                                        width: 60,
                                        height: 60,
                                        child: CircleAvatar(
                                          child: Icon(
                                            Icons.event_available,
                                          ),
                                        ),
                                      ),
                              ),
                              title: Text(
                                event['title']?.toString() ??
                                    'Untitled Event',
                              ),
                              subtitle: Padding(
                                padding:
                                    const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date: ${formatDate(event['startTime'])}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Location: ${event['location'] ?? 'Not specified'}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: ${registration['status'] ?? 'registered'}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Registered at: ${formatDate(registration['registeredAt'])}',
                                    ),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                            ),
                            const Divider(),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  showTicket(
                                    context,
                                    event,
                                    registration,
                                  );
                                },
                                icon: const Icon(Icons.qr_code_2),
                                label: const Text('View Ticket'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
