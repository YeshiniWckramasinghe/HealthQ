import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Firestore contract (doctor module)
//
// doctor_availability/{doctorId}_{yyyy-MM-dd}_{HHmm}
//   doctorId, date, startTime, endTime
//   status          'available' | 'unavailable'      <- effective status, only
//                                                       changes after approval
//   requestStatus   'none' | 'pending' | 'approved' | 'rejected'
//   requestedStatus 'available' | 'unavailable'      (while a request exists)
//   requestId       'REQ-2026-1547'                  (while a request exists)
//
// availability_requests/{REQ-yyyy-NNNN}
//   doctorId, doctorName, hospital, slotId, date, startTime, endTime,
//   currentStatus, requestedStatus, reason,
//   status 'pending' | 'approved' | 'rejected' | 'cancelled',
//   submittedAt, reviewedAt?, reviewedBy?, reviewerNote?
//
// The hospital-staff side can approve / reject with [resolveRequest].
// ---------------------------------------------------------------------------

String _s(dynamic v, String fallback) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? fallback : t;
}

String? _opt(dynamic v) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? null : t;
}

DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class DoctorAvailabilitySlot {
  final String id;
  final String doctorId;
  final String date; // yyyy-MM-dd
  final String startTime; // HH:mm
  final String endTime; // HH:mm

  /// Effective availability: 'available' | 'unavailable'.
  final String status;

  /// 'none' | 'pending' | 'approved' | 'rejected'.
  final String requestStatus;
  final String? requestedStatus;
  final String? requestId;

  const DoctorAvailabilitySlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.requestStatus = 'none',
    this.requestedStatus,
    this.requestId,
  });

  factory DoctorAvailabilitySlot.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    var status = _s(m['status'], 'available');
    var request = _s(m['requestStatus'], 'none');

    // Older builds stored the request state directly in `status`.
    if (status == 'pending' || status == 'approved' || status == 'rejected') {
      request = status;
      status = 'available';
    }
    if (status != 'available' && status != 'unavailable') status = 'available';
    if (!const ['none', 'pending', 'approved', 'rejected'].contains(request)) {
      request = 'none';
    }

    return DoctorAvailabilitySlot(
      id: d.id,
      doctorId: _s(m['doctorId'], ''),
      date: _s(m['date'], ''),
      startTime: _s(m['startTime'], '09:00'),
      endTime: _s(m['endTime'], '10:00'),
      status: status,
      requestStatus: request,
      requestedStatus: _opt(m['requestedStatus']),
      requestId: _opt(m['requestId']),
    );
  }

  /// What the badge in the slot list shows.
  String get displayStatus => requestStatus == 'none' ? status : requestStatus;

  bool get isUnavailable => status == 'unavailable';
  bool get hasOpenRequest => requestStatus == 'pending' && requestId != null;
  bool get hasRequest => requestId != null && requestStatus != 'none';
  String get label => '$startTime - $endTime';
}

class AvailabilityRequest {
  final String id;
  final String doctorId;
  final String doctorName;
  final String hospital;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final String currentStatus;
  final String requestedStatus;
  final String reason;

  /// 'pending' | 'approved' | 'rejected' | 'cancelled'.
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerNote;

  const AvailabilityRequest({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.hospital,
    required this.slotId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.currentStatus,
    required this.requestedStatus,
    required this.reason,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerNote,
  });

  factory AvailabilityRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return AvailabilityRequest(
      id: d.id,
      doctorId: _s(m['doctorId'], ''),
      doctorName: _s(m['doctorName'], 'Doctor'),
      hospital: _s(m['hospital'], ''),
      slotId: _s(m['slotId'], ''),
      date: _s(m['date'], ''),
      startTime: _s(m['startTime'], '09:00'),
      endTime: _s(m['endTime'], '10:00'),
      currentStatus: _s(m['currentStatus'], 'available'),
      requestedStatus: _s(m['requestedStatus'], 'unavailable'),
      reason: _s(m['reason'], '-'),
      status: _s(m['status'], 'pending'),
      submittedAt: _ts(m['submittedAt']) ?? DateTime.now(),
      reviewedAt: _ts(m['reviewedAt']),
      reviewedBy: _opt(m['reviewedBy']),
      reviewerNote: _opt(m['reviewerNote']),
    );
  }

  bool get isPending => status == 'pending';
  String get slotLabel => '$startTime – $endTime';
}

