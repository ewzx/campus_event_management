import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../organizer/pages/organizer_home_page.dart';
import '../participant/pages/event_list_page.dart';
import '../../models/event.dart';
import '../organizer/widgets/organizer_event_card.dart';

class EventsHomePage extends StatelessWidget {
  const EventsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
            builder: (context, snap) {
              final role = snap.data?.data()?['role'];
              if (role == 'organizer') {
                return IconButton(
                  tooltip: 'My Events',
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerHomePage())),
                );
              }
              if (role == 'participant') {
                return IconButton(
                  tooltip: 'My Registrations',
                  icon: const Icon(Icons.confirmation_number),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventListPage())),
                );
              }
              return const SizedBox();
            },
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final events = snapshot.data!.docs
              .map((d) => Event.fromMap(d.data(), id: d.id))
              .toList();
          if (events.isEmpty) return const Center(child: Text('No upcoming events.'));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [for (final e in events) OrganizerEventCard(event: e)],
              ),
            ),
          );
        },
      ),
    );
  }
}