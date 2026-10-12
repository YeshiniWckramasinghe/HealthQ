import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'check_in_screen.dart';
import 'queue_backend_service.dart';

// ============================================================================
// QUEUE PATIENT MODEL
// ============================================================================

class QueuePatient {
  final String queueNumber;
  final String patientName;
  final String doctorName;
  final String status;

  const QueuePatient({
    required this.queueNumber,
    required this.patientName,
    required this.doctorName,
    this.status = 'Waiting',
  });
}

// ============================================================================
// QUEUE NOTIFICATION EVENT
// ============================================================================

class QueueNotificationEvent {
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
  final DateTime time;

  QueueNotificationEvent({
    required this.title,
    required this.body,
    required this.icon,
    required this.iconColor,
  }) : time = DateTime.now();
}

// Global notification bus.
class QueueNotificationCenter {
  static final ValueNotifier<List<QueueNotificationEvent>>
      notifications =
      ValueNotifier<List<QueueNotificationEvent>>([]);

  static void add({
    required String title,
    required String body,
    required IconData icon,
    required Color iconColor,
  }) {
    final updated = [
      QueueNotificationEvent(
        title: title,
        body: body,
        icon: icon,
        iconColor: iconColor,
      ),
      ...notifications.value,
    ];

    notifications.value = updated;
  }
}

// ============================================================================
// BOTTOM NAVIGATION BRIDGE
// ============================================================================

class QueueNavigationCenter {
  static final ValueNotifier<int?> requestedTab =
      ValueNotifier<int?>(null);

  static void goToTab(
    BuildContext context,
    int index,
  ) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    requestedTab.value = null;
    requestedTab.value = index;
  }
}

// ============================================================================
// SHARED QUEUE BOTTOM BAR
// ============================================================================

class QueueBottomBar extends StatelessWidget {
  final int selectedIndex;
  const QueueBottomBar({super.key, this.selectedIndex = -1});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE1E9E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            label: 'Appointments',
            index: 1,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.notifications_none_rounded,
            selectedIcon: Icons.notifications_rounded,
            label: 'Notifications',
            index: 2,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final selected = selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          QueueNavigationCenter.goToTab(context, index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 22,
              color: selected
                  ? const Color(0xFF007471)
                  : const Color(0xFF789090),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF007471)
                    : const Color(0xFF789090),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED SCREEN LAYOUT
//
// Every queue screen uses the same rule, like the Home screen:
// full width on phones, centred and capped on tablets / web / desktop.
// The bottom navigation always spans the full width.
// ============================================================================

class QueueLayout {
  // Same cap the Check-In screen uses, so the whole flow lines up.
  static const double maxContentWidth = 480;

  static double contentWidth(double screenWidth) {
    return math.min(screenWidth, maxContentWidth);
  }

  static Widget body({
    required double screenWidth,
    required Widget content,
    required Widget bottomNavigation,
  }) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: contentWidth(screenWidth),
              child: content,
            ),
          ),
        ),
        bottomNavigation,
      ],
    );
  }
}

// ============================================================================
// QUEUE STATUS SCREEN
// ============================================================================

class QueueStatusScreen extends StatefulWidget {
  final String? appointmentId;
  final CheckInAppointment? initialAppointment;

  const QueueStatusScreen({
    super.key,
    this.appointmentId,
    this.initialAppointment,
  });

  @override
  State<QueueStatusScreen> createState() =>
      _QueueStatusScreenState();
}

