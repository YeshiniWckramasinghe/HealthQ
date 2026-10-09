import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'queue_status_screen.dart' show QueuePatient;

// ============================================================================
// LIVE QUEUE SNAPSHOT
//
// One object that carries everything the Estimated Waiting Time, My Turn,
// Missed My Turn and New Queue Status screens need.
// ============================================================================

class QueueLiveData {
  const QueueLiveData({
    required this.appointmentId,
    required this.yourQueueNumber,
    required this.patients,
    required this.patientsAhead,
    required this.averageMinutesPerPatient,
    required this.myStatus,
  });

  final String appointmentId;
  final int yourQueueNumber;
  final List<QueuePatient> patients;
  final int patientsAhead;
  final int averageMinutesPerPatient;

  /// queueStatus field of the appointment document (Waiting / Missed / ...).
  final String myStatus;

  int get estimatedMinutes {
    if (patientsAhead <= 0) return 1;
    final minutes = patientsAhead * averageMinutesPerPatient;
    return minutes < 1 ? 1 : minutes;
  }

  /// It is the patient's turn when nobody active is ahead, or when the
  /// staff side has already called / started this patient.
  bool get isMyTurn {
    final status = myStatus.toLowerCase();

    if (status.contains('called') ||
        status.contains('your turn') ||
        status.contains('consult')) {
      return true;
    }

    return yourQueueNumber > 0 && patientsAhead <= 0;
  }

  /// Patient currently being served (same rule as QueueStatusScreen).
  QueuePatient? get currentlyServing {
    if (patients.isEmpty) return null;

    for (final patient in patients) {
      if (patient.status.toLowerCase().contains('consult')) {
        return patient;
      }
    }

    for (final patient in patients) {
      if (!QueueBackend.isFinished(patient.status)) {
        return patient;
      }
    }

    return patients.first;
  }
}

// ============================================================================
// LIVE WATCHER
//
// Listens to BOTH the appointment document and the queues collection and
// pushes a fresh QueueLiveData whenever either one changes.
// ============================================================================

class QueueLiveWatcher {
  QueueLiveWatcher({
    required this.appointmentId,
    required this.onData,
    this.onError,
  });

  final String appointmentId;
  final void Function(QueueLiveData data) onData;
  final void Function(Object error)? onError;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _appointmentSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _queuesSub;

  Map<String, dynamic>? _appointment;
  QuerySnapshot<Map<String, dynamic>>? _queues;

  void start() {
    final firestore = FirebaseFirestore.instance;

    _appointmentSub = firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .listen(
      (snapshot) {
        _appointment = snapshot.data();
        _emit();
      },
      onError: (Object error) => onError?.call(error),
    );

    _queuesSub = firestore.collection('queues').snapshots().listen(
      (snapshot) {
        _queues = snapshot;
        _emit();
      },
      onError: (Object error) => onError?.call(error),
    );
  }

  void dispose() {
    _appointmentSub?.cancel();
    _queuesSub?.cancel();
  }

  void _emit() {
    final appointment = _appointment;
    final queues = _queues;

    if (appointment == null || queues == null) return;

    final hospital = (appointment['hospitalName'] ?? appointment['hospital'] ?? '')
        .toString();
    final doctor =
        (appointment['doctorName'] ?? appointment['doctor'] ?? '').toString();
    final date = (appointment['date'] ?? '').toString();
    final session = (appointment['session'] ?? '').toString();
    final patientName = (appointment['patientName'] ?? '').toString();

    final myNumber = QueueBackend.readInt(
      appointment['queueNumber'] ?? appointment['queueNo'],
    );

    final patients = <QueuePatient>[];

    for (final doc in queues.docs) {
      final data = doc.data();

      if (!QueueBackend.matchesSession(
        data: data,
        hospital: hospital,
        doctor: doctor,
        date: date,
        session: session,
      )) {
        continue;
      }

      final number = QueueBackend.readInt(data['queueNumber']);
      if (number <= 0) continue;

      patients.add(
        QueuePatient(
          queueNumber: number.toString().padLeft(2, '0'),
          patientName: data['patientName']?.toString() ?? 'Patient $number',
          doctorName: data['doctorName']?.toString() ?? doctor,
          status: data['status']?.toString() ?? 'Waiting',
        ),
      );
    }

    // Missed / cancelled patients are no longer part of the live line.
    patients.removeWhere(
      (p) => QueueBackend.isMissedOrCancelled(p.status),
    );

    // Make sure the patient's own entry is always present.
    final hasMe = patients.any(
      (p) => int.tryParse(p.queueNumber) == myNumber,
    );

    if (!hasMe && myNumber > 0) {
      patients.add(
        QueuePatient(
          queueNumber: myNumber.toString().padLeft(2, '0'),
          patientName: patientName.isEmpty ? 'You' : patientName,
          doctorName: doctor,
          status: 'Waiting',
        ),
      );
    }

    patients.sort(
      (a, b) => (int.tryParse(a.queueNumber) ?? 0)
          .compareTo(int.tryParse(b.queueNumber) ?? 0),
    );

    var ahead = 0;
    for (final p in patients) {
      final n = int.tryParse(p.queueNumber) ?? 0;
      if (n > 0 && n < myNumber && !QueueBackend.isFinished(p.status)) {
        ahead++;
      }
    }

    final average = QueueBackend.readInt(appointment['averageMinutesPerPatient']);

    onData(
      QueueLiveData(
        appointmentId: appointmentId,
        yourQueueNumber: myNumber,
        patients: patients,
        patientsAhead: ahead,
        averageMinutesPerPatient:
            average > 0 ? average : QueueBackend.defaultAverageMinutes,
        myStatus: (appointment['queueStatus'] ?? '').toString(),
      ),
    );
  }
}

