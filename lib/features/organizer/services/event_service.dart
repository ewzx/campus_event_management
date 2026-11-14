
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/event.dart';

class EventService {
  final CollectionReference<Map<String, dynamic>> _events =
      FirebaseFirestore.instance.collection('events');

  // Get the currently logged-in organizer.
  User _getCurrentOrganizer() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    if (user.isAnonymous) {
      throw Exception('Anonymous accounts cannot manage events.');
    }

    return user;
  }

  // Create a new event.
  Future<void> addEvent(Event event) async {
    final user = _getCurrentOrganizer();

    final doc = _events.doc();

    final eventData = event.toMap();

    eventData['eventId'] = doc.id;
    eventData['organizerId'] = user.uid;

    await doc.set(eventData);
  }

  // Update an existing event.
  // Preserve system-managed registration data.
  Future<void> updateEvent(Event event) async {
    final user = _getCurrentOrganizer();

    final doc = _events.doc(event.eventId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final snapshot = await transaction.get(doc);

        if (!snapshot.exists) {
          throw Exception('Event not found.');
        }

        final existingData = snapshot.data()!;

        if (existingData['organizerId'] != user.uid) {
          throw Exception(
            'You cannot update another organizer\'s event.',
          );
        }

        final updatedData = event.toMap();

        // Keep the original event ID and owner.
        updatedData['eventId'] = event.eventId;
        updatedData['organizerId'] = user.uid;

        // Preserve the latest registration count.
        updatedData['registeredCount'] =
            existingData['registeredCount'] ?? 0;

        transaction.update(doc, updatedData);
      },
    );
  }

  // Delete an event and its subcollections.
  Future<void> deleteEvent(String eventId) async {
    final user = _getCurrentOrganizer();

    final doc = _events.doc(eventId);

    // Check event ownership first.
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      throw Exception('Event not found.');
    }

    if (snapshot.data()?['organizerId'] != user.uid) {
      throw Exception(
        'You cannot delete another organizer\'s event.',
      );
    }

    // Delete registrations in batches.
    await _deleteSubcollection(
      doc.collection('registrations'),
    );

    // Delete announcements in batches.
    await _deleteSubcollection(
      doc.collection('announcements'),
    );

    // Delete the parent event document last.
    // Check ownership again before deleting.
    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final latestSnapshot = await transaction.get(doc);

        if (!latestSnapshot.exists) {
          throw Exception('Event not found.');
        }

        if (latestSnapshot.data()?['organizerId'] != user.uid) {
          throw Exception(
            'You cannot delete another organizer\'s event.',
          );
        }

        transaction.delete(doc);
      },
    );
  }

  // Delete all documents in a subcollection using batches.
  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(400).get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }
  }

  // Get events belonging to the current organizer.
  Stream<List<Event>> getMyEvents(String organizerId) {
    return _events
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Event.fromMap(
              doc.data(),
              id: doc.id,
            ),
          )
          .toList();
    });
  }
}
