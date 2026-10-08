import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
// QUEUE STATUS SCREEN
// ============================================================================

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({
    super.key,
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

  bool _isLoading = true;
  String? _errorMessage;

  String? _appointmentId;
  String? _hospital;
  String? _doctorName;
  String? _date;
  String? _session;
  String? _patientName;

  int _yourQueueNumber = 0;

  List<QueuePatient> _patients = [];

  final int _averageMinutesPerPatient = 5;

  final int _selectedBottomIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadQueueData();
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================================
  // LOAD USER'S CHECKED-IN APPOINTMENT
  // ==========================================================================

  Future<void> _loadQueueData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please log in before viewing your queue.',
        );
      }

      // Get the user's checked-in appointment.
      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .where(
            'userId',
            isEqualTo: user.uid,
          )
          .where(
            'checkedIn',
            isEqualTo: true,
          )
          .get();

      if (appointmentSnapshot.docs.isEmpty) {
        throw Exception(
          'No checked-in appointment was found.',
        );
      }

      // Prefer an appointment that is still waiting.
      QueryDocumentSnapshot<Map<String, dynamic>> appointmentDoc =
          appointmentSnapshot.docs.first;

      for (final doc in appointmentSnapshot.docs) {
        final data = doc.data();

        final queueStatus =
            data['queueStatus']?.toString().toLowerCase();

        if (queueStatus == 'waiting') {
          appointmentDoc = doc;
          break;
        }
      }

      final data = appointmentDoc.data();

      _appointmentId = appointmentDoc.id;

      _hospital =
          data['hospitalName']?.toString() ??
              data['hospital']?.toString();

      

      _date =
          data['date']?.toString();

      _session =
          data['session']?.toString();

      _patientName =
          data['patientName']?.toString();

      final queueNumberValue =
          data['queueNumber'] ?? data['queueNo'];

      _yourQueueNumber =
          _readQueueNumber(queueNumberValue);

      if (_appointmentId == null ||
          _appointmentId!.isEmpty) {
        throw Exception(
          'Appointment ID is missing.',
        );
      }

      if (_hospital == null ||
          _hospital!.isEmpty) {
        throw Exception(
          'Hospital information is missing.',
        );
      }

      if (_doctorName == null ||
          _doctorName!.isEmpty) {
        throw Exception(
          'Doctor information is missing.',
        );
      }

      // Start real-time queue listener.
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
  // LISTEN TO FIRESTORE QUEUES
  // ==========================================================================

  void _listenToQueues() {
    _queueSubscription?.cancel();

    _queueSubscription = _firestore
        .collection('queues')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        final List<QueuePatient> loadedPatients = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final hospital =
              data['hospital']?.toString();

          final doctorName =
              data['doctorName']?.toString();


          final session =
              data['session']?.toString();

          // Match the queue with the current appointment.
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

          loadedPatients.add(
            QueuePatient(
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
            ),
          );
        }

        // If the current queue document was not found in the
        // filtered queue collection, create it from the appointment.
        final containsYourNumber =
            loadedPatients.any(
          (patient) =>
              int.tryParse(patient.queueNumber) ==
              _yourQueueNumber,
        );

        if (!containsYourNumber &&
            _yourQueueNumber > 0) {
          loadedPatients.add(
            QueuePatient(
              queueNumber: _yourQueueNumber
                  .toString()
                  .padLeft(2, '0'),
              patientName:
                  _patientName ?? 'You',
              doctorName:
                  _doctorName ?? '',
              status: 'Waiting',
            ),
          );
        }

        loadedPatients.sort(
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
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load live queue data.';
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

          if (queueDateText ==
              formatted) {
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
      if (patient.status
              .toLowerCase() !=
          'completed') {
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
          patient.status
                  .toLowerCase() !=
              'completed') {
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

            final horizontalPadding =
                width < 380
                    ? 14.0
                    : width < 600
                        ? 24.0
                        : math.min(
                            width * 0.08,
                            70.0,
                          );

            final contentWidth =
                math.min(
              width -
                  (horizontalPadding *
                      2),
              700.0,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          _buildBody(width),
                    ),
                    _buildBottomNavigation(
                      width,
                    ),
                  ],
                ),
              ),
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
            SizedBox(
              width: 150,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _loadQueueData,
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
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                ),
                child:
                    const Text('Retry'),
              ),
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

  Widget _buildCurrentlyServingCard(
    bool compact,
  ) {
    final serving =
        _currentlyServing;

    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(
        minHeight:
            compact ? 138 : 150,
      ),
      padding:
          EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 13 : 15,
        compact ? 14 : 16,
        compact ? 14 : 16,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF00827D),
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENTLY SERVING',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize:
                  compact ? 10 : 11,
              fontWeight:
                  FontWeight.w700,
              letterSpacing:
                  0.3,
            ),
          ),
          SizedBox(
            height:
                compact ? 9 : 11,
          ),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .center,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      compact ? 11 : 13,
                  vertical:
                      compact ? 7 : 8,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  'T-${serving.queueNumber}',
                  style:
                      TextStyle(
                    color:
                        const Color(
                      0xFF00827D,
                    ),
                    fontSize:
                        compact ? 18 : 20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  serving
                      .patientName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        compact
                            ? 11
                            : 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                serving.status
                            .toLowerCase() ==
                        'waiting'
                    ? 'In Consult'
                    : serving.status,
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize:
                      compact ? 9 : 10,
                  fontWeight:
                      FontWeight.w700,
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
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: Text(
        'Current Queue',
        style: TextStyle(
          fontSize:
              compact ? 13 : 14,
          fontWeight:
              FontWeight.w500,
          color:
              const Color(
            0xFF00827D,
          ),
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
          compact ? 58 : 62,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 22,
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
          width: 13,
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
                0xFF39A49E,
              )
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          11,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFF00827D,
          ),
          width:
              isSelected ? 0 : 1.6,
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
              : FontWeight.w500,
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoItem(
              title: 'Est. Wait',
              value:
                  '$_estimatedWaitingMinutes mins',
              compact:
                  compact,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Align(
              alignment:
                  Alignment.centerRight,
              child: _buildInfoItem(
                title:
                    'Patient Ahead',
                value:
                    '$_patientsAhead',
                compact:
                    compact,
                alignRight:
                    true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required bool compact,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color:
                const Color(
              0xFF00827D,
            ),
            fontSize:
                compact ? 10 : 11,
            fontWeight:
                FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style: TextStyle(
            color:
                const Color(
              0xFF00827D,
            ),
            fontSize:
                compact ? 10 : 11,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
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
        horizontal: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height:
            compact ? 44 : 48,
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
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize:
                  compact ? 13 : 14,
              fontWeight:
                  FontWeight.w600,
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
    final compact =
        width < 380;

    return Container(
      width: double.infinity,
      height:
          compact ? 66 : 72,
      decoration:
          const BoxDecoration(
        color: Colors.white,
        border:
            Border(
          top: BorderSide(
            color:
                Color(0xFFE1E9E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            icon:
                Icons.home_outlined,
            selectedIcon:
                Icons.home_rounded,
            label: 'Home',
            index: 0,
            compact:
                compact,
          ),
          _buildNavItem(
            icon: Icons
                .calendar_today_outlined,
            selectedIcon: Icons
                .calendar_month_rounded,
            label:
                'Appointments',
            index: 1,
            compact:
                compact,
          ),
          _buildNavItem(
            icon: Icons
                .format_list_bulleted,
            selectedIcon: Icons
                .format_list_bulleted,
            label: 'Queue',
            index: 2,
            compact:
                compact,
          ),
          _buildNavItem(
            icon: Icons
                .notifications_none_rounded,
            selectedIcon: Icons
                .notifications_rounded,
            label: 'Alerts',
            index: 3,
            compact:
                compact,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool compact,
  }) {
    final selected =
        _selectedBottomIndex ==
            index;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2) {
            return;
          }

          _handleNavigation(index);
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size:
                  compact ? 21 : 23,
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : const Color(
                      0xFF789090,
                    ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                fontSize:
                    compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(
                        0xFF00827D,
                      )
                    : const Color(
                        0xFF789090,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(
    int index,
  ) {
    if (index == 2) {
      return;
    }

    QueueNavigationCenter
        .goToTab(
      context,
      index,
    );
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
  });

  final int yourQueueNumber;
  final int averageMinutesPerPatient;
  final int patientsAhead;
  final List<QueuePatient> patients;

  @override
  State<EstimatedWaitingTimeScreen>
      createState() =>
          _EstimatedWaitingTimeScreenState();
}

class _EstimatedWaitingTimeScreenState
    extends State<
        EstimatedWaitingTimeScreen> {
  Timer? _timer;

  late int _initialSeconds;
  late int _remainingSeconds;

  final int _selectedBottomIndex = 2;

  @override
  void initState() {
    super.initState();

    final calculatedMinutes =
        math.max(
      1,
      widget.patientsAhead *
          widget.averageMinutesPerPatient,
    );

    _initialSeconds =
        calculatedMinutes * 60;

    _remainingSeconds =
        _initialSeconds;

    _startCountdown();
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

          _openMyTurn();
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
    if (!mounted) {
      return;
    }

    QueueNotificationCenter.add(
      title: 'It\'s Your Turn',
      body:
          'Your queue number ${widget.yourQueueNumber} is now ready. Please proceed to the consultation room.',
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
              widget.yourQueueNumber,
          patients:
              widget.patients,
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

            final horizontalPadding =
                width < 380
                    ? 14.0
                    : width < 600
                        ? 24.0
                        : math.min(
                            width * 0.08,
                            70.0,
                          );

            final contentWidth =
                math.min(
              width -
                  (horizontalPadding *
                      2),
              700.0,
            );

            return Center(
              child: SizedBox(
                width:
                    contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildEstimatedContent(
                          width,
                        ),
                      ),
                    ),
                    _buildBottomNavigation(
                      width,
                    ),
                  ],
                ),
              ),
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
          const Text(
            'Estimated Waiting Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF063E3E),
              letterSpacing:
                  -0.4,
            ),
          ),
          SizedBox(
            height:
                compact ? 32 : 42,
          ),
          Center(
            child:
                _buildCountdownCircle(
              compact,
            ),
          ),
          SizedBox(
            height:
                compact ? 34 : 40,
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
                color:
                    Color(0xFF00827D),
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildQueueStrip(
            compact,
          ),
          SizedBox(
            height:
                compact ? 16 : 18,
          ),
          _buildEstimatedInformation(
            compact,
          ),
          SizedBox(
            height:
                compact ? 24 : 28,
          ),
          _buildEstimatedNextButton(
            compact,
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
                      FontWeight.w800,
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
                      compact ? 24 : 26,
                  fontWeight:
                      FontWeight.w800,
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
          horizontal: 22,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            widget.patients.length,
        separatorBuilder:
            (_, _) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final patient =
              widget.patients[index];

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
                      0xFF39A49E,
                    )
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFF00827D,
                ),
                width:
                    selected ? 0 : 1.5,
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
                        : FontWeight.w500,
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

  Widget _buildEstimatedInformation(
    bool compact,
  ) {
    final estimatedWait =
        math.max(
      1,
      widget.patientsAhead *
          widget.averageMinutesPerPatient,
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: Row(
        children: [
          Expanded(
            child: _smallInfo(
              'Est. Wait',
              '$estimatedWait mins',
            ),
          ),
          Expanded(
            child: Align(
              alignment:
                  Alignment.centerRight,
              child: _smallInfo(
                'Patient Ahead',
                '${widget.patientsAhead}',
                right: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(
    String title,
    String value, {
    bool right = false,
  }) {
    return Column(
      crossAxisAlignment:
          right
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 10,
            color:
                Color(0xFF00827D),
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 10,
            color:
                Color(0xFF00827D),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedNextButton(
    bool compact,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height:
            compact ? 44 : 48,
        child: ElevatedButton(
          onPressed:
              _openMyTurn,
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
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),
          ),
          child:
              const Text(
            'Next',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    final compact =
        width < 380;

    return Container(
      height:
          compact ? 66 : 72,
      color: Colors.white,
      child: Row(
        children: [
          _estimatedNavItem(
            Icons.home_outlined,
            Icons.home_rounded,
            'Home',
            0,
            compact,
          ),
          _estimatedNavItem(
            Icons
                .calendar_today_outlined,
            Icons
                .calendar_month_rounded,
            'Appointments',
            1,
            compact,
          ),
          _estimatedNavItem(
            Icons
                .format_list_bulleted,
            Icons
                .format_list_bulleted,
            'Queue',
            2,
            compact,
          ),
          _estimatedNavItem(
            Icons
                .notifications_none_rounded,
            Icons
                .notifications_rounded,
            'Alerts',
            3,
            compact,
          ),
        ],
      ),
    );
  }

  Widget _estimatedNavItem(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool compact,
  ) {
    final selected =
        index ==
            _selectedBottomIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          QueueNavigationCenter
              .goToTab(
            context,
            index,
          );
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size:
                  compact ? 21 : 23,
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : const Color(
                      0xFF789090,
                    ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(
                        0xFF00827D,
                      )
                    : const Color(
                        0xFF789090,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final int yourQueueNumber;
  final List<QueuePatient> patients;

  @override
  State<MyTurnScreen> createState() =>
      _MyTurnScreenState();
}

class _MyTurnScreenState
    extends State<MyTurnScreen> {
  Timer? _timer;

  int _remainingSeconds =
      5 * 60;

  final int _selectedBottomIndex =
      0;

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

            final contentWidth =
                math.min(
              width - 28,
              700.0,
            );

            return Center(
              child: SizedBox(
                width:
                    contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildMyTurnContent(
                          width,
                        ),
                      ),
                    ),
                    _buildBottomNavigation(
                      width,
                    ),
                  ],
                ),
              ),
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
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'My Turn',
              style:
                  TextStyle(
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
                compact ? 100 : 125,
          ),
          Container(
            width:
                compact ? 66 : 70,
            height:
                compact ? 66 : 70,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFF39A49E),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 42,
            ),
          ),
          SizedBox(
            height:
                compact ? 14 : 18,
          ),
          Text(
            'Its Your Turn',
            style:
                TextStyle(
              fontSize:
                  compact ? 20 : 21,
              fontWeight:
                  FontWeight.w900,
              color:
                  const Color(
                0xFF063E3E,
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          const Text(
            'Please Process to consultation',
            style: TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF00827D),
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          const Text(
            'Room 03',
            style: TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF00827D),
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          SizedBox(
            height:
                compact ? 112 : 130,
          ),
          _buildMyTurnButton(
            label: 'On My Way',
            color:
                const Color(
              0xFF39A49E,
            ),
            onPressed:
                _onMyWay,
          ),
          const SizedBox(
            height: 12,
          ),
          _buildMyTurnButton(
            label:
                'Need More Time',
            color:
                const Color(
              0xFF00827D,
            ),
            onPressed:
                _needMoreTime,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No response in 5 min → Position is Changed',
            style:
                TextStyle(
              fontSize:
                  compact ? 10 : 11,
              fontWeight:
                  FontWeight.w500,
              color:
                  const Color(
                0xFF00827D,
              ),
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            '$_remainingText remaining',
            style:
                TextStyle(
              fontSize:
                  compact ? 9 : 10,
              color:
                  const Color(
                0xFF789090,
              ),
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

  Widget _buildMyTurnButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed:
            onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              color,
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
        ),
        child: Text(
          label,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    final compact =
        width < 380;

    return Container(
      height:
          compact ? 66 : 72,
      color: Colors.white,
      child: Row(
        children: [
          _myTurnNav(
            Icons.home_outlined,
            Icons.home_rounded,
            'Home',
            0,
            compact,
          ),
          _myTurnNav(
            Icons
                .calendar_today_outlined,
            Icons
                .calendar_month_rounded,
            'Appointments',
            1,
            compact,
          ),
          _myTurnNav(
            Icons
                .format_list_bulleted,
            Icons
                .format_list_bulleted,
            'Queue',
            2,
            compact,
          ),
          _myTurnNav(
            Icons
                .notifications_none_rounded,
            Icons
                .notifications_rounded,
            'Alerts',
            3,
            compact,
          ),
        ],
      ),
    );
  }

  Widget _myTurnNav(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool compact,
  ) {
    final selected =
        index ==
            _selectedBottomIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          QueueNavigationCenter
              .goToTab(
            context,
            index,
          );
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size:
                  compact ? 21 : 23,
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : const Color(
                      0xFF789090,
                    ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(
                        0xFF00827D,
                      )
                    : const Color(
                        0xFF789090,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final int previousQueueNumber;
  final List<QueuePatient> patients;

  @override
  State<MissedMyTurnScreen>
      createState() =>
          _MissedMyTurnScreenState();
}

class _MissedMyTurnScreenState
    extends State<
        MissedMyTurnScreen> {
  final int _selectedBottomIndex =
      0;

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

  void _rejoinQueue() {
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

            final contentWidth =
                math.min(
              width - 28,
              700.0,
            );

            return Center(
              child: SizedBox(
                width:
                    contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildMissedContent(
                          width,
                        ),
                      ),
                    ),
                    _buildBottomNavigation(
                      width,
                    ),
                  ],
                ),
              ),
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
          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              'Missed My Turn',
              style:
                  TextStyle(
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
                compact ? 120 : 140,
          ),
          const Icon(
            Icons.warning,
            color:
                Color(0xFF39A49E),
            size: 78,
          ),
          SizedBox(
            height:
                compact ? 12 : 16,
          ),
          Text(
            'You Missed Your Turn',
            style:
                TextStyle(
              fontSize:
                  compact ? 19 : 20,
              fontWeight:
                  FontWeight.w900,
              color:
                  const Color(
                0xFF063E3E,
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          const Text(
            'Don’t Worry, You Can Rejoin The Queue',
            style: TextStyle(
              fontSize: 11,
              color:
                  Color(0xFF00827D),
              fontWeight:
                  FontWeight.w500,
            ),
          ),
          SizedBox(
            height:
                compact ? 82 : 98,
          ),
          _missedButton(
            label: 'Rejoin',
            color:
                const Color(
              0xFF39A49E,
            ),
            onPressed:
                _rejoinQueue,
          ),
          const SizedBox(
            height: 10,
          ),
          _missedButton(
            label:
                'Contact Support',
            color:
                const Color(
              0xFF00827D,
            ),
            onPressed:
                _contactSupport,
          ),
          const SizedBox(
            height: 10,
          ),
          _missedButton(
            label: 'Cancel',
            color:
                const Color(
              0xFF00827D,
            ),
            onPressed:
                _cancel,
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'No response in 5 min → Position is Changed',
            style: TextStyle(
              fontSize: 10,
              color:
                  Color(0xFF00827D),
              fontWeight:
                  FontWeight.w500,
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

  Widget _missedButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed:
            onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              color,
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),
        ),
        child: Text(
          label,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    final compact =
        width < 380;

    return Container(
      height:
          compact ? 66 : 72,
      color: Colors.white,
      child: Row(
        children: [
          _missedNav(
            Icons.home_outlined,
            Icons.home_rounded,
            'Home',
            0,
            compact,
          ),
          _missedNav(
            Icons
                .calendar_today_outlined,
            Icons
                .calendar_month_rounded,
            'Appointments',
            1,
            compact,
          ),
          _missedNav(
            Icons
                .format_list_bulleted,
            Icons
                .format_list_bulleted,
            'Queue',
            2,
            compact,
          ),
          _missedNav(
            Icons
                .notifications_none_rounded,
            Icons
                .notifications_rounded,
            'Alerts',
            3,
            compact,
          ),
        ],
      ),
    );
  }

  Widget _missedNav(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool compact,
  ) {
    final selected =
        index ==
            _selectedBottomIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          QueueNavigationCenter
              .goToTab(
            context,
            index,
          );
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size:
                  compact ? 21 : 23,
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : const Color(
                      0xFF789090,
                    ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(
                        0xFF00827D,
                      )
                    : const Color(
                        0xFF789090,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final int yourQueueNumber;
  final List<QueuePatient> patients;
  final int currentServingIndex;
  final int averageMinutesPerPatient;

  @override
  State<NewQueueStatusScreen>
      createState() =>
          _NewQueueStatusScreenState();
}

class _NewQueueStatusScreenState
    extends State<
        NewQueueStatusScreen> {
  final int _selectedBottomIndex =
      2;

  int get _patientsAhead {
    return widget.patients
        .where(
          (patient) {
            final number =
                int.tryParse(
              patient.queueNumber,
            );

            return number != null &&
                number <
                    widget
                        .yourQueueNumber &&
                patient.status
                        .toLowerCase() !=
                    'completed';
          },
        )
        .length;
  }

  QueuePatient
      get _currentlyServing {
    if (widget.patients.isEmpty) {
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
      widget.patients.length - 1,
    );

    return widget
        .patients[index];
  }

  int get _estimatedMinutes {
    return math.max(
      1,
      _patientsAhead *
          widget.averageMinutesPerPatient,
    );
  }

  void _next() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EstimatedWaitingTimeScreen(
          yourQueueNumber:
              widget.yourQueueNumber,
          averageMinutesPerPatient:
              widget
                  .averageMinutesPerPatient,
          patientsAhead:
              _patientsAhead,
          patients:
              widget.patients,
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

            final contentWidth =
                math.min(
              width - 28,
              700.0,
            );

            return Center(
              child: SizedBox(
                width:
                    contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildNewQueueContent(
                          width,
                        ),
                      ),
                    ),
                    _buildBottomNavigation(
                      width,
                    ),
                  ],
                ),
              ),
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
          Text(
            'New Queue Status',
            style:
                TextStyle(
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
          SizedBox(
            height:
                compact ? 8 : 10,
          ),
          _buildServingCard(
            compact,
          ),
          SizedBox(
            height:
                compact ? 32 : 36,
          ),
          Center(
            child: CustomPaint(
              painter:
                  _QueueSignalPainter(),
              size:
                  const Size(
                42,
                42,
              ),
            ),
          ),
          SizedBox(
            height:
                compact ? 8 : 10,
          ),
          Center(
            child: Text(
              'Your New Position',
              style:
                  TextStyle(
                fontSize:
                    compact ? 20 : 21,
                fontWeight:
                    FontWeight.w900,
                color:
                    const Color(
                  0xFF063E3E,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Center(
            child: Text(
              '#${widget.yourQueueNumber}',
              style:
                  TextStyle(
                fontSize:
                    compact ? 48 : 54,
                height: 1,
                fontWeight:
                    FontWeight.w900,
                color:
                    const Color(
                  0xFF00827D,
                ),
              ),
            ),
          ),
          SizedBox(
            height:
                compact ? 30 : 36,
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w500,
                color:
                    Color(0xFF00827D),
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildNewQueueScroller(
            compact,
          ),
          SizedBox(
            height:
                compact ? 16 : 18,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Est. Wait: $_estimatedMinutes mins',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          Color(
                        0xFF00827D,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$_patientsAhead Patient Ahead',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        Color(
                      0xFF00827D,
                    ),
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
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: SizedBox(
              width:
                  double.infinity,
              height: 48,
              child:
                  ElevatedButton(
                onPressed: _next,
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF00827D,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                ),
                child:
                    const Text(
                  'Next',
                  style:
                      TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
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

    return Container(
      width: double.infinity,
      height:
          compact ? 116 : 116,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF00827D),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENTLY SERVING',
            style:
                TextStyle(
              color:
                  Colors.white,
              fontSize:
                  compact ? 9 : 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
                child: Text(
                  'T-${serving.queueNumber}',
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF00827D,
                    ),
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  serving.patientName,
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
              Text(
                serving.status
                            .toLowerCase() ==
                        'waiting'
                    ? 'In Consult'
                    : serving.status,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w700,
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
      height: 56,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 22,
        ),
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            widget.patients.length,
        separatorBuilder:
            (_, _) =>
                const SizedBox(
          width: 12,
        ),
        itemBuilder:
            (context, index) {
          final patient =
              widget.patients[index];

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
                      0xFF39A49E,
                    )
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFF00827D,
                ),
                width:
                    selected ? 0 : 1.5,
              ),
            ),
            child: Text(
              patient.queueNumber,
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    selected
                        ? FontWeight.w900
                        : FontWeight.w500,
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
    final compact =
        width < 380;

    return Container(
      height:
          compact ? 66 : 72,
      color: Colors.white,
      child: Row(
        children: [
          _newQueueNav(
            Icons.home_outlined,
            Icons.home_rounded,
            'Home',
            0,
            compact,
          ),
          _newQueueNav(
            Icons
                .calendar_today_outlined,
            Icons
                .calendar_month_rounded,
            'Appointments',
            1,
            compact,
          ),
          _newQueueNav(
            Icons
                .format_list_bulleted,
            Icons
                .format_list_bulleted,
            'Queue',
            2,
            compact,
          ),
          _newQueueNav(
            Icons
                .notifications_none_rounded,
            Icons
                .notifications_rounded,
            'Alerts',
            3,
            compact,
          ),
        ],
      ),
    );
  }

  Widget _newQueueNav(
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool compact,
  ) {
    final selected =
        index ==
            _selectedBottomIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 2) {
            return;
          }

          QueueNavigationCenter
              .goToTab(
            context,
            index,
          );
        },
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? selectedIcon
                  : icon,
              size:
                  compact ? 21 : 23,
              color: selected
                  ? const Color(
                      0xFF00827D,
                    )
                  : const Color(
                      0xFF789090,
                    ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(
                        0xFF00827D,
                      )
                    : const Color(
                        0xFF789090,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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