// ============================================================================
// QUEUE BACKEND (writes)
// ============================================================================

class QueueBackend {
  QueueBackend._();

  static const int defaultAverageMinutes = 5;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // Helpers shared with the live watcher
  // --------------------------------------------------------------------------

  static int readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool isFinished(String status) {
    final s = status.toLowerCase();
    return s == 'completed' || isMissedOrCancelled(s);
  }

  static bool isMissedOrCancelled(String status) {
    final s = status.toLowerCase();
    return s == 'missed' || s == 'cancelled' || s == 'canceled';
  }

  static bool matchesSession({
    required Map<String, dynamic> data,
    required String hospital,
    required String doctor,
    required String date,
    required String session,
  }) {
    return data['hospital']?.toString() == hospital &&
        data['doctorName']?.toString() == doctor &&
        data['session']?.toString() == session &&
        _isSameDate(data['date'], date);
  }

  // Same rule QueueStatusScreen already uses:
  // appointment "2026-10-09"  ==  queue "9 Oct 2026" / "09 Oct 2026".
  static bool _isSameDate(dynamic queueDate, String appointmentDate) {
    if (queueDate == null || appointmentDate.trim().isEmpty) return false;

    final queueText = queueDate.toString().trim();
    final appointmentText = appointmentDate.trim();

    if (queueText == appointmentText) return true;

    try {
      final parts = appointmentText.split('-');

      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];

        if (month >= 1 && month <= 12) {
          final plain = '$day ${months[month - 1]} $year';
          final padded = '${day.toString().padLeft(2, '0')} ${months[month - 1]} $year';

          return queueText == plain || queueText == padded;
        }
      }
    } catch (_) {}

    return false;
  }

  // --------------------------------------------------------------------------
  // Find the user's active (checked-in) appointment id
  // --------------------------------------------------------------------------

  static Future<String?> findMyAppointmentId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .where('checkedIn', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return null;

    for (final doc in snapshot.docs) {
      final status = (doc.data()['queueStatus'] ?? '').toString().toLowerCase();
      if (status == 'waiting') return doc.id;
    }

    return snapshot.docs.first.id;
  }

  // --------------------------------------------------------------------------
  // "I'm on my way"  ->  appointment completed
  // --------------------------------------------------------------------------

  static Future<void> completeTurn(String appointmentId) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointmentId);

    final appointment = await appointmentRef.get();
    final data = appointment.data();
    if (data == null) return;

    await appointmentRef.update({
      'status': 'completed',
      'queueStatus': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateMyQueueDoc(data, {'status': 'Completed'});

    await _notify(
      data,
      appointmentId,
      title: 'Appointment Completed',
      body:
          'Your queue turn ${readInt(data['queueNumber'] ?? data['queueNo'])} has been marked as completed.',
      type: 'queue_completed',
    );
  }

  // --------------------------------------------------------------------------
  // Missed turn (timer ended or "I need more time")
  // --------------------------------------------------------------------------

  static Future<void> markMissed(String appointmentId) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointmentId);

    final appointment = await appointmentRef.get();
    final data = appointment.data();
    if (data == null) return;

    await appointmentRef.update({
      'queueStatus': 'Missed',
      'missedAt': FieldValue.serverTimestamp(),
      'missedCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _updateMyQueueDoc(data, {'status': 'Missed'});

    await _notify(
      data,
      appointmentId,
      title: 'Missed My Turn',
      body:
          'Your queue position has changed because there was no response within 5 minutes.',
      type: 'queue_missed',
    );
  }

  // --------------------------------------------------------------------------
  // Rejoin after a missed turn  ->  new queue number at the end of the line
  // --------------------------------------------------------------------------

  static Future<int> rejoinQueue(String appointmentId) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointmentId);

    final appointment = await appointmentRef.get();
    final data = appointment.data();

    if (data == null) {
      throw Exception('Appointment not found.');
    }

    final hospital =
        (data['hospitalName'] ?? data['hospital'] ?? '').toString();
    final doctor = (data['doctorName'] ?? data['doctor'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final session = (data['session'] ?? '').toString();
    final oldNumber = readInt(data['queueNumber'] ?? data['queueNo']);

    // Highest number already used in this doctor / date / session queue.
    final userId = (data['userId'] ?? '').toString();
    final queueSnapshot = await _firestore.collection('queues').get();
    DocumentReference<Map<String, dynamic>>? myQueueRef;
    var userMatched = false;
    var highest = oldNumber;

    for (final doc in queueSnapshot.docs) {
      final q = doc.data();

      if (!matchesSession(
        data: q,
        hospital: hospital,
        doctor: doctor,
        date: date,
        session: session,
      )) {
        continue;
      }

      final number = readInt(q['queueNumber']);
      if (number > highest) highest = number;

      // The queue document carries the patient's userId, so match on that
      // first and only fall back to the queue number.
      if (userId.isNotEmpty && q['userId']?.toString() == userId) {
        myQueueRef = doc.reference;
        userMatched = true;
      } else if (!userMatched && number == oldNumber) {
        myQueueRef = doc.reference;
      }
    }

    // Same counter document AppointmentService uses, so booking and rejoin
    // can never hand out the same number.
    final counterRef = _firestore
        .collection('queue_counters')
        .doc(_counterId(data, hospital, doctor, date, session));

    final newNumber = await _firestore.runTransaction<int>((transaction) async {
      final counter = await transaction.get(counterRef);

      var last = 0;
      if (counter.exists) {
        last = readInt(counter.data()?['lastNumber']);
      }

      final next = (last > highest ? last : highest) + 1;

      transaction.set(
        counterRef,
        {
          'hospitalId': (data['hospitalId'] ?? '').toString(),
          'doctorId': (data['doctorId'] ?? '').toString(),
          'hospitalName': hospital,
          'doctorName': doctor,
          'date': date,
          'session': session,
          'lastNumber': next,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return next;
    });

    await appointmentRef.update({
      'previousQueueNumber': oldNumber,
      'queueNo': newNumber,
      'queueNumber': newNumber,
      'queueStatus': 'Waiting',
      'rejoinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (myQueueRef != null) {
      await myQueueRef.update({
        'queueNumber': newNumber,
        'status': 'Waiting',
      });
    }

    await _notify(
      data,
      appointmentId,
      title: 'New Queue Number',
      body: 'You have rejoined the queue. Your new queue number is $newNumber.',
      type: 'queue_rejoined',
    );

    return newNumber;
  }

  // --------------------------------------------------------------------------
  // "It's your turn" notification (written once by the waiting-time screen)
  // --------------------------------------------------------------------------

  static Future<void> notifyYourTurn(String appointmentId) async {
    final appointment =
        await _firestore.collection('appointments').doc(appointmentId).get();
    final data = appointment.data();
    if (data == null) return;

    await _notify(
      data,
      appointmentId,
      title: "It's Your Turn",
      body:
          'Your queue number ${readInt(data['queueNumber'] ?? data['queueNo'])} is now ready. Please proceed to the consultation room.',
      type: 'queue_your_turn',
    );
  }

  // --------------------------------------------------------------------------
  // Internals
  // --------------------------------------------------------------------------

  static String _counterId(
    Map<String, dynamic> data,
    String hospital,
    String doctor,
    String date,
    String session,
  ) {
    String safe(String v) => v.trim().replaceAll('/', '_').replaceAll(' ', '_');

    final hospitalId = (data['hospitalId'] ?? '').toString().trim();
    final doctorId = (data['doctorId'] ?? '').toString().trim();

    final hospitalPart = hospitalId.isNotEmpty ? hospitalId : hospital.trim();
    final doctorPart = doctorId.isNotEmpty ? doctorId : doctor.trim();

    return '${safe(hospitalPart)}_${safe(doctorPart)}_${safe(date)}_${safe(session)}';
  }

  /// Updates the matching document in `queues` (if one exists for this patient).
  static Future<void> _updateMyQueueDoc(
    Map<String, dynamic> appointment,
    Map<String, dynamic> changes,
  ) async {
    final hospital =
        (appointment['hospitalName'] ?? appointment['hospital'] ?? '').toString();
    final doctor =
        (appointment['doctorName'] ?? appointment['doctor'] ?? '').toString();
    final date = (appointment['date'] ?? '').toString();
    final session = (appointment['session'] ?? '').toString();
    final number = readInt(appointment['queueNumber'] ?? appointment['queueNo']);

    final userId = (appointment['userId'] ?? '').toString();
    final snapshot = await _firestore.collection('queues').get();

    DocumentReference<Map<String, dynamic>>? target;

    for (final doc in snapshot.docs) {
      final q = doc.data();

      if (!matchesSession(
        data: q,
        hospital: hospital,
        doctor: doctor,
        date: date,
        session: session,
      )) {
        continue;
      }

      // Prefer the userId match; fall back to the queue number.
      if (userId.isNotEmpty && q['userId']?.toString() == userId) {
        target = doc.reference;
        break;
      }

      if (target == null && readInt(q['queueNumber']) == number) {
        target = doc.reference;
      }
    }

    if (target != null) {
      await target.update(changes);
    }
  }

  static Future<void> _notify(
    Map<String, dynamic> appointment,
    String appointmentId, {
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final userId = (appointment['userId'] ?? '').toString();
      if (userId.isEmpty) return;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'appointmentId': appointmentId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // A failed notification must never block the queue flow.
    }
  }
}