class AvailabilitySummary {
  final String? nextActiveDate;
  final int totalSlots;
  final Map<String, int> slotsPerDate;

  const AvailabilitySummary({
    this.nextActiveDate,
    this.totalSlots = 0,
    this.slotsPerDate = const <String, int>{},
  });

  factory AvailabilitySummary.fromSlots(List<DoctorAvailabilitySlot> slots) {
    final perDate = <String, int>{};
    String? next;
    for (final s in slots) {
      perDate[s.date] = (perDate[s.date] ?? 0) + 1;
      if (s.status == 'available' &&
          (next == null || s.date.compareTo(next) < 0)) {
        next = s.date;
      }
    }
    return AvailabilitySummary(
      nextActiveDate: next,
      totalSlots: slots.length,
      slotsPerDate: perDate,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class DoctorAvailabilityService {
  static final DoctorAvailabilityService instance =
      DoctorAvailabilityService._();
  DoctorAvailabilityService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String _slotsCol = 'doctor_availability';
  static const String _requestsCol = 'availability_requests';

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String slotId(String doctorId, String date, String startTime) =>
      '${doctorId}_${date}_${startTime.replaceAll(':', '')}';

  static String oppositeStatus(String s) =>
      s == 'available' ? 'unavailable' : 'available';

  // ---------- Slots ----------

  /// Live slots for one day, sorted by start time.
  Stream<List<DoctorAvailabilitySlot>> slotsStream(
      String doctorId, String date) {
    return _db
        .collection(_slotsCol)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(DoctorAvailabilitySlot.fromDoc).toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// Live slots from today onwards (single-field query, filtered locally so
  /// no composite index is required).
  Stream<List<DoctorAvailabilitySlot>> upcomingSlotsStream(String doctorId) {
    return _db
        .collection(_slotsCol)
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final today = dateKey(DateTime.now());
      final list = snap.docs
          .map(DoctorAvailabilitySlot.fromDoc)
          .where((s) => s.date.compareTo(today) >= 0)
          .toList();
      list.sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.startTime.compareTo(b.startTime);
      });
      return list;
    });
  }

  // ---------- Requests ----------

