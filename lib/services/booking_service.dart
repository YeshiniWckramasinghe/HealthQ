import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Hospital {
  final String id, name, province, district, city, status;
  final int slotsLeft;
  const Hospital({
    required this.id,
    required this.name,
    required this.province,
    required this.district,
    required this.city,
    required this.status,
    required this.slotsLeft,
  });

  factory Hospital.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Hospital(
      id: d.id,
      name: m['name'] ?? '',
      province: m['province'] ?? '',
      district: m['district'] ?? '',
      city: m['city'] ?? '',
      status: m['status'] ?? 'open',
      slotsLeft: (m['slotsLeft'] ?? 0) as int,
    );
  }

  bool get isFull => status == 'full';
  String get label => switch (status) {
        'open' => 'OPD Open',
        'limited' => '$slotsLeft slots left',
        _ => 'Full',
      };
  Color get color => switch (status) {
        'open' => Colors.green,
        'limited' => Colors.orange,
        _ => Colors.red,
      };
}

class Doctor {
  final String id, name, speciality;
  int waiting;
  Doctor({
    required this.id,
    required this.name,
    required this.speciality,
    this.waiting = 0,
  });

  factory Doctor.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Doctor(
        id: d.id, name: m['name'] ?? '', speciality: m['speciality'] ?? '');
  }
}

class AppointmentRecord {
  final String id, hospitalName, doctorName, date, dateLabel, session, status;
  final int queueNo;
  final DateTime createdAt;
  AppointmentRecord({
    required this.id,
    required this.hospitalName,
    required this.doctorName,
    required this.date,
    required this.dateLabel,
    required this.session,
    required this.status,
    required this.queueNo,
    required this.createdAt,
  });

