import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationService {
  // A live list of the registrations for one event.
  Stream<List<Map<String, dynamic>>> getRegistrations(String eventId) {
    return FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}