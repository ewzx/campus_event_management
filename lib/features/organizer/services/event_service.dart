import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/event.dart';

class EventService {
  final CollectionReference<Map<String, dynamic>> _events =
  FirebaseFirestore.instance.collection('events');

  // Saves a new event. Firestore makes the ID, and we store it in the event too.
  Future<void> addEvent(Event event) async {
    final doc = _events.doc();
    await doc.set({...event.toMap(), 'eventId': doc.id});
  }

  Future<void> updateEvent(Event event) async {
    await _events.doc(event.eventId).set(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }

  // A live list of one organizer's events. It updates by itself.
  Stream<List<Event>> getMyEvents(String organizerId) {
    return _events
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromMap(d.data(), id: d.id)).toList());
  }
}