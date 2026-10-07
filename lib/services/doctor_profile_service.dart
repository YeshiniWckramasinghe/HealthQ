import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Reads / updates the doctor's own record in the existing `staff` collection
// (created by StaffAuthService). Only these fields are ever written:
//   name, specialty, department, email, contactNo, avatarColor,
//   bookingDoctorId, updatedAt
// Nothing else on the teammates' staff documents is touched, and a staff
// document is never created from here.
// ---------------------------------------------------------------------------

String _s(dynamic v, String fallback) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? fallback : t;
}

String? _opt(dynamic v) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? null : t;
}

class DoctorProfile {
  final String staffId;
  final String name;
  final String specialty;
  final String department;
  final String hospital;
  final String room;
  final String email;
  final String phone;

  /// ARGB value of the chosen avatar colour (see DoctorProfileService.avatarColors).
  final int? avatarColor;
  final String? photoUrl;

  /// Id of the matching doctor in `hospitals/{id}/doctors` (patient bookings).
  final String? bookingDoctorId;

  const DoctorProfile({
    required this.staffId,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.room,
    this.department = '',
    this.email = '',
    this.phone = '',
    this.avatarColor,
    this.photoUrl,
    this.bookingDoctorId,
  });

  factory DoctorProfile.fromMap(
      Map<String, dynamic> m, DoctorProfile fallback) {
    final color = m['avatarColor'];
    return DoctorProfile(
      staffId: fallback.staffId,
      name: _s(m['name'], fallback.name),
      specialty: _s(m['specialty'], fallback.specialty),
      department: _s(m['department'], fallback.department),
      hospital: _s(m['hospital'], fallback.hospital),
      room: _s(m['room'], fallback.room),
      email: _s(m['email'], fallback.email),
      phone: _s(m['contactNo'], fallback.phone),
      avatarColor: color is num ? color.toInt() : fallback.avatarColor,
      photoUrl: _opt(m['photoUrl']) ?? fallback.photoUrl,
      bookingDoctorId: _opt(m['bookingDoctorId']) ?? fallback.bookingDoctorId,
    );
  }

  /// "Government Hospital — Colombo" -> "Colombo".
  String get hospitalShort =>
      hospital.contains('—') ? hospital.split('—').last.trim() : hospital;

  String get initials {
    final parts = name
        .replaceAll(RegExp(r'^\s*dr\.?\s+', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class DoctorProfileService {
  static final DoctorProfileService instance = DoctorProfileService._();
  DoctorProfileService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const List<String> specialties = <String>[
    'General Medicine',
    'Internal Medicine',
    'Cardiology',
    'Paediatrics',
    'General Surgery',
    'Obstetrics & Gynaecology',
    'Orthopaedics',
    'Dermatology',
    'ENT',
    'Ophthalmology',
    'Psychiatry',
    'Emergency Medicine',
  ];

  static const List<String> departments = <String>[
    'General Medicine OPD',
    'Cardiology OPD',
    'Paediatrics OPD',
    'Surgery OPD',
    'Orthopaedic OPD',
    'ENT OPD',
    'Eye OPD',
    'Emergency OPD',
  ];

  /// Selectable avatar colours (used by "Change Photo").
  static const List<int> avatarColors = <int>[
    0xFF007471,
    0xFF2F80ED,
    0xFF7B61FF,
    0xFFD97706,
    0xFFDC2626,
    0xFF0F766E,
  ];

  final Map<String, DocumentReference<Map<String, dynamic>>> _refCache =
      <String, DocumentReference<Map<String, dynamic>>>{};

  /// The staff document is normally `staff/{staffId}` (that is how
  /// StaffAuthService seeds it), but fall back to a staffId query so records
  /// created some other way still work.
  Future<DocumentReference<Map<String, dynamic>>?> _resolveRef(
      String staffId) async {
    final cached = _refCache[staffId];
    if (cached != null) return cached;

    final direct = _db.collection('staff').doc(staffId);
    final snap = await direct.get();
    if (snap.exists) {
      _refCache[staffId] = direct;
      return direct;
    }
    final q = await _db
        .collection('staff')
        .where('staffId', isEqualTo: staffId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    _refCache[staffId] = q.docs.first.reference;
    return q.docs.first.reference;
  }

  /// Live profile. Never errors: if Firestore is unreachable the stream just
  /// ends and the UI keeps showing [fallback] (the data from login).
  Stream<DoctorProfile> profileStream(DoctorProfile fallback) async* {
    try {
      final ref = await _resolveRef(fallback.staffId);
      if (ref == null) return;
      await for (final snap in ref.snapshots()) {
        final data = snap.data();
        if (data != null) yield DoctorProfile.fromMap(data, fallback);
      }
    } catch (e) {
      debugPrint('DoctorProfileService stream: $e');
    }
  }

  // ---------- Validation helpers (shared with the edit screen) ----------

  static bool isValidEmail(String v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());

  /// Accepts 0712345678, 071 234 5678, +94712345678, 94712345678.
  /// Returns the local 10-digit form or null if it is not a valid number.
  static String? normalizePhone(String v) {
    var d = v.replaceAll(RegExp(r'[\s\-()]'), '');
    if (d.startsWith('+94')) d = '0${d.substring(3)}';
    if (d.startsWith('94') && d.length == 11) d = '0${d.substring(2)}';
    return RegExp(r'^0\d{9}$').hasMatch(d) ? d : null;
  }

  static String formatPhone(String digits) {
    final d = digits.replaceAll(RegExp(r'\s'), '');
    if (d.length == 10) {
      return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6)}';
    }
    return digits;
  }

  // ---------- Writes ----------

  Future<void> updateProfile({
    required String staffId,
    required String name,
    required String specialty,
    required String department,
    required String email,
    required String phone,
  }) async {
    final ref = await _resolveRef(staffId);
    if (ref == null) {
      throw Exception(
          'Your staff record was not found in the database. Please check your connection and try again.');
    }
    await ref.update(<String, dynamic>{
      'name': name.trim(),
      'specialty': specialty,
      'department': department,
      // Teammates look staff up by lower-case email, so keep that format.
      'email': email.trim().toLowerCase(),
      'contactNo': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAvatarColor(String staffId, int color) async {
    final ref = await _resolveRef(staffId);
    if (ref == null) throw Exception('Your staff record was not found.');
    await ref.update(<String, dynamic>{
      'avatarColor': color,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remembers which `hospitals/{id}/doctors` entry this doctor is, so patient
  /// bookings keep reaching them even after they edit their display name.
  Future<void> linkBookingDoctor(String staffId, String bookingDoctorId) async {
    try {
      final ref = await _resolveRef(staffId);
      if (ref == null) return;
      await ref.update(<String, dynamic>{'bookingDoctorId': bookingDoctorId});
    } catch (e) {
      debugPrint('DoctorProfileService link: $e');
    }
  }
}
