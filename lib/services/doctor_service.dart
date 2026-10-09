import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'doctor_attachment_service.dart';
import 'doctor_availability_service.dart';
import 'doctor_profile_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _s(dynamic v, String fallback) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? fallback : t;
}

String? _opt(dynamic v) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? null : t;
}

int _i(dynamic v, int fallback) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

/// "9:5" -> "09:05". Leaves anything unparseable untouched.
String normalizeDoctorTime(String t) {
  final p = t.trim().split(':');
  if (p.length < 2) return t;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return t;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class DoctorAppointment {
  final String id;
  final String patientName;
  final String patientId; // NIC / demo id used as display id
  final String time; // "09:30"
  final String session; // "Morning" / "Evening"
  final String room;
  final String type; // "Consultation", "Follow-up", "Routine Checkup"
  final String status; // completed | in_progress | next | upcoming
  final int queueNo;
  final String date; // yyyy-MM-dd
  final String? notes;
  final String? diagnosis;
  final String? prescription;
  final String? patientGender;
  final int? patientAge;
  final String? patientPhone;
  final String source; // 'demo' | 'booking'

  /// Files (X-rays, PDFs ...) attached during the consultation.
  final List<ConsultationAttachment> attachments;

  const DoctorAppointment({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.time,
    required this.session,
    required this.room,
    required this.type,
    required this.status,
    required this.queueNo,
    required this.date,
    this.notes,
    this.diagnosis,
    this.prescription,
    this.patientGender,
    this.patientAge,
    this.patientPhone,
    this.source = 'demo',
    this.attachments = const <ConsultationAttachment>[],
  });

  factory DoctorAppointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final age = m['patientAge'];
    return DoctorAppointment(
      id: d.id,
      patientName: _s(m['patientName'], 'Unknown'),
      patientId: _s(m['patientDisplayId'], _s(m['userId'], 'P00000')),
      time: normalizeDoctorTime(_s(m['time'], '09:00')),
      session: _s(m['session'], 'Morning'),
      room: _s(m['room'], 'Room 01'),
      type: _s(m['type'], 'Consultation'),
      status: _s(m['status'], 'upcoming'),
      queueNo: _i(m['queueNo'], 0),
      date: _s(m['date'], ''),
      notes: _opt(m['notes']),
      diagnosis: _opt(m['diagnosis']),
      prescription: _opt(m['prescription']),
      patientGender: _opt(m['patientGender']),
      patientAge: age is num ? age.toInt() : null,
      patientPhone: _opt(m['patientPhone']),
      source: _s(m['source'], 'demo'),
      attachments: ConsultationAttachment.listFrom(m['attachments']),
    );
  }

  DoctorAppointment copyWith({
    String? status,
    String? notes,
    String? diagnosis,
    String? prescription,
    List<ConsultationAttachment>? attachments,
  }) =>
      DoctorAppointment(
        id: id,
        patientName: patientName,
        patientId: patientId,
        time: time,
        session: session,
        room: room,
        type: type,
        status: status ?? this.status,
        queueNo: queueNo,
        date: date,
        notes: notes ?? this.notes,
        diagnosis: diagnosis ?? this.diagnosis,
        prescription: prescription ?? this.prescription,
        patientGender: patientGender,
        patientAge: patientAge,
        patientPhone: patientPhone,
        source: source,
        attachments: attachments ?? this.attachments,
      );

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isNext => status == 'next';
  bool get isUpcoming => status == 'upcoming';
  bool get isWaiting => isNext || isUpcoming;

  /// "Male · 34 years" - skips whatever is not recorded.
  String get demographics {
    final parts = <String>[
      if (patientGender != null) patientGender!,
      if (patientAge != null) '$patientAge years',
    ];
    return parts.isEmpty ? 'Details not recorded' : parts.join(' · ');
  }
}

class DoctorStats {
  final int totalAppointments;
  final int waitingPatients;
  final int inConsultation;
  final int completed;

  const DoctorStats({
    this.totalAppointments = 0,
    this.waitingPatients = 0,
    this.inConsultation = 0,
    this.completed = 0,
  });