class _QueueStatusScreenState
    extends State<QueueStatusScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _queueSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _appointmentsSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  String? _appointmentId;
  String? _hospital;
  String? _doctorName;
  String? _date;
  String? _session;
  String? _patientName;
  String? _nic;

  int _yourQueueNumber = 0;

  // Holds appointment if user has not yet checked in
  DocumentSnapshot<Map<String, dynamic>>? _notCheckedInDoc;

  List<QueuePatient> _patients = [];

  final int _averageMinutesPerPatient = 5;

  @override
  void initState() {
    super.initState();
    if (widget.initialAppointment != null) {
      _applyInitialAppointment(widget.initialAppointment!);
    }
    _loadQueueData();
  }

  void _applyInitialAppointment(CheckInAppointment a) {
    _appointmentId = a.appointmentId;
    _hospital = a.hospital;
    _doctorName = a.doctor;
    _date = a.date;
    _session = a.session;
    _patientName = a.patient;
    _nic = a.nic;
    _yourQueueNumber = int.tryParse(a.estimatedQueueNumber) ?? 0;
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================================
  // LOAD USER'S APPOINTMENT (CHECKED IN OR CONFIRMED)
  // ==========================================================================

  Future<void> _loadQueueData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _notCheckedInDoc = null;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please log in before viewing your queue.',
        );
      }

      DocumentSnapshot<Map<String, dynamic>>? appointmentDoc;

      // 1. Direct lookup by appointmentId
      final targetId = widget.appointmentId ?? _appointmentId;
      if (targetId != null && targetId.isNotEmpty) {
        final directSnap = await _firestore
            .collection('appointments')
            .doc(targetId)
            .get();
        if (directSnap.exists) {
          appointmentDoc = directSnap;
        }
      }

      // 2. Query by authUid / userUid / userId / nic
      if (appointmentDoc == null) {
        var snaps = await _firestore
            .collection('appointments')
            .where('authUid', isEqualTo: user.uid)
            .get();

        if (snaps.docs.isEmpty) {
          snaps = await _firestore
              .collection('appointments')
              .where('userUid', isEqualTo: user.uid)
              .get();
        }

        if (snaps.docs.isEmpty) {
          snaps = await _firestore
              .collection('appointments')
              .where('userId', isEqualTo: user.uid)
              .get();
        }

        if (snaps.docs.isEmpty) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .get();
            final nic = (userDoc.data()?['nic'] ??
                    userDoc.data()?['userId'] ??
                    '')
                .toString()
                .trim();
            if (nic.isNotEmpty) {
              snaps = await _firestore
                  .collection('appointments')
                  .where('nic', isEqualTo: nic)
                  .get();

              if (snaps.docs.isEmpty) {
                snaps = await _firestore
                    .collection('appointments')
                    .where('userId', isEqualTo: nic)
                    .get();
              }
            }
          } catch (_) {}
        }

        if (snaps.docs.isNotEmpty) {
          // Priority 1: checked in & waiting
          QueryDocumentSnapshot<Map<String, dynamic>>? bestDoc;
          for (final doc in snaps.docs) {
            final d = doc.data();
            if (d['checkedIn'] == true &&
                (d['queueStatus'] ?? '').toString().toLowerCase() == 'waiting') {
              bestDoc = doc;
              break;
            }
          }

          // Priority 2: any checked in
          bestDoc ??= snaps.docs
              .where((d) => d.data()['checkedIn'] == true)
              .firstOrNull;

          // Priority 3: confirmed or upcoming
          bestDoc ??= snaps.docs.where((d) {
            final s = (d.data()['status'] ?? '').toString().toLowerCase();
            return s == 'confirmed' || s == 'upcoming';
          }).firstOrNull;

          // Priority 4: first matching doc
          bestDoc ??= snaps.docs.first;

          appointmentDoc = bestDoc;
        }
      }

      if (appointmentDoc == null) {
        throw Exception(
          'No active appointment was found.',
        );
      }

      final data = appointmentDoc.data() ?? {};

      _appointmentId = appointmentDoc.id;

      _hospital =
          data['hospitalName']?.toString() ??
              data['hospital']?.toString() ?? '';

      _doctorName =
          data['doctorName']?.toString() ??
              data['doctor']?.toString() ?? '';

      _date =
          data['date']?.toString() ?? '';

      _session =
          data['session']?.toString() ?? '';

      _patientName =
          data['patientName']?.toString() ?? '';

      _nic =
          data['nic']?.toString() ?? '';

      final queueNumberValue =
          data['queueNumber'] ?? data['queueNo'];

      _yourQueueNumber =
          _readQueueNumber(queueNumberValue);

      final isCheckedIn = (data['checkedIn'] == true);

      // If appointment is confirmed/pending but user has not checked in yet:
      if (!isCheckedIn) {
        if (!mounted) return;
        setState(() {
          _notCheckedInDoc = appointmentDoc;
          _isLoading = false;
        });
        return;
      }

      // Start real-time queue listener across collections.
      _listenToQueues();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            _friendlyErrorMessage(e);
      });
    }
  }

  // ==========================================================================
  // LISTEN TO FIRESTORE QUEUES & APPOINTMENTS
  // ==========================================================================

  void _listenToQueues() {
    _queueSubscription?.cancel();
    _appointmentsSubscription?.cancel();

    QuerySnapshot<Map<String, dynamic>>? latestQueues;
    QuerySnapshot<Map<String, dynamic>>? latestAppts;

    void updateCombinedQueue() {
      if (!mounted) return;

      final Map<int, QueuePatient> patientMap = {};

      // 1. From queues collection
      if (latestQueues != null) {
        for (final doc in latestQueues!.docs) {
          final data = doc.data();

          final hospital =
              data['hospital']?.toString();

          final doctorName =
              data['doctorName']?.toString();

          final session =
              data['session']?.toString();

          final sameHospital =
              hospital == _hospital;

          final sameDoctor =
              doctorName == _doctorName;

          final sameDate =
              _isSameDate(data['date']);

          final sameSession =
              session == _session;

          if (!sameHospital ||
              !sameDoctor ||
              !sameDate ||
              !sameSession) {
            continue;
          }

          final queueNumber =
              _readQueueNumber(
            data['queueNumber'],
          );

          if (queueNumber <= 0) {
            continue;
          }

          patientMap[queueNumber] = QueuePatient(
            queueNumber:
                queueNumber.toString().padLeft(2, '0'),
            patientName:
                data['patientName']?.toString() ??
                    'Patient $queueNumber',
            doctorName:
                doctorName ?? _doctorName ?? '',
            status:
                data['status']?.toString() ??
                    'Waiting',
          );
        }
      }

      // 2. From appointments collection
      if (latestAppts != null) {
        for (final doc in latestAppts!.docs) {
          final data = doc.data();

          final hospital = (data['hospitalName'] ?? data['hospital'] ?? '').toString();
          final doctorName = (data['doctorName'] ?? data['doctor'] ?? '').toString();
          final session = (data['session'] ?? '').toString();
          final status = (data['status'] ?? '').toString().toLowerCase();

          if (status == 'cancelled' || status == 'rejected') continue;

          final sameHospital = hospital == _hospital;
          final sameDoctor = doctorName == _doctorName;
          final sameDate = _isSameDate(data['date']);
          final sameSession = session == _session;

          if (!sameHospital || !sameDoctor || !sameDate || !sameSession) {
            continue;
          }

          final queueNumber = _readQueueNumber(data['queueNo'] ?? data['queueNumber']);
          if (queueNumber <= 0) continue;

          final isChecked = (data['checkedIn'] == true);
          final rawQueueStatus = (data['queueStatus'] ?? (isChecked ? 'Waiting' : 'Booked')).toString();

          if (!patientMap.containsKey(queueNumber) || isChecked) {
            patientMap[queueNumber] = QueuePatient(
              queueNumber: queueNumber.toString().padLeft(2, '0'),
              patientName: data['patientName']?.toString() ?? 'Patient $queueNumber',
              doctorName: doctorName.isNotEmpty ? doctorName : (_doctorName ?? ''),
              status: rawQueueStatus,
            );
          }
        }
      }

      // Ensure current user's number is present
      if (_yourQueueNumber > 0 && !patientMap.containsKey(_yourQueueNumber)) {
        patientMap[_yourQueueNumber] = QueuePatient(
          queueNumber:
              _yourQueueNumber.toString().padLeft(2, '0'),
          patientName:
              _patientName?.isNotEmpty == true ? _patientName! : 'You',
          doctorName:
              _doctorName ?? '',
          status: 'Waiting',
        );
      }

      final loadedPatients = patientMap.values.toList()
        ..sort(
          (a, b) {
            final aNumber =
                int.tryParse(a.queueNumber) ?? 0;

            final bNumber =
                int.tryParse(b.queueNumber) ?? 0;

            return aNumber.compareTo(bNumber);
          },
        );

      setState(() {
        _patients = loadedPatients;
        _isLoading = false;
        _errorMessage = null;
      });
    }

    _queueSubscription = _firestore
        .collection('queues')
        .snapshots()
        .listen(
      (snapshot) {
        latestQueues = snapshot;
        updateCombinedQueue();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      },
    );

    _appointmentsSubscription = _firestore
        .collection('appointments')
        .snapshots()
        .listen(
      (snapshot) {
        latestAppts = snapshot;
        updateCombinedQueue();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  // ==========================================================================
  // DATE MATCHING
  // ==========================================================================

  bool _isSameDate(dynamic queueDate) {
    if (queueDate == null || _date == null) {
      return false;
    }

    final queueDateText =
        queueDate.toString().trim();

    final appointmentDate =
        _date!.trim();

    // Direct match.
    if (queueDateText == appointmentDate) {
      return true;
    }

    // Convert appointment format:
    // 2026-10-09 -> 09 Oct 2026
    try {
      final parts =
          appointmentDate.split('-');

      if (parts.length == 3) {
        final year =
            int.parse(parts[0]);

        final month =
            int.parse(parts[1]);

        final day =
            int.parse(parts[2]);

        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        if (month >= 1 &&
            month <= 12) {
          final formatted =
              '$day ${months[month - 1]} $year';

          // Firestore queue docs may use "09 Oct 2026" (zero padded).
          final paddedFormatted =
              '${day.toString().padLeft(2, '0')} ${months[month - 1]} $year';

          if (queueDateText ==
                  formatted ||
              queueDateText ==
                  paddedFormatted) {
            return true;
          }
        }
      }
    } catch (_) {
      // Ignore parsing errors.
    }

    return false;
  }

  // ==========================================================================
  // QUEUE NUMBER READER
  // ==========================================================================

  int _readQueueNumber(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // ==========================================================================
  // ERROR MESSAGE
  // ==========================================================================

  String _friendlyErrorMessage(Object error) {
    final message =
        error.toString();

    if (message.contains(
      'No checked-in appointment',
    )) {
      return 'No checked-in appointment was found.';
    }

    if (message.contains(
      'Please log in',
    )) {
      return 'Please log in to view your queue.';
    }

    return message
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // ==========================================================================
  // CURRENTLY SERVING
  // ==========================================================================

  QueuePatient get _currentlyServing {
    if (_patients.isEmpty) {
      return QueuePatient(
        queueNumber: '01',
        patientName: 'No Patient',
        doctorName:
            _doctorName ?? '',
        status: 'In Consult',
      );
    }

    // First priority:
    // queue member marked as In Consult.
    for (final patient in _patients) {
      if (patient.status
          .toLowerCase()
          .contains('consult')) {
        return patient;
      }
    }

    // Second priority:
    // first patient that is not completed.
    for (final patient in _patients) {
      if (!QueueBackend.isFinished(
        patient.status,
      )) {
        return patient;
      }
    }

    return _patients.first;
  }

  // ==========================================================================
  // PATIENTS AHEAD
  // ==========================================================================

  int get _patientsAhead {
    if (_yourQueueNumber <= 0) {
      return 0;
    }

    int count = 0;

    for (final patient in _patients) {
      final number =
          int.tryParse(
        patient.queueNumber,
      );

      if (number != null &&
          number < _yourQueueNumber &&
          !QueueBackend.isFinished(
            patient.status,
          )) {
        count++;
      }
    }

    return count;
  }

  // ==========================================================================
  // ESTIMATED WAIT
  // ==========================================================================

  int get _estimatedWaitingMinutes {
    if (_patientsAhead <= 0) {
      return 1;
    }

    return math.max(
      1,
      _patientsAhead *
          _averageMinutesPerPatient,
    );
  }

  // ==========================================================================
  // QUEUE TEXT
  // ==========================================================================

  String get _yourQueueText {
    return _yourQueueNumber
        .toString()
        .padLeft(2, '0');
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            return QueueLayout.body(
              screenWidth: width,
              content: _buildBody(width),
              bottomNavigation: _buildBottomNavigation(width),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================

  Widget _buildBody(double width) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00827D),
        ),
      );
    }

    if (_notCheckedInDoc != null) {
      return _buildCheckInRequiredView(width);
    }

    if (_errorMessage != null) {
      return _buildErrorState(width);
    }

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          4,
          0,
          width < 600 ? 14 : 24,
        ),
        child: _buildMainContent(width),
      ),
    );
  }

  // ==========================================================================
  // CHECK-IN REQUIRED VIEW
  // ==========================================================================

  Widget _buildCheckInRequiredView(double width) {
    final compact = width < 380;
    final data = _notCheckedInDoc?.data() ?? {};
    final hosp = _hospital?.isNotEmpty == true ? _hospital! : 'Hospital';
    final doc = _doctorName?.isNotEmpty == true ? _doctorName! : 'Doctor';
    final dLabel = data['dateLabel']?.toString() ?? _date ?? '';
    final sess = _session ?? '';
    final qNo = _yourQueueNumber.toString().padLeft(2, '0');
    final isPending = (data['status']?.toString().toLowerCase() == 'pending');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: compact ? 40 : 42,
                    height: compact ? 40 : 42,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF063E3E),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.hourglass_top_rounded : Icons.how_to_reg_rounded,
                size: 38,
                color: isPending ? const Color(0xFFD97706) : const Color(0xFF00827D),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isPending ? 'Appointment Pending OPD Confirmation' : 'Check-In Required for Live Queue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 17 : 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF063E3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Your appointment has been submitted and is awaiting OPD confirmation. Once confirmed, you can check in to join the live waiting queue.'
                  : 'Please check in when you arrive at the hospital to enter the live queue and track your waiting time in real time.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5A7272),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD6E5E5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reserved Queue Token',
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          color: const Color(0xFF789090),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00827D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$qNo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildSummaryRow('Hospital', hosp),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Doctor', doc),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Date & Session', '$dLabel · $sess'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Patient', _patientName?.isNotEmpty == true ? _patientName! : 'You'),
                  if (_nic != null && _nic!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow('NIC / User ID', _nic!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final checkInAppt = CheckInAppointment(
                    appointmentId: _appointmentId ?? '',
                    nic: _nic ?? '',
                    hospital: hosp,
                    date: dLabel,
                    session: sess,
                    doctor: doc,
                    speciality: data['speciality']?.toString() ?? '',
                    patient: _patientName ?? '',
                    contact: data['contact']?.toString() ?? '',
                    estimatedQueueNumber: _yourQueueNumber.toString(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckInScreen(
                        bookedAppointment: checkInAppt,
                        onCheckIn: (confirmed) {
                          _applyInitialAppointment(confirmed);
                          _loadQueueData();
                        },
                      ),
                    ),
                  ).then((_) => _loadQueueData());
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  isPending ? 'Proceed to Check In' : 'Check In to Live Queue',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00827D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00827D),
                  side: const BorderSide(color: Color(0xFF00827D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF789090)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF063E3E),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ERROR STATE
  // ==========================================================================

  Widget _buildErrorState(double width) {
    final compact =
        width < 380;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .queue_play_next_rounded,
              size: 54,
              color:
                  Color(0xFF00827D),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              _errorMessage ??
                  'Unable to load queue.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize:
                    compact ? 14 : 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    const Color(
                  0xFF063E3E,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckInScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00827D),
                    side: const BorderSide(color: Color(0xFF00827D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Check In with NIC'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loadQueueData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00827D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MAIN CONTENT
  // ==========================================================================

  Widget _buildMainContent(
    double width,
  ) {
    final compact =
        width < 380;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          height:
              compact ? 8 : 12,
        ),

        _buildTitle(compact),

        SizedBox(
          height:
              compact ? 12 : 16,
        ),

        _buildCurrentlyServingCard(
          compact,
        ),

        SizedBox(
          height:
              compact ? 32 : 42,
        ),

        _buildSignalIcon(),

        SizedBox(
          height:
              compact ? 8 : 10,
        ),

        _buildYourNumberSection(
          compact,
        ),

        SizedBox(
          height:
              compact ? 32 : 40,
        ),

        _buildCurrentQueueTitle(
          compact,
        ),

        SizedBox(
          height:
              compact ? 12 : 14,
        ),

        _buildQueueScroller(
          compact,
        ),

        SizedBox(
          height:
              compact ? 18 : 20,
        ),

        _buildQueueInformation(
          compact,
        ),

        SizedBox(
          height:
              compact ? 22 : 30,
        ),

        _buildNextButton(
          compact,
        ),
      ],
    );
  }

  // ==========================================================================
  // TITLE
  // ==========================================================================

  Widget _buildTitle(
    bool compact,
  ) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape:
              const CircleBorder(),
          child: InkWell(
            customBorder:
                const CircleBorder(),
            onTap: () {
              Navigator.of(
                context,
              ).pop();
            },
            child: SizedBox(
              width:
                  compact ? 40 : 42,
              height:
                  compact ? 40 : 42,
              child: const Icon(
                Icons
                    .arrow_back_rounded,
                color:
                    Color(0xFF063E3E),
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          'Queue Status',
          style: TextStyle(
            fontSize:
                compact ? 22 : 25,
            fontWeight:
                FontWeight.w800,
            color:
                const Color(
              0xFF063E3E,
            ),
            letterSpacing:
                -0.5,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CURRENTLY SERVING CARD
  // ==========================================================================

  Widget _buildCurrentlyServingCard(bool compact) {
    final serving = _currentlyServing;
    final doctor = _doctorName?.isNotEmpty == true
        ? _doctorName!
        : (serving.doctorName.isNotEmpty ? serving.doctorName : 'Dr. R. Fernando');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 13 : 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF007471),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENTLY SERVING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'T-${serving.queueNumber}',
                  style: TextStyle(
                    color: const Color(0xFF007471),
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'In Consult',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SIGNAL ICON
  // ==========================================================================

  Widget _buildSignalIcon() {
    return Center(
      child: SizedBox(
        height: 42,
        width: 42,
        child: CustomPaint(
          painter:
              _QueueSignalPainter(),
        ),
      ),
    );
  }

  // ==========================================================================
  // YOUR NUMBER
  // ==========================================================================

  Widget _buildYourNumberSection(
    bool compact,
  ) {
    return Column(
      children: [
        Center(
          child: Text(
            'Your Number',
            style: TextStyle(
              fontSize:
                  compact ? 21 : 23,
              fontWeight:
                  FontWeight.w800,
              color:
                  const Color(
                0xFF063E3E,
              ),
            ),
          ),
        ),
        SizedBox(
          height:
              compact ? 2 : 4,
        ),
        Center(
          child: FittedBox(
            fit:
                BoxFit.scaleDown,
            child: Text(
              '#$_yourQueueText',
              style: TextStyle(
                fontSize:
                    compact ? 54 : 60,
                height: 1,
                fontWeight:
                    FontWeight.w900,
                color:
                    const Color(
                  0xFF00827D,
                ),
                letterSpacing:
                    -2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CURRENT QUEUE TITLE
  // ==========================================================================

  Widget _buildCurrentQueueTitle(
    bool compact,
  ) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Current Queue',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF007471),
        ),
      ),
    );
  }

  // ==========================================================================
  // QUEUE SCROLLER
  // ==========================================================================

  Widget _buildQueueScroller(
    bool compact,
  ) {
    return SizedBox(
      height:
          compact ? 56 : 60,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _patients.length,
        separatorBuilder:
            (_, _) =>
                const SizedBox(
          width: 10,
        ),
        itemBuilder:
            (context, index) {
          final patient =
              _patients[index];

          final isCurrentlyServing =
              patient.queueNumber ==
                  _currentlyServing
                      .queueNumber;

          return _buildQueueNumberBox(
            patient.queueNumber,
            isCurrentlyServing,
            compact,
          );
        },
      ),
    );
  }

  Widget _buildQueueNumberBox(
    String number,
    bool isSelected,
    bool compact,
  ) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      width:
          compact ? 54 : 56,
      height:
          compact ? 54 : 56,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color: isSelected
            ? const Color(
                0xFF00827D,
              )
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
        border:
            Border.all(
          color: isSelected
              ? const Color(0xFF00827D)
              : const Color(0xFFD6E5E5),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color:
                      const Color(
                    0xFF00827D,
                  ).withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 8,
                  offset:
                      const Offset(
                    0,
                    3,
                  ),
                ),
              ]
            : null,
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize:
              compact ? 19 : 20,
          fontWeight: isSelected
              ? FontWeight.w900
              : FontWeight.w600,
          color: isSelected
              ? Colors.white
              : const Color(
                  0xFF063E3E,
                ),
        ),
      ),
    );
  }

  // ==========================================================================
  // QUEUE INFORMATION
  // ==========================================================================

  Widget _buildQueueInformation(
    bool compact,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Est. Wait: $_estimatedWaitingMinutes mins',
            style: const TextStyle(
              color: Color(0xFF789090),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${_patientsAhead.toString().padLeft(2, '0')} Patient Ahead',
            style: const TextStyle(
              color: Color(0xFF789090),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // NEXT BUTTON
  // ==========================================================================

  Widget _buildNextButton(
    bool compact,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed:
              _openEstimatedWaitingTime,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(
              0xFF00827D,
            ),
            foregroundColor:
                Colors.white,
            elevation: 0,
            shape:
                const StadiumBorder(),
          ),
          child: const Text(
            'Next',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _openEstimatedWaitingTime() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EstimatedWaitingTimeScreen(
          yourQueueNumber:
              _yourQueueNumber,
          averageMinutesPerPatient:
              _averageMinutesPerPatient,
          patientsAhead:
              _patientsAhead,
          patients:
              _patients,
          appointmentId:
              _appointmentId,
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

  Widget _buildBottomNavigation(
    double width,
  ) {
    return const QueueBottomBar(selectedIndex: -1);
  }
}

// ============================================================================
// ESTIMATED WAITING TIME SCREEN
// ============================================================================

class EstimatedWaitingTimeScreen
    extends StatefulWidget {
  const EstimatedWaitingTimeScreen({
    super.key,
    required this.yourQueueNumber,
    required this.averageMinutesPerPatient,
    required this.patientsAhead,
    required this.patients,
    this.appointmentId,
  });

  final int yourQueueNumber;
  final int averageMinutesPerPatient;
  final int patientsAhead;
  final List<QueuePatient> patients;
  final String? appointmentId;

  @override
  State<EstimatedWaitingTimeScreen>
      createState() =>
          _EstimatedWaitingTimeScreenState();
}

class _EstimatedWaitingTimeScreenState
    extends State<
        EstimatedWaitingTimeScreen> {
  Timer? _timer;
  QueueLiveWatcher? _watcher;
  bool _turnOpened = false;

  late int _initialSeconds;
  late int _remainingSeconds;

  // Live values (start from what the previous screen passed in,
  // then follow Firestore).
  late int _yourQueueNumber;
  late int _patientsAhead;
  late int _averageMinutes;
  late List<QueuePatient> _patients;

  @override
  void initState() {
    super.initState();

    _yourQueueNumber = widget.yourQueueNumber;
    _patientsAhead = widget.patientsAhead;
    _averageMinutes = widget.averageMinutesPerPatient;
    _patients = widget.patients;

    final calculatedMinutes =
        math.max(
      1,
      _patientsAhead *
          _averageMinutes,
    );

    _initialSeconds =
        calculatedMinutes * 60;

    _remainingSeconds =
        _initialSeconds;

    _startCountdown();
    _startLiveListener();
  }

  // Follows the queue in Firestore. Patients ahead / waiting time update
  // by themselves; when it becomes this patient's turn we open MyTurnScreen.
  void _startLiveListener() {
    final appointmentId = widget.appointmentId;

    if (appointmentId == null || appointmentId.isEmpty) {
      return;
    }

    _watcher = QueueLiveWatcher(
      appointmentId: appointmentId,
      onData: (data) {
        if (!mounted || _turnOpened) {
          return;
        }

        final changed =
            data.patientsAhead != _patientsAhead ||
                data.averageMinutesPerPatient != _averageMinutes;

        setState(() {
          _yourQueueNumber = data.yourQueueNumber;
          _patients = data.patients;
          _patientsAhead = data.patientsAhead;
          _averageMinutes = data.averageMinutesPerPatient;

          if (changed) {
            _initialSeconds = data.estimatedMinutes * 60;
            _remainingSeconds = _initialSeconds;
          }
        });

        if (changed && !(_timer?.isActive ?? false)) {
          _startCountdown();
        }

        if (data.isMyTurn) {
          _openMyTurn();
        }
      },
      onError: (_) {},
    )..start();
  }

  void _startCountdown() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (_remainingSeconds <=
            1) {
          _timer?.cancel();

          setState(() {
            _remainingSeconds =
                0;
          });

          // With a backend connection the live queue decides when it is
          // the patient's turn, not the local countdown.
          if (widget.appointmentId == null) {
            _openMyTurn();
          }
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watcher?.dispose();
    super.dispose();
  }

  int get _remainingMinutes {
    return (_remainingSeconds / 60)
        .ceil();
  }

  int get _displayMinutes {
    return math.max(
      0,
      _remainingMinutes,
    );
  }

  double get _progress {
    if (_initialSeconds <= 0) {
      return 0;
    }

    return (_remainingSeconds /
            _initialSeconds)
        .clamp(0.0, 1.0);
  }

  void _openMyTurn() {
    if (!mounted || _turnOpened) {
      return;
    }

    _turnOpened = true;
    _timer?.cancel();
    _watcher?.dispose();

    final appointmentId = widget.appointmentId;

    if (appointmentId != null && appointmentId.isNotEmpty) {
      QueueBackend.notifyYourTurn(appointmentId).catchError((e) {
        debugPrint('notifyYourTurn failed: $e');
      });
    }

    QueueNotificationCenter.add(
      title: 'It\'s Your Turn',
      body:
          'Your queue number $_yourQueueNumber is now ready. Please proceed to the consultation room.',
      icon:
          Icons.notifications_active,
      iconColor:
          const Color(0xFF00827D),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MyTurnScreen(
          yourQueueNumber:
              _yourQueueNumber,
          patients:
              _patients,
          appointmentId:
              widget.appointmentId,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            return QueueLayout.body(
              screenWidth: width,
              content: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildEstimatedContent(
                          width,
                        ),
                      ),
              bottomNavigation: _buildBottomNavigation(width),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstimatedContent(
    double width,
  ) {
    final compact =
        width < 380;

    final estimatedWait = math.max(
      1,
      _patientsAhead * _averageMinutes,
    );

    return Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            compact ? 14 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height:
                compact ? 8 : 12,
          ),
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: compact ? 40 : 42,
                    height: compact ? 40 : 42,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF063E3E),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Queue Status',
                style: TextStyle(
                  fontSize: compact ? 22 : 25,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF063E3E),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                compact ? 24 : 32,
          ),
          Center(
            child:
                _buildCountdownCircle(
              compact,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Column(
              children: [
                const Text(
                  'AVG Time Per Patient',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF789090),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_averageMinutes min',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF063E3E),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                compact ? 24 : 28,
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF007471),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _buildQueueStrip(
            compact,
          ),
          SizedBox(
            height:
                compact ? 12 : 14,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Wait: $estimatedWait mins',
                  style: const TextStyle(
                    color: Color(0xFF789090),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_patientsAhead.toString().padLeft(2, '0')} Patient Ahead',
                  style: const TextStyle(
                    color: Color(0xFF789090),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                compact ? 24 : 28,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _openMyTurn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007471),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height:
                compact ? 16 : 22,
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCircle(
    bool compact,
  ) {
    final circleSize =
        compact ? 150.0 : 170.0;

    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: CustomPaint(
        painter:
            _WaitingTimePainter(
          progress:
              _progress,
        ),
        child: Center(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                '$_displayMinutes mins',
                style:
                    TextStyle(
                  fontSize:
                      compact ? 25 : 27,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      const Color(
                    0xFF00827D,
                  ),
                ),
              ),
              Text(
                'left',
                style:
                    TextStyle(
                  fontSize:
                      compact ? 16 : 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      const Color(
                    0xFF00827D,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueStrip(
    bool compact,
  ) {
    return SizedBox(
      height:
          compact ? 56 : 58,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _patients.length,
        separatorBuilder:
            (_, _) =>
                const SizedBox(
          width: 10,
        ),
        itemBuilder:
            (context, index) {
          final patient =
              _patients[index];

          final number =
              int.tryParse(
            patient.queueNumber,
          );

          final selected =
              number ==
                  widget
                      .yourQueueNumber;

          return Container(
            width:
                compact ? 50 : 52,
            height:
                compact ? 50 : 52,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border:
                  Border.all(
                color: selected
                    ? const Color(0xFF00827D)
                    : const Color(0xFFD6E5E5),
                width: 1.5,
              ),
            ),
            child: Text(
              patient.queueNumber,
              style: TextStyle(
                fontSize:
                    compact ? 18 : 19,
                fontWeight:
                    selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(
                        0xFF063E3E,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    return const QueueBottomBar(selectedIndex: -1);
  }
}

// ============================================================================
// MY TURN SCREEN
// ============================================================================

class MyTurnScreen
    extends StatefulWidget {
  const MyTurnScreen({
    super.key,
    required this.yourQueueNumber,
    required this.patients,
    this.appointmentId,
  });

  final int yourQueueNumber;
  final List<QueuePatient> patients;
  final String? appointmentId;

  @override
  State<MyTurnScreen> createState() =>
      _MyTurnScreenState();
}

class _MyTurnScreenState
    extends State<MyTurnScreen> {
  Timer? _timer;

  int _remainingSeconds =
      5 * 60;

  bool _handled = false;

  @override
  void initState() {
    super.initState();

    _startFiveMinuteTimer();
  }

  void _startFiveMinuteTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted ||
            _handled) {
          return;
        }

        if (_remainingSeconds <=
            1) {
          _timer?.cancel();

          setState(() {
            _remainingSeconds =
                0;
          });

          _goToMissedTurn();
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _remainingText {
    final minutes =
        (_remainingSeconds ~/ 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (_remainingSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  void _onMyWay() {
    if (_handled) {
      return;
    }

    _handled = true;
    _timer?.cancel();

    final appointmentId = widget.appointmentId;

    if (appointmentId != null && appointmentId.isNotEmpty) {
      QueueBackend.completeTurn(appointmentId).catchError((e) {
        debugPrint('completeTurn failed: $e');
      });
    }

    QueueNotificationCenter.add(
      title:
          'Appointment Completed',
      body:
          'Your queue turn ${widget.yourQueueNumber} has been marked as completed.',
      icon:
          Icons.check_circle_outline,
      iconColor: Colors.green,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Appointment completed successfully.',
        ),
        duration:
            Duration(seconds: 2),
      ),
    );

    Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(
          context,
        ).popUntil(
          (route) =>
              route.isFirst,
        );
      },
    );
  }

  void _needMoreTime() {
    if (_handled) {
      return;
    }

    _handled = true;
    _timer?.cancel();

    _goToMissedTurn();
  }

  void _goToMissedTurn() {
    if (!mounted) {
      return;
    }

    _handled = true;
    _timer?.cancel();

    final appointmentId = widget.appointmentId;

    if (appointmentId != null && appointmentId.isNotEmpty) {
      QueueBackend.markMissed(appointmentId).catchError((e) {
        debugPrint('markMissed failed: $e');
      });
    }

    QueueNotificationCenter.add(
      title:
          'Missed My Turn',
      body:
          'Your queue position has changed because there was no response within 5 minutes.',
      icon:
          Icons.warning_amber_rounded,
      iconColor:
          Colors.orange,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MissedMyTurnScreen(
          previousQueueNumber:
              widget.yourQueueNumber,
          patients:
              widget.patients,
          appointmentId:
              widget.appointmentId,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            return QueueLayout.body(
              screenWidth: width,
              content: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildMyTurnContent(
                          width,
                        ),
                      ),
              bottomNavigation: _buildBottomNavigation(width),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyTurnContent(
    double width,
  ) {
    final compact =
        width < 380;

    return Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            compact ? 14 : 16,
      ),
      child: Column(
        children: [
          SizedBox(
            height:
                compact ? 8 : 12,
          ),
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: compact ? 40 : 42,
                    height: compact ? 40 : 42,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF063E3E),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Queue Status',
                style: TextStyle(
                  fontSize: compact ? 22 : 25,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF063E3E),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                compact ? 36 : 48,
          ),
          Container(
            width:
                compact ? 66 : 70,
            height:
                compact ? 66 : 70,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFF007471),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Text(
            'Its Your Turn',
            style:
                TextStyle(
              fontSize:
                  compact ? 22 : 24,
              fontWeight:
                  FontWeight.w900,
              color:
                  const Color(
                0xFF063E3E,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Please Proceed to consultation\nRoom 03',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:
                  Color(0xFF789090),
              height: 1.35,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          SizedBox(
            height:
                compact ? 40 : 52,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onMyWay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007471),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'On My Way',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _needMoreTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF063A37),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Need More Time',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  'No response in 5 min → Position is Changed',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        Color(0xFF789090),
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '$_remainingText remaining',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF789090),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                compact ? 16 : 22,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    return const QueueBottomBar(selectedIndex: -1);
  }
}

// ============================================================================
// MISSED MY TURN SCREEN
// ============================================================================

class MissedMyTurnScreen
    extends StatefulWidget {
  const MissedMyTurnScreen({
    super.key,
    required this.previousQueueNumber,
    required this.patients,
    this.appointmentId,
  });

  final int previousQueueNumber;
  final List<QueuePatient> patients;
  final String? appointmentId;

  @override
  State<MissedMyTurnScreen>
      createState() =>
          _MissedMyTurnScreenState();
}

class _MissedMyTurnScreenState
    extends State<
        MissedMyTurnScreen> {
  int get _newQueueNumber {
    if (widget.patients.isEmpty) {
      return widget
              .previousQueueNumber +
          10;
    }

    final numbers = widget
        .patients
        .map(
          (patient) =>
              int.tryParse(
            patient.queueNumber,
          ),
        )
        .whereType<int>()
        .toList();

    final maximum =
        numbers.isEmpty
            ? widget
                .previousQueueNumber
            : numbers.reduce(
                math.max,
              );

    return math.max(
      widget.previousQueueNumber +
          10,
      maximum + 6,
    );
  }

  Future<void> _rejoinQueue() async {
    final appointmentId = widget.appointmentId;

    // Connected to Firestore: take a real new queue number.
    if (appointmentId != null && appointmentId.isNotEmpty) {
      try {
        final newNumber =
            await QueueBackend.rejoinQueue(appointmentId);

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NewQueueStatusScreen(
              yourQueueNumber:
                  newNumber,
              patients:
                  widget.patients,
              currentServingIndex:
                  0,
              averageMinutesPerPatient:
                  QueueBackend.defaultAverageMinutes,
              appointmentId:
                  appointmentId,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to rejoin the queue. Please try again.',
            ),
          ),
        );
      }

      return;
    }

    final newPatients =
        _generateNewQueuePatients();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewQueueStatusScreen(
          yourQueueNumber:
              _newQueueNumber,
          patients:
              newPatients,
          currentServingIndex:
              0,
          averageMinutesPerPatient:
              5,
        ),
      ),
    );
  }

  List<QueuePatient>
      _generateNewQueuePatients() {
    final start =
        math.max(
      1,
      _newQueueNumber - 2,
    );

    return List.generate(
      7,
      (index) {
        final number =
            start + index;

        return QueuePatient(
          queueNumber: number
              .toString()
              .padLeft(2, '0'),
          patientName:
              number ==
                      _newQueueNumber
                  ? 'You'
                  : 'Patient $number',
          doctorName:
              'Dr. R. Fernando',
          status:
              number == start
                  ? 'In Consult'
                  : 'Waiting',
        );
      },
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Support has been notified. Please contact the reception desk.',
        ),
        duration:
            Duration(seconds: 3),
      ),
    );

    QueueNotificationCenter.add(
      title:
          'Support Request',
      body:
          'Your request to contact support has been sent to the reception.',
      icon:
          Icons.support_agent,
      iconColor:
          const Color(0xFF00827D),
    );
  }

  void _cancel() {
    Navigator.of(
      context,
    ).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            return QueueLayout.body(
              screenWidth: width,
              content: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildMissedContent(
                          width,
                        ),
                      ),
              bottomNavigation: _buildBottomNavigation(width),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMissedContent(
    double width,
  ) {
    final compact =
        width < 380;

    return Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            compact ? 14 : 16,
      ),
      child: Column(
        children: [
          SizedBox(
            height:
                compact ? 8 : 12,
          ),
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: compact ? 40 : 42,
                    height: compact ? 40 : 42,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF063E3E),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Queue Status',
                style: TextStyle(
                  fontSize: compact ? 22 : 25,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF063E3E),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                compact ? 36 : 48,
          ),
          Icon(
            Icons.warning_rounded,
            color: const Color(0xFF007471),
            size: compact ? 72 : 82,
          ),
          SizedBox(
            height:
                compact ? 14 : 18,
          ),
          Text(
            'You Missed Your Turn',
            style:
                TextStyle(
              fontSize:
                  compact ? 22 : 24,
              fontWeight:
                  FontWeight.w900,
              color:
                  const Color(
                0xFF063E3E,
              ),
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          const Text(
            'Don’t Worry, You Can Rejoin The Queue',
            style: TextStyle(
              fontSize: 13,
              color:
                  Color(0xFF789090),
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          SizedBox(
            height:
                compact ? 36 : 48,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _rejoinQueue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007471),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Rejoin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _contactSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007471),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007471),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No response in 5 min → Position is Changed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF789090),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                compact ? 14 : 20,
          ),
        ],
      ),
    );
  }


  Widget _buildBottomNavigation(
    double width,
  ) {
    return const QueueBottomBar(selectedIndex: -1);
  }
}

// ============================================================================
// NEW QUEUE STATUS SCREEN
// ============================================================================

class NewQueueStatusScreen
    extends StatefulWidget {
  const NewQueueStatusScreen({
    super.key,
    required this.yourQueueNumber,
    required this.patients,
    required this.currentServingIndex,
    required this.averageMinutesPerPatient,
    this.appointmentId,
  });

  final int yourQueueNumber;
  final List<QueuePatient> patients;
  final int currentServingIndex;
  final int averageMinutesPerPatient;
  final String? appointmentId;

  @override
  State<NewQueueStatusScreen>
      createState() =>
          _NewQueueStatusScreenState();
}

class _NewQueueStatusScreenState
    extends State<
        NewQueueStatusScreen> {
  QueueLiveWatcher? _watcher;
  QueueLiveData? _live;

  late int _yourNumber;
  late int _averageMinutes;
  late List<QueuePatient> _patients;

  @override
  void initState() {
    super.initState();

    _yourNumber = widget.yourQueueNumber;
    _averageMinutes = widget.averageMinutesPerPatient;
    _patients = widget.patients;

    final appointmentId = widget.appointmentId;

    if (appointmentId != null && appointmentId.isNotEmpty) {
      _watcher = QueueLiveWatcher(
        appointmentId: appointmentId,
        onData: (data) {
          if (!mounted) {
            return;
          }

          setState(() {
            _live = data;
            _yourNumber = data.yourQueueNumber;
            _averageMinutes = data.averageMinutesPerPatient;
            _patients = data.patients;
          });
        },
        onError: (_) {},
      )..start();
    }
  }

  @override
  void dispose() {
    _watcher?.dispose();
    super.dispose();
  }

  int get _patientsAhead {
    return _patients
        .where(
          (patient) {
            final number =
                int.tryParse(
              patient.queueNumber,
            );

            return number != null &&
                number < _yourNumber &&
                !QueueBackend.isFinished(
                  patient.status,
                );
          },
        )
        .length;
  }

  QueuePatient
      get _currentlyServing {
    final liveServing = _live?.currentlyServing;

    if (liveServing != null) {
      return liveServing;
    }

    if (_patients.isEmpty) {
      return const QueuePatient(
        queueNumber: '001',
        patientName:
            'No Patient',
        doctorName:
            'Dr. R. Fernando',
        status:
            'In Consult',
      );
    }

    final index =
        widget.currentServingIndex
            .clamp(
      0,
      _patients.length - 1,
    );

    return widget
        .patients[index];
  }

  int get _estimatedMinutes {
    return math.max(
      1,
      _patientsAhead *
          _averageMinutes,
    );
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EstimatedWaitingTimeScreen(
          yourQueueNumber:
              _yourNumber,
          averageMinutesPerPatient:
              _averageMinutes,
          patientsAhead:
              _patientsAhead,
          patients:
              _patients,
          appointmentId:
              widget.appointmentId,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final width =
                constraints.maxWidth;

            return QueueLayout.body(
              screenWidth: width,
              content: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildNewQueueContent(
                          width,
                        ),
                      ),
              bottomNavigation: _buildBottomNavigation(width),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewQueueContent(
    double width,
  ) {
    final compact =
        width < 380;

    return Padding(
      padding:
          EdgeInsets.symmetric(
        horizontal:
            compact ? 14 : 16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height:
                compact ? 8 : 12,
          ),
          Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: SizedBox(
                    width: compact ? 40 : 42,
                    height: compact ? 40 : 42,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF063E3E),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Queue Status',
                style: TextStyle(
                  fontSize: compact ? 22 : 25,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF063E3E),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                compact ? 12 : 16,
          ),
          _buildServingCard(
            compact,
          ),
          SizedBox(
            height:
                compact ? 24 : 32,
          ),
          Center(
            child: CustomPaint(
              painter:
                  _QueueSignalPainter(),
              size:
                  const Size(
                40,
                40,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Center(
            child: Text(
              'Your New Position',
              style:
                  TextStyle(
                fontSize:
                    compact ? 19 : 21,
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(
                  0xFF063E3E,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Center(
            child: Text(
              '#$_yourNumber',
              style:
                  TextStyle(
                fontSize:
                    compact ? 44 : 52,
                height: 1,
                fontWeight:
                    FontWeight.w900,
                color:
                    const Color(
                  0xFF007471,
                ),
              ),
            ),
          ),
          SizedBox(
            height:
                compact ? 24 : 30,
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF007471),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _buildNewQueueScroller(
            compact,
          ),
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 6,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Est. Wait: $_estimatedMinutes mins',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xFF007471,
                    ),
                  ),
                ),
                Text(
                  '$_patientsAhead Patient Ahead',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xFF007471,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                compact ? 24 : 30,
          ),
          SizedBox(
            width:
                double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF007471,
                ),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    const StadiumBorder(),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildServingCard(
    bool compact,
  ) {
    final serving =
        _currentlyServing;
    final doctor = serving.doctorName.isNotEmpty ? serving.doctorName : 'Dr. R. Fernando';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 13 : 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF007471),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENTLY SERVING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'T-${serving.queueNumber}',
                  style: TextStyle(
                    color: const Color(0xFF007471),
                    fontSize: compact ? 17 : 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doctor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'In Consult',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewQueueScroller(
    bool compact,
  ) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _patients.length,
        separatorBuilder: (_, _) => const SizedBox(
          width: 10,
        ),
        itemBuilder: (context, index) {
          final patient = _patients[index];
          final number = int.tryParse(patient.queueNumber);
          final selected = number == _yourNumber;

          return Container(
            width: compact ? 50 : 54,
            height: compact ? 50 : 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF007471)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF007471),
                width: 1.5,
              ),
            ),
            child: Text(
              patient.queueNumber,
              style: TextStyle(
                fontSize: 18,
                fontWeight: selected
                    ? FontWeight.w900
                    : FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(0xFF063E3E),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    return const QueueBottomBar(selectedIndex: -1);
  }
}

// ============================================================================
// WAITING TIME CIRCLE PAINTER
// ============================================================================

class _WaitingTimePainter
    extends CustomPainter {
  final double progress;

  const _WaitingTimePainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(
          size.width,
          size.height,
        ) /
            2 -
        8;

    final trackPaint =
        Paint()
          ..color =
              const Color(
            0xFFDDEDEA,
          )
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 17
          ..strokeCap =
              StrokeCap.round;

    final progressPaint =
        Paint()
          ..color =
              const Color(
            0xFF00827D,
          )
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 17
          ..strokeCap =
              StrokeCap.round;

    const startAngle =
        -math.pi / 2;

    const gap = 0.35;

    final sweep =
        (2 * math.pi - gap) *
            progress;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle + gap / 2,
      2 * math.pi - gap,
      false,
      trackPaint,
    );

    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle + gap / 2,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
        _WaitingTimePainter
            oldDelegate,
  ) {
    return oldDelegate
            .progress !=
        progress;
  }
}

// ============================================================================
// SIGNAL ICON PAINTER
// ============================================================================

class _QueueSignalPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final paint = Paint()
      ..color = Colors.red
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap =
          StrokeCap.round;

    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = Colors.red
        ..style =
            PaintingStyle.fill,
    );

    final path1 = Path()
      ..moveTo(
        center.dx - 9,
        center.dy - 8,
      )
      ..quadraticBezierTo(
        center.dx - 16,
        center.dy,
        center.dx - 9,
        center.dy + 8,
      );

    canvas.drawPath(
      path1,
      paint,
    );

    final path2 = Path()
      ..moveTo(
        center.dx + 9,
        center.dy - 8,
      )
      ..quadraticBezierTo(
        center.dx + 16,
        center.dy,
        center.dx + 9,
        center.dy + 8,
      );

    canvas.drawPath(
      path2,
      paint,
    );

    final path3 = Path()
      ..moveTo(
        center.dx - 16,
        center.dy - 14,
      )
      ..quadraticBezierTo(
        center.dx - 27,
        center.dy,
        center.dx - 16,
        center.dy + 14,
      );

    canvas.drawPath(
      path3,
      paint,
    );

    final path4 = Path()
      ..moveTo(
        center.dx + 16,
        center.dy - 14,
      )
      ..quadraticBezierTo(
        center.dx + 27,
        center.dy,
        center.dx + 16,
        center.dy + 14,
      );

    canvas.drawPath(
      path4,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant
        CustomPainter oldDelegate,
  ) {
    return false;
  }
}