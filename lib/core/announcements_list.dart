import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/announcement.dart';
import 'formatters.dart';

class AnnouncementsList extends StatelessWidget {
  final String eventId;

  const AnnouncementsList({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data!.docs
            .map((d) => Announcement.fromMap(d.data()))
            .toList();

        if (list.isEmpty) {
          return const Text('No announcements yet.');
        }

        return Column(
          children: [
            for (final a in list)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(a.message),
                  subtitle: Text(
                    '${formatDate(a.createdAt)}, ${formatTime(a.createdAt)}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}