  double get progressPercent =>
      totalAppointments == 0 ? 0 : completed / totalAppointments;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DoctorService {
  static final DoctorService instance = DoctorService._();
  DoctorService._();

  /// Turn off to stop writing sample patients / appointments for doctors that
  /// have no appointments today (e.g. for production).
  static bool enableDemoSeed = true;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _appts =>
      _db.collection('doctor_appointments');

  // ---------- Date helpers ----------

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayKey() => dateKey(DateTime.now());
  String todayString() => todayKey();

  /// Time order first, then token number.
  static int compareSchedule(DoctorAppointment a, DoctorAppointment b) {
    final t = a.time.compareTo(b.time);
    if (t != 0) return t;
    final q = a.queueNo.compareTo(b.queueNo);
    if (q != 0) return q;
    return a.id.compareTo(b.id);
  }

  // ---------- Streams ----------

  /// Live appointments for [doctorId] on [date] (yyyy-MM-dd), in visit order.
  Stream<List<DoctorAppointment>> appointmentsStream(
      String doctorId, String date) {
    return _appts
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(DoctorAppointment.fromDoc).toList();
      list.sort(compareSchedule);
      return list;
    });
  }

  Stream<DoctorAppointment?> appointmentStream(String appointmentId) {
    return _appts
        .doc(appointmentId)
        .snapshots()
        .map((d) => d.exists ? DoctorAppointment.fromDoc(d) : null);
  }

  DoctorStats computeStats(List<DoctorAppointment> appointments) {
    var completed = 0, inConsult = 0, waiting = 0;
    for (final a in appointments) {
      if (a.isCompleted) completed++;
      if (a.isInProgress) inConsult++;
      if (a.isWaiting) waiting++;
    }
    return DoctorStats(
      totalAppointments: appointments.length,
      waitingPatients: waiting,
      inConsultation: inConsult,
      completed: completed,
    );
  }

  // ---------- Queue transitions ----------
  //
  // Every transition re-reads the day from Firestore (so it never works from a
  // stale list on screen), applies the change, and keeps exactly ONE patient
  // flagged 'next' while anyone is still waiting. All writes are one batch.

  Future<List<DoctorAppointment>> _fetchDay(String doctorId, String date) async {
    final snap = await _appts
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .get();
    final list = snap.docs.map(DoctorAppointment.fromDoc).toList();
    list.sort(compareSchedule);
    return list;
  }

  Map<String, String> _planStatuses(
      List<DoctorAppointment> list, Map<String, String> overrides) {
    final status = <String, String>{for (final a in list) a.id: a.status};
    overrides.forEach((id, s) {
      if (status.containsKey(id)) status[id] = s;
    });

    String? keep;
    for (final a in list) {
      if (status[a.id] == 'next') {
        if (keep == null) {
          keep = a.id;
        } else {
          status[a.id] = 'upcoming';
        }
      }
    }
    if (keep == null) {
      for (final a in list) {
        if (status[a.id] == 'upcoming') {
          status[a.id] = 'next';
          break;
        }
      }
    }
    return status;
  }

  Future<void> _transition({
    required String doctorId,
    required String date,
    required String targetId,
    required String newStatus,
    Map<String, dynamic> extra = const <String, dynamic>{},
    List<DoctorAppointment>? prefetched,
  }) async {
    final list = prefetched ?? await _fetchDay(doctorId, date);
    final target = list.where((a) => a.id == targetId).firstOrNull;
    if (target == null) {
      throw Exception('Appointment not found. It may have been removed.');
    }
    if (target.isCompleted && newStatus != 'completed') {
      throw Exception('This consultation is already completed.');
    }
    if (target.status == newStatus && newStatus == 'in_progress') return;

    final planned = _planStatuses(list, <String, String>{targetId: newStatus});
    final batch = _db.batch();
    for (final a in list) {
      final s = planned[a.id] ?? a.status;
      final isTarget = a.id == targetId;
      if (!isTarget && s == a.status) continue;
      batch.update(_appts.doc(a.id), <String, dynamic>{
        'status': s,
        if (isTarget) ...extra,
      });
    }
    await batch.commit();
  }

  Future<void> _normalizeDay(String doctorId, String date) async {
    final list = await _fetchDay(doctorId, date);
    final planned = _planStatuses(list, const <String, String>{});
    final batch = _db.batch();
    var writes = 0;
    for (final a in list) {
      final s = planned[a.id] ?? a.status;
      if (s != a.status) {
        batch.update(_appts.doc(a.id), <String, dynamic>{'status': s});
        writes++;
      }
    }
    if (writes > 0) await batch.commit();
  }

  /// Doctor opens the consultation for a patient.
  Future<void> startConsultation({
    required String doctorId,
    required String date,
    required String appointmentId,
  }) {
    return _transition(
      doctorId: doctorId,
      date: date,
      targetId: appointmentId,
      newStatus: 'in_progress',
      extra: <String, dynamic>{'startedAt': FieldValue.serverTimestamp()},
    );
  }

  /// "Call Next" on the queue screen: the next waiting patient goes in.
  Future<DoctorAppointment> callNext({
    required String doctorId,
    required String date,
  }) async {
    final list = await _fetchDay(doctorId, date);
    final next = list.where((a) => a.isNext).firstOrNull ??
        list.where((a) => a.isUpcoming).firstOrNull;
    if (next == null) throw Exception('No patients are waiting.');
    await _transition(
      doctorId: doctorId,
      date: date,
      targetId: next.id,
      newStatus: 'in_progress',
      extra: <String, dynamic>{'startedAt': FieldValue.serverTimestamp()},
      prefetched: list,
    );
    return next;
  }

  /// Saves the notes AND completes the visit in a single atomic batch, then
  /// advances the queue.
  Future<void> completeConsultation({
    required String doctorId,
    required String date,
    required String appointmentId,
    String? notes,
    String? diagnosis,
    String? prescription,
  }) {
    return _transition(
      doctorId: doctorId,
      date: date,
      targetId: appointmentId,
      newStatus: 'completed',
      extra: <String, dynamic>{
        if (notes != null) 'notes': notes.trim(),
        if (diagnosis != null) 'diagnosis': diagnosis.trim(),
        if (prescription != null) 'prescription': prescription.trim(),
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Draft save - does not change the queue.
  Future<void> saveConsultationNotes({
    required String appointmentId,
    required String notes,
    required String diagnosis,
    required String prescription,
  }) async {
    await _appts.doc(appointmentId).update(<String, dynamic>{
      'notes': notes.trim(),
      'diagnosis': diagnosis.trim(),
      'prescription': prescription.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Bridge: patient bookings -> doctor queue ----------
  //
  // READ-ONLY on the teammates' `appointments` collection. New bookings for
  // this doctor are copied into `doctor_appointments` (doc id `bk_<bookingId>`,
  // so it is idempotent and never overwrites the doctor's own updates).

  Future<void> _syncChain = Future<void>.value();

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static String slotTimeFor(String session, int queueNo) {
    final base = session.toLowerCase().startsWith('e') ? 16 * 60 : 9 * 60;
    final minutes = base + (queueNo > 0 ? queueNo - 1 : 0) * 15;
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static int? _ageFromDob(String? dob) {
    final d = DateTime.tryParse(dob ?? '');
    if (d == null) return null;
    final now = DateTime.now();
    var age = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) {
      age--;
    }
    return age < 0 ? null : age;
  }

  /// Starts listening for today's patient bookings. Cancel the returned
  /// subscription in dispose(). Failures (e.g. rules) are only logged.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> startBookingSync({
    required String date,
    required DoctorProfile Function() profile,
    required Future<void> Function(String bookingDoctorId) onLinked,
  }) {
    return _db
        .collection('appointments')
        .where('date', isEqualTo: date)
        .snapshots()
        .listen(
      (snap) {
        final docs = snap.docs;
        _syncChain = _syncChain
            .then((_) => _importBookings(docs, date, profile(), onLinked))
            .catchError((Object e) {
          debugPrint('DoctorService booking import: $e');
        });
      },
      onError: (Object e) => debugPrint('DoctorService booking sync: $e'),
    );
  }

  Future<void> _importBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String date,
    DoctorProfile profile,
    Future<void> Function(String bookingDoctorId) onLinked,
  ) async {
    final wantName = _norm(profile.name);
    final linkedId = profile.bookingDoctorId;

    final matched = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    String? matchedDoctorId;
    for (final d in docs) {
      final m = d.data();
      if (_s(m['status'], 'upcoming') != 'upcoming') continue;
      final bookedDoctorId = _s(m['doctorId'], '');
      final byId =
          linkedId != null && linkedId.isNotEmpty && bookedDoctorId == linkedId;
      final byName =
          wantName.isNotEmpty && _norm(_s(m['doctorName'], '')) == wantName;
      if (byId || byName) {
        matched.add(d);
        if (bookedDoctorId.isNotEmpty) matchedDoctorId ??= bookedDoctorId;
      }
    }
    if (matched.isEmpty) return;

    if ((linkedId == null || linkedId.isEmpty) && matchedDoctorId != null) {
      await onLinked(matchedDoctorId);
    }

    final existing = await _fetchDay(profile.staffId, date);
    final have = existing.map((a) => a.id).toSet();

    final batch = _db.batch();
    var created = 0;
    for (final d in matched) {
      final id = 'bk_${d.id}';
      if (have.contains(id)) continue;
      final m = d.data();
      final queueNo = _i(m['queueNo'], 0);
      final session = _s(m['session'], 'Morning');
      final nic = _s(m['nic'], '').toUpperCase();

      batch.set(_appts.doc(id), <String, dynamic>{
        'doctorId': profile.staffId,
        'bookingId': d.id,
        'source': 'booking',
        'patientName': _s(m['patientName'], 'Patient'),
        'patientDisplayId': nic.isNotEmpty ? nic : _s(m['userId'], 'P00000'),
        'patientPhone': _s(m['contact'], ''),
        'patientAge': _ageFromDob(_opt(m['dob'])),
        'time': slotTimeFor(session, queueNo),
        'session': session,
        'room': profile.room,
        'type': 'Consultation',
        'status': 'upcoming',
        'queueNo': queueNo,
        'date': date,
        'notes': '',
        'diagnosis': '',
        'prescription': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      created++;
    }
    if (created == 0) return;

    await batch.commit();
    await _normalizeDay(profile.staffId, date);
    debugPrint('DoctorService: imported $created booking(s) for $date');
  }

  // ---------- Bootstrap + demo data ----------

  /// Called once when the dashboard opens. Never throws.
  Future<void> bootstrap(DoctorProfile profile) async {
    try {
      await seedDemoDataIfEmpty(profile.staffId, profile.room);
    } catch (e) {
      debugPrint('DoctorService bootstrap (appointments): $e');
    }
    await DoctorAvailabilityService.instance.seedIfNeeded(
      doctorId: profile.staffId,
      doctorName: profile.name,
      hospital: profile.hospital,
    );
  }

  /// Seeds sample appointments + patient records for [doctorId] when they
  /// have none today. Safe to call repeatedly; never throws.
  Future<void> seedDemoDataIfEmpty(String doctorId, String room) async {
    if (!enableDemoSeed) return;
    try {
      final today = todayKey();
      final existing = await _appts
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;

      Map<String, dynamic> appt(String name, String pid, String gender,
              int age, String time, String type, String status, int queueNo,
              {String notes = '',
              String diagnosis = '',
              String prescription = ''}) =>
          <String, dynamic>{
            'doctorId': doctorId,
            'patientName': name,
            'patientDisplayId': pid,
            'patientGender': gender,
            'patientAge': age,
            'time': time,
            'session': 'Morning',
            'room': room,
            'type': type,
            'status': status,
            'queueNo': queueNo,
            'date': today,
            'notes': notes,
            'diagnosis': diagnosis,
            'prescription': prescription,
            'source': 'demo',
            'createdAt': FieldValue.serverTimestamp(),
          };

      final demoAppointments = <Map<String, dynamic>>[
        appt('Nimal Perera', 'P12341', 'Male', 45, '09:00', 'Consultation',
            'completed', 1,
            notes: 'Patient complains of fever and cold.',
            diagnosis: 'Common Cold',
            prescription:
                '1. Paracetamol 500mg - 1-0-1\n2. Cetirizine 10mg - 0-0-1'),
        appt('Sanduni Silva', 'P12342', 'Female', 29, '09:15', 'Consultation',
            'in_progress', 2),
        appt('Kasun Fernando', 'P12345', 'Male', 34, '09:30', 'Consultation',
            'next', 3),
        appt('Dilani Wickramasinghe', 'P12346', 'Female', 52, '09:45',
            'Follow-up', 'upcoming', 4),
        appt('Tharindu Jayasinghe', 'P12347', 'Male', 38, '10:00',
            'Consultation', 'upcoming', 5),
        appt('Ishara Senanayake', 'P12348', 'Male', 61, '10:30',
            'Routine Checkup', 'upcoming', 6),
      ];

      Map<String, String> n(String title, String subtitle, [String? details]) =>
          <String, String>{
            'title': title,
            'subtitle': subtitle,
            if (details != null) 'details': details,
          };

      final patients = <String, Map<String, dynamic>>{
        'P12345': <String, dynamic>{
          'name': 'Kasun Fernando',
          'gender': 'Male',
          'age': 34,
          'phone': '071 234 5678',
          'address': 'No. 12, Matara',
          'bloodGroup': 'O+',
          'overview': [
            n('Diabetes', 'Diagnosed in 2020',
                'Type 2 diabetes mellitus. On Metformin 500mg. Review HbA1c every 3 months.'),
            n('Hypertension', 'Under medication since 2021',
                'Controlled on Amlodipine 5mg. Monitor blood pressure at every visit.'),
          ],
          'allergies': [
            n('Penicillin', 'mild reaction'),
            n('Dust', 'sneezing'),
          ],
          'conditions': [
            n('Type 2 Diabetes', '2020'),
            n('Hypertension', '2021'),
            n('High Cholesterol', '2022'),
          ],
          'medications': [
            n('Metformin 500mg', '1-0-1'),
            n('Amlodipine 5mg', '1-0-0'),
            n('Atorvastatin 20mg', '1-0-0'),
          ],
          'visits': [
            n('General Checkup', '2025-03-15'),
            n('Follow up (Diabetes)', '2025-01-10'),
          ],
        },
        'P12341': <String, dynamic>{
          'name': 'Nimal Perera',
          'gender': 'Male',
          'age': 45,
          'phone': '077 123 4567',
          'address': 'No. 5, Galle Road, Colombo',
          'bloodGroup': 'A+',
          'overview': [n('Asthma', 'Since childhood', 'Uses inhaler when needed.')],
          'allergies': [n('Pollen', 'seasonal rhinitis')],
          'conditions': [n('Bronchial Asthma', '2005')],
          'medications': [n('Salbutamol inhaler', 'as needed')],
          'visits': [n('Routine Checkup', '2025-02-02')],
        },
        'P12342': <String, dynamic>{
          'name': 'Sanduni Silva',
          'gender': 'Female',
          'age': 29,
          'phone': '076 555 0192',
          'address': 'No. 78, Kandy Road, Kegalle',
          'bloodGroup': 'B+',
          'overview': <Map<String, String>>[],
          'allergies': <Map<String, String>>[],
          'conditions': <Map<String, String>>[],
          'medications': <Map<String, String>>[],
          'visits': [n('General Checkup', '2024-11-20')],
        },
        'P12346': <String, dynamic>{
          'name': 'Dilani Wickramasinghe',
          'gender': 'Female',
          'age': 52,
          'phone': '070 321 8890',
          'address': 'No. 3, Temple Road, Gampaha',
          'bloodGroup': 'AB+',
          'overview': [n('Hypothyroidism', 'Since 2018', 'Stable on Levothyroxine.')],
          'allergies': [n('Sulfa drugs', 'rash')],
          'conditions': [n('Hypothyroidism', '2018')],
          'medications': [n('Levothyroxine 50mcg', '1-0-0')],
          'visits': [n('Thyroid review', '2025-02-18')],
        },
        'P12347': <String, dynamic>{
          'name': 'Tharindu Jayasinghe',
          'gender': 'Male',
          'age': 38,
          'phone': '072 410 7766',
          'address': 'No. 21, Lake Road, Kurunegala',
          'bloodGroup': 'O-',
          'overview': <Map<String, String>>[],
          'allergies': <Map<String, String>>[],
          'conditions': <Map<String, String>>[],
          'medications': <Map<String, String>>[],
          'visits': <Map<String, String>>[],
        },
        'P12348': <String, dynamic>{
          'name': 'Ishara Senanayake',
          'gender': 'Male',
          'age': 61,
          'phone': '071 998 3321',
          'address': 'No. 9, Hill Street, Nuwara Eliya',
          'bloodGroup': 'B-',
          'overview': [n('Hypertension', 'Since 2015', 'On Losartan 50mg.')],
          'allergies': <Map<String, String>>[],
          'conditions': [n('Hypertension', '2015')],
          'medications': [n('Losartan 50mg', '1-0-0')],
          'visits': [n('Blood pressure review', '2025-03-01')],
        },
      };

      final batch = _db.batch();
      for (final a in demoAppointments) {
        batch.set(_appts.doc(), a);
      }
      patients.forEach((id, data) {
        batch.set(_db.collection('patient_records').doc(id), data);
      });
      await batch.commit();
      debugPrint('DoctorService: demo data seeded for $doctorId on $today');
    } catch (e) {
      debugPrint('DoctorService seed note: $e');
    }
  }
}
