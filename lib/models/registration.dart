import 'package:cloud_firestore/cloud_firestore.dart';

class Registration {
  final String registrationId; // also QR code value
  final String eventId;
  final String participantId;
  final String status; // 'registered', 'cancelled' or 'waitlisted'
  final String attendanceStatus; // 'not checked in' or 'present'
  final DateTime? checkedInAt; // empty until checked in
  final String checkedInBy; // uid of the staff member, empty until check-in
  final bool walkIn;

  Registration({
    required this.registrationId,
    required this.eventId,
    required this.participantId,
    this.status = 'registered',
    this.attendanceStatus = 'not checked in',
    this.checkedInAt,
    this.checkedInBy = '',
    this.walkIn = false,
  });

  // Registration into Map for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'registrationId': registrationId,
      'eventId': eventId,
      'participantId': participantId,
      'status': status,
      'attendanceStatus': attendanceStatus,
      'checkedInAt': checkedInAt,
      'checkedInBy': checkedInBy,
      'walkIn': walkIn,
    };
  }

  // Map from Firestore to Registration.
  factory Registration.fromMap(Map<String, dynamic> map) {
    return Registration(
      registrationId: map['registrationId'],
      eventId: map['eventId'],
      participantId: map['participantId'],
      status: map['status'] ?? 'registered',
      attendanceStatus: map['attendanceStatus'] ?? 'not checked in',
      checkedInAt: map['checkedInAt'] == null ? null: (map['checkedInAt'] as Timestamp).toDate(),
      checkedInBy: map['checkedInBy'] ?? '',
      walkIn: map['walkIn'] ?? false,
    );
  }
}