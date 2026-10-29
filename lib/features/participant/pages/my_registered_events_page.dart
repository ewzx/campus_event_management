
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Registered Events')),
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
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.event_available),
                        ),
                        title: Text(
                          event['title']?.toString() ??
                              'Untitled Event',
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
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
