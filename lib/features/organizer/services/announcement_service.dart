import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/announcement.dart';

class AnnouncementService {
  CollectionReference<Map<String, dynamic>> _col(String eventId) {
    return FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('announcements');
  }

  Future<void> addAnnouncement(Announcement a) async {
    final doc = _col(a.eventId).doc();
    await doc.set({...a.toMap(), 'announcementId': doc.id});
  }

  Future<void> deleteAnnouncement(String eventId, String id) async {
    await _col(eventId).doc(id).delete();
  }

  // A live list, newest first.
  Stream<List<Announcement>> getAnnouncements(String eventId) {
    return _col(eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => Announcement.fromMap(d.data())).toList());
  }
}