  Stream<List<AvailabilityRequest>> requestsStream(String doctorId) {
    return _db
        .collection(_requestsCol)
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(AvailabilityRequest.fromDoc).toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  Stream<AvailabilityRequest?> requestStream(String requestId) {
    return _db
        .collection(_requestsCol)
        .doc(requestId)
        .snapshots()
        .map((d) => d.exists ? AvailabilityRequest.fromDoc(d) : null);
  }

  String _newRequestId() {
    final n = 1000 + Random().nextInt(9000);
    return 'REQ-${DateTime.now().year}-$n';
  }

  /// Creates a change request and flags the slot as pending in ONE
  /// transaction. The slot's effective status is NOT changed here - it only
  /// changes when staff approve the request.
  Future<AvailabilityRequest> submitChangeRequest({
    required String doctorId,
    required String doctorName,
    required String hospital,
    required DoctorAvailabilitySlot slot,
    required String requestedStatus,
    required String reason,
  }) async {
    final slotRef = _db.collection(_slotsCol).doc(slot.id);
    final cleanReason = reason.trim();

    for (var attempt = 0; attempt < 5; attempt++) {
      final reqId = _newRequestId();
      final reqRef = _db.collection(_requestsCol).doc(reqId);
      var currentStatus = slot.status;

      try {
        await _db.runTransaction<void>((tx) async {
          final existing = await tx.get(reqRef);
          if (existing.exists) throw Exception('ID_COLLISION');

          final freshSnap = await tx.get(slotRef);
          if (!freshSnap.exists) {
            throw Exception('This time slot no longer exists.');
          }
          final fresh = DoctorAvailabilitySlot.fromDoc(freshSnap);
          if (fresh.hasOpenRequest) {
            throw Exception(
                'A change request for this slot is already pending.');
          }
          if (fresh.status == requestedStatus) {
            throw Exception(
                'This slot is already marked as ${requestedStatus == 'available' ? 'Available' : 'Unavailable'}.');
          }
          currentStatus = fresh.status;

          tx.set(reqRef, <String, dynamic>{
            'doctorId': doctorId,
            'doctorName': doctorName,
            'hospital': hospital,
            'slotId': slot.id,
            'date': slot.date,
            'startTime': slot.startTime,
            'endTime': slot.endTime,
            'currentStatus': fresh.status,
            'requestedStatus': requestedStatus,
            'reason': cleanReason,
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
          });
          tx.update(slotRef, <String, dynamic>{
            'requestStatus': 'pending',
            'requestedStatus': requestedStatus,
            'requestId': reqId,
            'requestedAt': FieldValue.serverTimestamp(),
          });
        });

        return AvailabilityRequest(
          id: reqId,
          doctorId: doctorId,
          doctorName: doctorName,
          hospital: hospital,
          slotId: slot.id,
          date: slot.date,
          startTime: slot.startTime,
          endTime: slot.endTime,
          currentStatus: currentStatus,
          requestedStatus: requestedStatus,
          reason: cleanReason,
          status: 'pending',
          submittedAt: DateTime.now(),
        );
      } catch (e) {
        if (e.toString().contains('ID_COLLISION')) continue; // try a new id
        rethrow;
      }
    }
    throw Exception('Could not create a request ID. Please try again.');
  }

  /// Doctor withdraws a request that is still pending.
  Future<void> cancelRequest(AvailabilityRequest request) async {
    final reqRef = _db.collection(_requestsCol).doc(request.id);
    final slotRef = _db.collection(_slotsCol).doc(request.slotId);

    await _db.runTransaction<void>((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw Exception('This request no longer exists.');
      final current = AvailabilityRequest.fromDoc(reqSnap);
      if (!current.isPending) {
        throw Exception('Only pending requests can be cancelled.');
      }
      final slotSnap = await tx.get(slotRef);

      tx.update(reqRef, <String, dynamic>{
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      if (slotSnap.exists) {
        final slot = DoctorAvailabilitySlot.fromDoc(slotSnap);
        if (slot.requestId == request.id) {
          tx.update(slotRef, <String, dynamic>{
            'requestStatus': 'none',
            'requestedStatus': FieldValue.delete(),
            'requestId': FieldValue.delete(),
          });
        }
      }
    });
  }

  /// FOR THE HOSPITAL-STAFF SIDE: approve or reject a pending request.
  /// Approving also applies the requested status to the slot.
  Future<void> resolveRequest({
    required String requestId,
    required bool approve,
    String? reviewerName,
    String? note,
  }) async {
    final reqRef = _db.collection(_requestsCol).doc(requestId);

    await _db.runTransaction<void>((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw Exception('Request not found.');
      final req = AvailabilityRequest.fromDoc(reqSnap);
      if (!req.isPending) throw Exception('Request is already ${req.status}.');
      final slotRef = _db.collection(_slotsCol).doc(req.slotId);
      final slotSnap = await tx.get(slotRef);

      tx.update(reqRef, <String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        if (reviewerName != null) 'reviewedBy': reviewerName,
        if (note != null && note.trim().isNotEmpty)
          'reviewerNote': note.trim(),
      });
      if (slotSnap.exists) {
        tx.update(slotRef, <String, dynamic>{
          'requestStatus': approve ? 'approved' : 'rejected',
          if (approve) 'status': req.requestedStatus,
        });
      }
    });
  }

  // ---------- Demo data ----------

  static const List<List<String>> _template = <List<String>>[
    ['09:00', '10:00'],
    ['10:00', '11:00'],
    ['11:00', '12:00'],
    ['13:00', '14:00'],
    ['14:00', '15:00'],
    ['15:00', '16:00'],
  ];
  static const List<int> _slotsPerDay = <int>[6, 4, 5, 6, 4, 5, 6];

  Future<String> _uniqueRequestId() async {
    for (var i = 0; i < 8; i++) {
      final id = _newRequestId();
      final snap = await _db.collection(_requestsCol).doc(id).get();
      if (!snap.exists) return id;
    }
    return '${_newRequestId()}${Random().nextInt(9)}';
  }

  /// Makes sure the next 7 days have slots. The first run for a doctor also
  /// creates three sample requests (pending / approved / rejected) so the
  /// request screens have something to show. Safe to call on every launch.
  Future<void> seedIfNeeded({
    required String doctorId,
    required String doctorName,
    required String hospital,
  }) async {
    try {
      final existing = await _db
          .collection(_slotsCol)
          .where('doctorId', isEqualTo: doctorId)
          .get();
      final knownDates = <String>{
        for (final d in existing.docs) _s(d.data()['date'], ''),
      };
      final firstRun = existing.docs.isEmpty;

      final today = DateTime.now();
      final batch = _db.batch();
      var writes = 0;

      String? pendingId, approvedId, rejectedId;
      if (firstRun) {
        pendingId = await _uniqueRequestId();
        approvedId = await _uniqueRequestId();
        while (approvedId == pendingId) {
          approvedId = await _uniqueRequestId();
        }
        rejectedId = await _uniqueRequestId();
        while (rejectedId == pendingId || rejectedId == approvedId) {
          rejectedId = await _uniqueRequestId();
        }
      }

      for (var day = 0; day < _slotsPerDay.length; day++) {
        final date = dateKey(today.add(Duration(days: day)));
        if (knownDates.contains(date)) continue;

        for (var i = 0; i < _slotsPerDay[day]; i++) {
          final start = _template[i][0];
          final end = _template[i][1];
          final data = <String, dynamic>{
            'doctorId': doctorId,
            'date': date,
            'startTime': start,
            'endTime': end,
            'status': 'available',
            'requestStatus': 'none',
          };

          // Day 0 mirrors the design: one unavailable slot and one slot in
          // each request state.
          if (day == 0 && firstRun) {
            if (i == 2) data['status'] = 'unavailable';
            if (i == 3) {
              data['requestStatus'] = 'pending';
              data['requestedStatus'] = 'unavailable';
              data['requestId'] = pendingId;
            }
            if (i == 4) {
              data['requestStatus'] = 'approved';
              data['requestedStatus'] = 'available';
              data['requestId'] = approvedId;
            }
            if (i == 5) {
              data['requestStatus'] = 'rejected';
              data['requestedStatus'] = 'unavailable';
              data['requestId'] = rejectedId;
            }
          }

          batch.set(
            _db.collection(_slotsCol).doc(slotId(doctorId, date, start)),
            data,
            SetOptions(merge: true),
          );
          writes++;
        }
      }

      if (firstRun) {
        final todayKey = dateKey(today);
        void addRequest(String id, int slotIndex, String current,
            String requested, String status, String reason,
            {String? note}) {
          final start = _template[slotIndex][0];
          batch.set(_db.collection(_requestsCol).doc(id), <String, dynamic>{
            'doctorId': doctorId,
            'doctorName': doctorName,
            'hospital': hospital,
            'slotId': slotId(doctorId, todayKey, start),
            'date': todayKey,
            'startTime': start,
            'endTime': _template[slotIndex][1],
            'currentStatus': current,
            'requestedStatus': requested,
            'reason': reason,
            'status': status,
            'submittedAt': FieldValue.serverTimestamp(),
            if (status != 'pending') 'reviewedAt': FieldValue.serverTimestamp(),
            if (status != 'pending') 'reviewedBy': 'Hospital Administration',
            if (note != null) 'reviewerNote': note,
          });
          writes++;
        }

        addRequest(pendingId!, 3, 'available', 'unavailable', 'pending',
            'Attending a medical conference');
        addRequest(approvedId!, 4, 'unavailable', 'available', 'approved',
            'Conference cancelled, back in clinic');
        addRequest(rejectedId!, 5, 'available', 'unavailable', 'rejected',
            'Personal appointment',
            note: 'Clinic is fully booked for this slot.');
      }

      if (writes > 0) await batch.commit();
    } catch (e) {
      debugPrint('DoctorAvailabilityService seed note: $e');
    }
  }
}
