
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../models/announcement.dart';
import '../../organizer/services/announcement_service.dart';

class ParticipantAnnouncementsPage extends StatelessWidget {
  const ParticipantAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcements')),
        body: const Center(
          child: Text('Please sign in to view announcements.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Announcements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .snapshots(),
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

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return const Center(
              child: Text('No events available.'),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context)
                    .colorScheme.surfaceContainerHighest,
                child: const Text(
                  'Announcements from events you have registered for.',
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final event in events)
                      _RegisteredEventAnnouncements(
                        eventDoc: event,
                        participantUid: user.uid,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RegisteredEventAnnouncements extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> eventDoc;
  final String participantUid;

  const _RegisteredEventAnnouncements({
    required this.eventDoc,
    required this.participantUid,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: eventDoc.reference
          .collection('registrations')
          .doc(participantUid)
          .snapshots(),
      builder: (context, registrationSnapshot) {
        if (registrationSnapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (!registrationSnapshot.hasData ||
            !registrationSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final eventData = eventDoc.data();
        final eventTitle =
            (eventData['title'] ?? 'Untitled Event').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<Announcement>>(
                  stream: AnnouncementService()
                      .getAnnouncements(eventDoc.id),
                  builder: (context, announcementSnapshot) {
                    if (announcementSnapshot.hasError) {
                      return Text(
                        'Error: ${announcementSnapshot.error}',
                      );
                    }

                    if (!announcementSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final announcements =
                        announcementSnapshot.data!;

                    if (announcements.isEmpty) {
                      return const Text(
                        'No announcements for this event yet.',
                      );
                    }

                    return Column(
                      children: [
                        for (final announcement in announcements)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(announcement.message),
                                const SizedBox(height: 8),
                                Text(
                                  '${formatDate(announcement.createdAt)}, '
                                  '${formatTime(announcement.createdAt)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