  factory AppointmentRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppointmentRecord(
      id: d.id,
      hospitalName: m['hospitalName'] ?? '',
      doctorName: m['doctorName'] ?? '',
      date: m['date'] ?? '',
      dateLabel: m['dateLabel'] ?? '',
      session: m['session'] ?? '',
      status: m['status'] ?? 'upcoming',
      queueNo: (m['queueNo'] ?? 0) as int,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class UserProfile {
  final String fullName, nic, dob, contact, email;
  const UserProfile({
    this.fullName = '',
    this.nic = '',
    this.dob = '',
    this.contact = '',
    this.email = '',
  });

  String get initials {
    final src = fullName.trim().isNotEmpty ? fullName.trim() : email.trim();
    if (src.isEmpty) return '?';
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class NotificationItem {
  final String id, title, body;
  final DateTime createdAt;
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory NotificationItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return NotificationItem(
      id: d.id,
      title: m['title'] ?? '',
      body: m['body'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BookingService {
  final _db = FirebaseFirestore.instance;

  static String queueKey(String hid, String did, String date, String session) =>
      '${hid}_${did}_${date}_$session';

  Future<List<Hospital>> getHospitals() async {
    final snap = await _db.collection('hospitals').get();
    final list = snap.docs.map(Hospital.fromDoc).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<Doctor>> getDoctors(String hospitalId) async {
    final snap = await _db
        .collection('hospitals')
        .doc(hospitalId)
        .collection('doctors')
        .get();
    return snap.docs.map(Doctor.fromDoc).toList();
  }

  /// Fills each doctor's `waiting` with the current queue count for that date/session.
  Future<void> loadWaiting(
      String hid, List<Doctor> docs, String date, String session) async {
    final snaps = await Future.wait([
      for (final d in docs)
        _db.collection('queues').doc(queueKey(hid, d.id, date, session)).get(),
    ]);
    for (var i = 0; i < docs.length; i++) {
      docs[i].waiting = (snaps[i].data()?['count'] ?? 0) as int;
    }
  }

  /// Books an appointment and returns the generated queue number.
  /// Runs in a transaction so two people can never get the same number.
  Future<int> book({
    required Hospital hospital,
    required Doctor doctor,
    required String date,
    required String dateLabel,
    required String session,
    required String patientName,
    required String nic,
    required String dob,
    required String contact,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please log in to book an appointment');

    final key = queueKey(hospital.id, doctor.id, date, session);
    final hRef = _db.collection('hospitals').doc(hospital.id);
    final qRef = _db.collection('queues').doc(key);
    final aRef = _db.collection('appointments').doc('${user.uid}_$key');
    final nRef = _db.collection('notifications').doc();
    final uRef = _db.collection('users').doc(user.uid);

    // Same format as the register screen: DD/MM/YYYY
    final dobDisplay = dob.length == 10 && dob.contains('-')
        ? '${dob.substring(8, 10)}/${dob.substring(5, 7)}/${dob.substring(0, 4)}'
        : dob;

    return _db.runTransaction<int>((tx) async {
      final h = await tx.get(hRef);
      if (h.data()?['status'] == 'full') {
        throw Exception('This hospital OPD is full');
      }
      if ((await tx.get(aRef)).exists) {
        throw Exception(
            'You already have an appointment with this doctor for that session');
      }
      final q = await tx.get(qRef);
      final u = await tx.get(uRef);
      final next = ((q.data()?['count'] ?? 0) as int) + 1;

      tx.set(qRef, {
        'count': next,
        'hospitalId': hospital.id,
        'doctorId': doctor.id,
        'date': date,
        'session': session,
      });
      tx.set(aRef, {
        'userId': user.uid,
        'hospitalId': hospital.id,
        'hospitalName': hospital.name,
        'doctorId': doctor.id,
        'doctorName': doctor.name,
        'speciality': doctor.speciality,
        'date': date,
        'dateLabel': dateLabel,
        'session': session,
        'patientName': patientName,
        'nic': nic,
        'dob': dob,
        'contact': contact,
        'queueNo': next,
        'status': 'upcoming',
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(nRef, {
        'userId': user.uid,
        'title': 'Appointment Confirmed',
        'body':
            'Your appointment at ${hospital.name} on $dateLabel is confirmed. Queue #$next.',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Fill missing profile fields from the first booking
      final um = u.data() ?? {};
      final fill = <String, dynamic>{
        if ((um['fullName'] ?? '') == '') 'fullName': patientName,
        if ((um['nic'] ?? '') == '') 'nic': nic,
        if ((um['dob'] ?? '') == '') 'dob': dobDisplay,
        if ((um['contactNo'] ?? um['contact'] ?? '') == '') 'contactNo': contact,
        if ((um['email'] ?? '') == '' && user.email != null) 'email': user.email,
      };
      if (fill.isNotEmpty) tx.set(uRef, fill, SetOptions(merge: true));
      return next;
    });
  }

  Stream<List<AppointmentRecord>> myAppointments() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(AppointmentRecord.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<UserProfile> myProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(const UserProfile());
    return _db.collection('users').doc(user.uid).snapshots().map((d) {
      final m = d.data() ?? {};
      return UserProfile(
        fullName: m['fullName'] ?? user.displayName ?? '',
        nic: m['nic'] ?? '',
        dob: m['dob'] ?? '',
        contact: m['contactNo'] ?? m['contact'] ?? user.phoneNumber ?? '',
        email: user.email ?? m['email'] ?? '',
      );
    });
  }

  Stream<List<NotificationItem>> myNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(NotificationItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Run ONCE (e.g. from main.dart) to fill an empty database with sample hospitals/doctors.
  Future<void> seedIfEmpty() async {
    try {
      final existing = await _db.collection('hospitals').limit(1).get();
      if (existing.docs.isNotEmpty) return;

      const hospitals = [
        ('city_general', 'City General Hospital', 'Western Province', 'Colombo', 'Colombo', 'open', 0),
        ('district_hospital', 'District Hospital', 'Western Province', 'Gampaha', 'Negombo', 'full', 0),
        ('teaching_hospital', 'Teaching Hospital', 'Central Province', 'Kandy', 'Kandy', 'limited', 3),
        ('karapitiya', 'Karapitiya Hospital', 'Southern Province', 'Galle', 'Galle', 'open', 0),
        ('jaffna_base', 'Jaffna Base Hospital', 'Northern Province', 'Jaffna', 'Jaffna', 'limited', 5),
        ('kurunegala', 'Kurunegala Hospital', 'North Western Province', 'Kurunegala', 'Kurunegala', 'open', 0),
      ];
      const doctors = [
        ('dr_perera', 'Dr. S. Perera', 'Internal Medicine'),
        ('dr_fernando', 'Dr. R. Fernando', 'General Surgery'),
        ('dr_silva', 'Dr. M. Silva', 'Paediatrics'),
      ];

      final batch = _db.batch();
      for (final h in hospitals) {
        final ref = _db.collection('hospitals').doc(h.$1);
        batch.set(ref, {
          'name': h.$2,
          'province': h.$3,
          'district': h.$4,
          'city': h.$5,
          'status': h.$6,
          'slotsLeft': h.$7,
        });
        for (final d in doctors) {
          batch.set(ref.collection('doctors').doc(d.$1),
              {'name': d.$2, 'speciality': d.$3});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('BookingService.seedIfEmpty skipped or failed: $e');
    }
  }
}