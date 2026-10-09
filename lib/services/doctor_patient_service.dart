import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'doctor_service.dart';

// ---------------------------------------------------------------------------
// patient_records/{patientId}   (owned by the doctor module)
//   name, gender, age, phone, address, bloodGroup
//   overview    [{title, subtitle, details?}]  chronic conditions shown on Overview
//   allergies   [{title, subtitle}]            e.g. Penicillin / mild reaction
//   conditions  [{title, subtitle}]            e.g. Hypertension / 2021
//   medications [{title, subtitle}]            e.g. Metformin 500mg / 1-0-1
//   visits      [{title, subtitle}]            subtitle = yyyy-MM-dd
//
// If no record exists (for example a patient that came in through the patient
// app) the screens fall back to what the appointment itself knows.
// ---------------------------------------------------------------------------

String _str(dynamic v) => v?.toString().trim() ?? '';

class PatientNote {
  final String title;
  final String subtitle;
  final String details;

  const PatientNote({
    required this.title,
    this.subtitle = '',
    this.details = '',
  });
}

class PatientVisit {
  final String date; // yyyy-MM-dd
  final String title;
  const PatientVisit({required this.date, required this.title});
}

List<PatientNote> _notes(dynamic raw) {
  if (raw is! List) return const <PatientNote>[];
  final out = <PatientNote>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final title = _str(e['title']);
    if (title.isEmpty) continue;
    out.add(PatientNote(
      title: title,
      subtitle: _str(e['subtitle']),
      details: _str(e['details']),
    ));
  }
  return out;
}

class PatientRecord {
  final String patientId;
  final String name;
  final String? gender;
  final int? age;
  final String phone;
  final String address;
  final String bloodGroup;
  final List<PatientNote> overview;
  final List<PatientNote> allergies;
  final List<PatientNote> conditions;
  final List<PatientNote> medications;
  final List<PatientNote> visits;

  const PatientRecord({
    required this.patientId,
    required this.name,
    this.gender,
    this.age,
    this.phone = '',
    this.address = '',
    this.bloodGroup = '',
    this.overview = const <PatientNote>[],
    this.allergies = const <PatientNote>[],
    this.conditions = const <PatientNote>[],
    this.medications = const <PatientNote>[],
    this.visits = const <PatientNote>[],
  });

  /// Minimal record built only from the appointment.
  factory PatientRecord.fromAppointment(DoctorAppointment a) => PatientRecord(
        patientId: a.patientId,
        name: a.patientName,
        gender: a.patientGender,
        age: a.patientAge,
        phone: a.patientPhone ?? '',
      );

  factory PatientRecord.fromMap(Map<String, dynamic> m, DoctorAppointment a) {
    final age = m['age'];
    final gender = _str(m['gender']);
    return PatientRecord(
      patientId: a.patientId,
      name: _str(m['name']).isEmpty ? a.patientName : _str(m['name']),
      gender: gender.isEmpty ? a.patientGender : gender,
      age: age is num ? age.toInt() : a.patientAge,
      phone: _str(m['phone']).isEmpty ? (a.patientPhone ?? '') : _str(m['phone']),
      address: _str(m['address']),
      bloodGroup: _str(m['bloodGroup']),
      overview: _notes(m['overview']),
      allergies: _notes(m['allergies']),
      conditions: _notes(m['conditions']),
      medications: _notes(m['medications']),
      visits: _notes(m['visits']),
    );
  }

  String get demographics {
    final parts = <String>[
      if (gender != null && gender!.isNotEmpty) gender!,
      if (age != null) '$age years',
    ];
    return parts.isEmpty ? 'Details not recorded' : parts.join(' · ');
  }

  /// "Penicillin (mild reaction), Dust (sneezing)" or a "none" message.
  String get allergySummary {
    if (allergies.isEmpty) return 'No known allergies';
    return allergies
        .map((a) => a.subtitle.isEmpty ? a.title : '${a.title} (${a.subtitle})')
        .join(', ');
  }
}

class DoctorPatientService {
  static final DoctorPatientService instance = DoctorPatientService._();
  DoctorPatientService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Never throws - falls back to what the appointment knows.
  Future<PatientRecord> loadRecord(DoctorAppointment appointment) async {
    try {
      final id = appointment.patientId.replaceAll('/', '_');
      final snap = await _db.collection('patient_records').doc(id).get();
      final data = snap.data();
      if (snap.exists && data != null) {
        return PatientRecord.fromMap(data, appointment);
      }
    } catch (e) {
      debugPrint('DoctorPatientService.loadRecord: $e');
    }
    return PatientRecord.fromAppointment(appointment);
  }

  /// Every appointment this doctor has had with the patient, newest first.
  Stream<List<DoctorAppointment>> patientAppointmentsStream(
      String patientId, String doctorId) {
    return _db
        .collection('doctor_appointments')
        .where('patientDisplayId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .where((d) =>
              doctorId.isEmpty || _str(d.data()['doctorId']) == doctorId)
          .map(DoctorAppointment.fromDoc)
          .toList();
      list.sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.time.compareTo(a.time);
      });
      return list;
    });
  }

  /// Manual history entries + completed visits recorded in this app,
  /// newest first.
  static List<PatientVisit> buildVisits(
      PatientRecord record, List<DoctorAppointment> appointments) {
    final out = <PatientVisit>[
      for (final v in record.visits)
        PatientVisit(date: v.subtitle, title: v.title),
      for (final a in appointments)
        if (a.isCompleted)
          PatientVisit(
            date: a.date,
            title: (a.diagnosis != null && a.diagnosis!.isNotEmpty)
                ? a.diagnosis!
                : a.type,
          ),
    ];
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }
}
