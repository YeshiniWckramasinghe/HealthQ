import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'check_in_screen.dart';

class AppointmentService {
  AppointmentService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ===========================================================================
  // CURRENT USER
  // ===========================================================================

  static String get _currentUserId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No authenticated user found. Please log in again.',
      );
    }

    return user.uid;
  }

  // ===========================================================================
  // CREATE APPOINTMENT
  // ===========================================================================

  static Future<CheckInAppointment> createAppointment({
    required CheckInAppointment appointment,
    String? doctorId,
    String? hospitalId,
  }) async {
    final uid = _currentUserId;

    final nic = appointment.nic.trim().toUpperCase();

    if (nic.isEmpty) {
      throw Exception('NIC is required.');
    }

    if (appointment.patient.trim().isEmpty) {
      throw Exception('Patient name is required.');
    }

    if (appointment.hospital.trim().isEmpty) {
      throw Exception('Hospital is required.');
    }

    if (appointment.doctor.trim().isEmpty) {
      throw Exception('Doctor is required.');
    }

    if (appointment.session.trim().isEmpty) {
      throw Exception('Session is required.');
    }

    final cleanDate =
        _normaliseDateForQuery(appointment.date);

    final cleanSession =
        _normaliseSession(appointment.session);

    // -------------------------------------------------------------------------
    // Check whether this user already has an appointment for the same
    // doctor/date/session.
    // -------------------------------------------------------------------------

    final existingAppointments = await _firestore
        .collection('appointments')
        .where(
          'userId',
          isEqualTo: uid,
        )
        .where(
          'date',
          isEqualTo: cleanDate,
        )
        .where(
          'doctorName',
          isEqualTo: appointment.doctor.trim(),
        )
        .where(
          'session',
          isEqualTo: cleanSession,
        )
        .get();

    for (final document in existingAppointments.docs) {
      final data = document.data();

      final status = (data['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final existingNic = (data['nic'] ?? '')
          .toString()
          .trim()
          .toUpperCase();

      if (status == 'upcoming' &&
          existingNic == nic) {
        return _convertToAppointment(
          document.id,
          data,
        );
      }
    }

    // -------------------------------------------------------------------------
    // Generate a unique queue number.
    //
    // Firestore transaction makes this safer when multiple patients
    // book at the same time.
    // -------------------------------------------------------------------------

    final queueNumber = await _generateQueueNumber(
      hospitalId: hospitalId ?? '',
      doctorId: doctorId ?? '',
      hospitalName: appointment.hospital,
      doctorName: appointment.doctor,
      date: cleanDate,
      session: cleanSession,
    );

    // -------------------------------------------------------------------------
    // Create appointment document.
    // -------------------------------------------------------------------------

    final appointmentRef =
        _firestore.collection('appointments').doc();

    final appointmentData = <String, dynamic>{
      'userId': uid,

      'nic': nic,
      'patientName': appointment.patient.trim(),
      'contact': appointment.contact.trim(),
      'dob': appointment.dateOfBirth.trim(),

      'hospitalId': hospitalId ?? '',
      'hospitalName': appointment.hospital.trim(),

      'doctorId': doctorId ?? '',
      'doctorName': appointment.doctor.trim(),

      'speciality': appointment.speciality.trim(),

      'date': cleanDate,
      'dateLabel': appointment.date.trim(),

      'session': cleanSession,

      // Both fields are kept because the existing project
      // already uses both names.
      'queueNo': queueNumber,
      'queueNumber': queueNumber,

      'status': 'upcoming',
      'queueStatus': 'Waiting',

      'checkedIn': false,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await appointmentRef.set(
      appointmentData,
    );

    // -------------------------------------------------------------------------
    // Create notification.
    // -------------------------------------------------------------------------

    await _firestore
        .collection('notifications')
        .add({
      'userId': uid,
      'title': 'Appointment Confirmed',
      'body':
          'Your appointment at ${appointment.hospital} on ${appointment.date} is confirmed. Queue #$queueNumber.',
      'createdAt': FieldValue.serverTimestamp(),
      'appointmentId': appointmentRef.id,
      'type': 'appointment_confirmation',
      'read': false,
    });

    // -------------------------------------------------------------------------
    // Return appointment object to the UI.
    // -------------------------------------------------------------------------

    return CheckInAppointment(
      appointmentId: appointmentRef.id,
      nic: nic,
      hospital: appointment.hospital,
      date: appointment.date,
      session: appointment.session,
      doctor: appointment.doctor,
      speciality: appointment.speciality,
      patient: appointment.patient,
      contact: appointment.contact,
      dateOfBirth: appointment.dateOfBirth,
      estimatedQueueNumber: queueNumber.toString(),
    );
  }

  // ===========================================================================
  // GENERATE QUEUE NUMBER
  // ===========================================================================

  static Future<int> _generateQueueNumber({
    required String hospitalId,
    required String doctorId,
    required String hospitalName,
    required String doctorName,
    required String date,
    required String session,
  }) async {
    // -------------------------------------------------------------------------
    // Use IDs when available.
    // Otherwise use names.
    // -------------------------------------------------------------------------

    final hospitalPart = hospitalId.trim().isNotEmpty
        ? hospitalId.trim()
        : hospitalName.trim();

    final doctorPart = doctorId.trim().isNotEmpty
        ? doctorId.trim()
        : doctorName.trim();

    final safeHospital =
        _safeDocumentPart(hospitalPart);

    final safeDoctor =
        _safeDocumentPart(doctorPart);

    final safeDate =
        _safeDocumentPart(date);

    final safeSession =
        _safeDocumentPart(session);

    final counterId =
        '${safeHospital}_${safeDoctor}_${safeDate}_$safeSession';

    final counterRef = _firestore
        .collection('queue_counters')
        .doc(counterId);

    return _firestore.runTransaction<int>(
      (transaction) async {
        final snapshot =
            await transaction.get(counterRef);

        int currentNumber = 0;

        if (snapshot.exists) {
          final data = snapshot.data();

          if (data != null) {
            currentNumber =
                _toInt(data['lastNumber']);
          }
        }

        final nextNumber =
            currentNumber + 1;

        transaction.set(
          counterRef,
          {
            'hospitalId': hospitalId,
            'doctorId': doctorId,
            'hospitalName': hospitalName.trim(),
            'doctorName': doctorName.trim(),
            'date': date,
            'session': session,
            'lastNumber': nextNumber,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        return nextNumber;
      },
    );
  }

  // ===========================================================================
  // FIND APPOINTMENT
  // ===========================================================================

  static Future<CheckInAppointment?> findAppointment({
    required String nic,
    String? appointmentId,
  }) async {
    try {
      final cleanedNic =
          nic.trim().toUpperCase();

      final cleanedAppointmentId =
          appointmentId?.trim();

      if (cleanedNic.isEmpty) {
        return null;
      }

      // -----------------------------------------------------------------------
      // 1. Appointment ID + NIC lookup
      // -----------------------------------------------------------------------

      if (cleanedAppointmentId != null &&
          cleanedAppointmentId.isNotEmpty) {
        final appointmentDocument =
            await _firestore
                .collection('appointments')
                .doc(cleanedAppointmentId)
                .get();

        if (appointmentDocument.exists) {
          final data =
              appointmentDocument.data();

          if (data != null) {
            final documentNic =
                (data['nic'] ?? '')
                    .toString()
                    .trim()
                    .toUpperCase();

            if (documentNic == cleanedNic) {
              return _convertToAppointment(
                appointmentDocument.id,
                data,
              );
            }
          }
        }
      }

      // -----------------------------------------------------------------------
      // 2. NIC lookup
      // -----------------------------------------------------------------------

      final querySnapshot =
          await _firestore
              .collection('appointments')
              .where(
                'nic',
                isEqualTo: cleanedNic,
              )
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // -----------------------------------------------------------------------
      // Prefer upcoming appointment.
      // -----------------------------------------------------------------------

      QueryDocumentSnapshot<
          Map<String, dynamic>>?
          selectedDocument;

      for (final document
          in querySnapshot.docs) {
        final data = document.data();

        final status =
            (data['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        if (status == 'upcoming') {
          selectedDocument = document;
          break;
        }
      }

      // If there is no upcoming appointment,
      // use the first matching appointment.
      selectedDocument ??=
          querySnapshot.docs.first;

      return _convertToAppointment(
        selectedDocument.id,
        selectedDocument.data(),
      );
    } catch (e) {
      throw Exception(
        'Unable to retrieve appointment from Firestore: $e',
      );
    }
  }

  // ===========================================================================
  // GET MY UPCOMING APPOINTMENTS
  // ===========================================================================

  static Stream<
      List<DocumentSnapshot<Map<String, dynamic>>>>
      watchMyAppointments() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <DocumentSnapshot<Map<String, dynamic>>>[],
      );
    }

    return _firestore
        .collection('appointments')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (snapshot) {
        final documents =
            List<DocumentSnapshot<
                Map<String, dynamic>>>.from(
          snapshot.docs,
        );

        documents.sort(
          (a, b) {
            final aData = a.data();
            final bData = b.data();

            final aCreated =
                aData?['createdAt'];

            final bCreated =
                bData?['createdAt'];

            if (aCreated is Timestamp &&
                bCreated is Timestamp) {
              return bCreated.compareTo(
                aCreated,
              );
            }

            return 0;
          },
        );

        return documents;
      },
    );
  }

  // ===========================================================================
  // UPDATE APPOINTMENT STATUS
  // ===========================================================================

  static Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    if (appointmentId.trim().isEmpty) {
      throw Exception(
        'Appointment ID is required.',
      );
    }

    await _firestore
        .collection('appointments')
        .doc(appointmentId.trim())
        .update({
      'status': status,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // MARK APPOINTMENT AS CHECKED IN
  // ===========================================================================

  static Future<void> markAsCheckedIn({
    required String appointmentId,
    required int queueNumber,
  }) async {
    if (appointmentId.trim().isEmpty) {
      throw Exception(
        'Appointment ID is required.',
      );
    }

    await _firestore
        .collection('appointments')
        .doc(appointmentId.trim())
        .update({
      'queueNo': queueNumber,
      'queueNumber': queueNumber,
      'queueStatus': 'Waiting',
      'checkedIn': true,
      'checkedInAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ===========================================================================
  // CONVERT FIRESTORE → CHECK IN APPOINTMENT
  // ===========================================================================

  static CheckInAppointment _convertToAppointment(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final queueValue =
        data['queueNo'] ??
            data['queueNumber'] ??
            '';

    return CheckInAppointment(
      appointmentId: documentId,

      nic:
          (data['nic'] ?? '')
              .toString(),

      hospital:
          (data['hospitalName'] ??
                  data['hospital'] ??
                  '')
              .toString(),

      date:
          (data['dateLabel'] ??
                  data['date'] ??
                  '')
              .toString(),

      session:
          (data['session'] ?? '')
              .toString(),

      doctor:
          (data['doctorName'] ??
                  data['doctor'] ??
                  '')
              .toString(),

      speciality:
          (data['speciality'] ??
                  data['specialty'] ??
                  '')
              .toString(),

      patient:
          (data['patientName'] ??
                  data['patient'] ??
                  '')
              .toString(),

      contact:
          (data['contact'] ??
                  data['contactNo'] ??
                  '')
              .toString(),

      dateOfBirth:
          (data['dob'] ??
                  data['dateOfBirth'] ??
                  '')
              .toString(),

      estimatedQueueNumber:
          queueValue.toString(),
    );
  }

  // ===========================================================================
  // GET NEXT QUEUE NUMBER
  //
  // Kept as a public helper because other screens may already use it.
  // ===========================================================================

  static Future<int> getNextQueueNumber({
    required String doctorName,
    required String date,
    required String session,
  }) async {
    final cleanDoctor =
        doctorName.trim();

    final cleanDate =
        _normaliseDateForQuery(date);

    final cleanSession =
        _normaliseSession(session);

    final snapshot = await _firestore
        .collection('appointments')
        .where(
          'doctorName',
          isEqualTo: cleanDoctor,
        )
        .where(
          'date',
          isEqualTo: cleanDate,
        )
        .where(
          'session',
          isEqualTo: cleanSession,
        )
        .get();

    int maximum = 0;

    for (final document in snapshot.docs) {
      final data = document.data();

      final number =
          _toInt(
        data['queueNo'] ??
            data['queueNumber'],
      );

      if (number > maximum) {
        maximum = number;
      }
    }

    return maximum + 1;
  }

  // ===========================================================================
  // NORMALISE DATE
  // ===========================================================================

  static String _normaliseDateForQuery(
    String value,
  ) {
    final trimmed =
        value.trim();

    if (RegExp(
      r'^\d{4}-\d{2}-\d{2}$',
    ).hasMatch(trimmed)) {
      return trimmed;
    }

    return trimmed;
  }

  // ===========================================================================
  // NORMALISE SESSION
  // ===========================================================================

  static String _normaliseSession(
    String value,
  ) {
    final trimmed =
        value.trim();

    final lower =
        trimmed.toLowerCase();

    if (lower.startsWith('morning')) {
      return 'Morning';
    }

    if (lower.startsWith('afternoon')) {
      return 'Afternoon';
    }

    if (lower.startsWith('evening')) {
      return 'Evening';
    }

    return trimmed;
  }

  // ===========================================================================
  // SAFE FIRESTORE DOCUMENT PART
  // ===========================================================================

  static String _safeDocumentPart(
    String value,
  ) {
    return value
        .trim()
        .replaceAll(
          '/',
          '_',
        )
        .replaceAll(
          ' ',
          '_',
        );
  }

  // ===========================================================================
  // CONVERT TO INTEGER
  // ===========================================================================

  static int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}