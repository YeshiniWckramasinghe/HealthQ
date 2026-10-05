import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================================
// NOTIFICATION MODEL
// ============================================================================

class HealthQNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;

  const HealthQNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

// ============================================================================
// GLOBAL FRONTEND NOTIFICATION STORE
// ============================================================================

class HealthQNotificationStore extends ChangeNotifier {
  HealthQNotificationStore._();

  static final HealthQNotificationStore instance =
      HealthQNotificationStore._();

  final List<HealthQNotification> _notifications = [];

  List<HealthQNotification> get notifications =>
      List.unmodifiable(_notifications);

  void addNotification({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    _notifications.insert(
      0,
      HealthQNotification(
        title: title,
        body: body,
        time: time,
        icon: icon,
        iconColor: iconColor,
      ),
    );

    notifyListeners();
  }
}

// ============================================================================
// QUEUE PATIENT
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
// QUEUE STATUS SCREEN
// ============================================================================

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({
    super.key,
    this.yourQueueNumber = 9,
    this.currentServingIndex = 0,
    this.averageMinutesPerPatient = 5,
    this.patients = const [
      QueuePatient(
        queueNumber: '07',
        patientName: 'Patient 07',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '08',
        patientName: 'Patient 08',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '09',
        patientName: 'You',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '10',
        patientName: 'Patient 10',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '11',
        patientName: 'Patient 11',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '12',
        patientName: 'Patient 12',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber: '13',
        patientName: 'Patient 13',
        doctorName: 'Dr. R. Fernando',
      ),
    ],
  });

  final int yourQueueNumber;
  final int currentServingIndex;
  final int averageMinutesPerPatient;
  final List<QueuePatient> patients;

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  int _selectedBottomIndex = 2;

  int get _yourQueueNumber => widget.yourQueueNumber;

  QueuePatient get _currentlyServing {
    if (widget.patients.isEmpty) {
      return const QueuePatient(
        queueNumber: '01',
        patientName: 'No Patient',
        doctorName: 'Dr. R. Fernando',
        status: 'In Consult',
      );
    }

    final index = widget.currentServingIndex.clamp(
      0,
      widget.patients.length - 1,
    );

    return widget.patients[index];
  }

  int get _patientsAhead {
    if (widget.patients.isEmpty) return 0;

    int count = 0;

    for (final patient in widget.patients) {
      final number = int.tryParse(patient.queueNumber);

      if (number != null &&
          number < _yourQueueNumber &&
          patient.status.toLowerCase() != 'completed') {
        count++;
      }
    }

    return count;
  }

  int get _estimatedWaitingMinutes {
    final calculated =
        _patientsAhead * widget.averageMinutesPerPatient;

    return calculated < 1 ? 1 : calculated;
  }

  String get _yourQueueText {
    return _yourQueueNumber.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final horizontalPadding = width < 380
                ? 14.0
                : width < 600
                    ? 24.0
                    : math.min(width * 0.08, 70.0);

            final contentWidth = math.min(
              width - (horizontalPadding * 2),
              700.0,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            0,
                            4,
                            0,
                            width < 600 ? 14 : 24,
                          ),
                          child: _buildMainContent(width),
                        ),
                      ),
                    ),
                    _buildBottomNavigation(width),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(double width) {
    final compact = width < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: compact ? 8 : 12),

        _buildTitle(compact),

        SizedBox(height: compact ? 12 : 16),

        _buildCurrentlyServingCard(compact),

        SizedBox(height: compact ? 32 : 42),

        _buildSignalIcon(),

        SizedBox(height: compact ? 8 : 10),

        _buildYourNumberSection(compact),

        SizedBox(height: compact ? 32 : 40),

        _buildCurrentQueueTitle(compact),

        SizedBox(height: compact ? 12 : 14),

        _buildQueueScroller(compact),

        SizedBox(height: compact ? 18 : 20),

        _buildQueueInformation(compact),

        SizedBox(height: compact ? 22 : 30),

        _buildNextButton(compact),
      ],
    );
  }

  Widget _buildTitle(bool compact) {
    return Text(
      'Queue Status',
      style: TextStyle(
        fontSize: compact ? 22 : 25,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF063E3E),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCurrentlyServingCard(bool compact) {
    final serving = _currentlyServing;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: compact ? 138 : 150,
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        compact ? 13 : 15,
        compact ? 14 : 16,
        compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF00827D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENTLY SERVING',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),

          SizedBox(height: compact ? 9 : 11),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 13,
                  vertical: compact ? 7 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'T-${serving.queueNumber}',
                  style: TextStyle(
                    color: const Color(0xFF00827D),
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  serving.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                serving.status == 'Waiting'
                    ? 'In Consult'
                    : serving.status,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalIcon() {
    return Center(
      child: SizedBox(
        height: 42,
        width: 42,
        child: CustomPaint(
          painter: _QueueSignalPainter(),
        ),
      ),
    );
  }

  Widget _buildYourNumberSection(bool compact) {
    return Column(
      children: [
        Center(
          child: Text(
            'Your Number',
            style: TextStyle(
              fontSize: compact ? 21 : 23,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF063E3E),
            ),
          ),
        ),

        SizedBox(height: compact ? 2 : 4),

        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '#$_yourQueueText',
              style: TextStyle(
                fontSize: compact ? 54 : 60,
                height: 1,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF00827D),
                letterSpacing: -2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentQueueTitle(bool compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Text(
        'Current Queue',
        style: TextStyle(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF00827D),
        ),
      ),
    );
  }

  Widget _buildQueueScroller(bool compact) {
    return SizedBox(
      height: compact ? 58 : 62,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.patients.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 13);
        },
        itemBuilder: (context, index) {
          final patient = widget.patients[index];

          final number = int.tryParse(patient.queueNumber);

          final isYourNumber = number == _yourQueueNumber;

          return _buildQueueNumberBox(
            patient.queueNumber,
            isYourNumber,
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
      duration: const Duration(milliseconds: 250),
      width: compact ? 54 : 56,
      height: compact ? 54 : 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF39A49E)
            : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF00827D),
          width: isSelected ? 0 : 1.6,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF00827D)
                      .withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: compact ? 19 : 20,
          fontWeight: isSelected
              ? FontWeight.w900
              : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : const Color(0xFF063E3E),
        ),
      ),
    );
  }

  Widget _buildQueueInformation(bool compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoItem(
              title: 'Est. Wait',
              value: '$_estimatedWaitingMinutes mins',
              compact: compact,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildInfoItem(
                title: 'Patient Ahead',
                value: '$_patientsAhead',
                compact: compact,
                alignRight: true,
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
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF00827D),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF00827D),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(bool compact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        height: compact ? 44 : 48,
        child: ElevatedButton(
          onPressed: _openEstimatedWaitingTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00827D),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w600,
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
        builder: (_) => EstimatedWaitingTimeScreen(
          estimatedMinutes: _estimatedWaitingMinutes,
          patientsAhead: _patientsAhead,
          averageMinutesPerPatient:
              widget.averageMinutesPerPatient,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(double width) {
    final compact = width < 380;

    return Container(
      width: double.infinity,
      height: compact ? 66 : 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE1E9E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            index: 0,
            compact: compact,
          ),
          _buildNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_month_rounded,
            label: 'Appointments',
            index: 1,
            compact: compact,
          ),
          _buildNavItem(
            icon: Icons.format_list_bulleted,
            selectedIcon: Icons.format_list_bulleted,
            label: 'Queue',
            index: 2,
            compact: compact,
          ),
          _buildNavItem(
            icon: Icons.notifications_none_rounded,
            selectedIcon: Icons.notifications_rounded,
            label: 'Alerts',
            index: 3,
            compact: compact,
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
    final selected = _selectedBottomIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBottomIndex = index;
          });

          _handleNavigation(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: compact ? 21 : 23,
              color: selected
                  ? const Color(0xFF00827D)
                  : const Color(0xFF789090),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 8 : 9,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: selected
                    ? const Color(0xFF00827D)
                    : const Color(0xFF789090),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 2) return;

    if (index == 0) {
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    }
  }
}

// ============================================================================
// ESTIMATED WAITING TIME SCREEN
// ============================================================================

class EstimatedWaitingTimeScreen extends StatefulWidget {
  const EstimatedWaitingTimeScreen({
    super.key,
    required this.estimatedMinutes,
    required this.patientsAhead,
    required this.averageMinutesPerPatient,
  });

  final int estimatedMinutes;
  final int patientsAhead;
  final int averageMinutesPerPatient;

  @override
  State<EstimatedWaitingTimeScreen> createState() =>
      _EstimatedWaitingTimeScreenState();
}

class _EstimatedWaitingTimeScreenState
    extends State<EstimatedWaitingTimeScreen> {
  Timer? _timer;

  late int _remainingSeconds;
  late int _initialSeconds;

  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();

    _initialSeconds =
        math.max(widget.estimatedMinutes * 60, 60);

    _remainingSeconds = _initialSeconds;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (_remainingSeconds <= 1) {
          _timer?.cancel();

          setState(() {
            _remainingSeconds = 0;
          });

          _openMyTurn();
          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _remainingMinutes {
    return (_remainingSeconds / 60).ceil();
  }

  double get _progress {
    if (_initialSeconds <= 0) return 0;

    return (_remainingSeconds / _initialSeconds)
        .clamp(0.0, 1.0);
  }

  void _openMyTurn() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MyTurnScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final contentWidth = math.min(
              width - 28,
              700.0,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child: _buildContent(width),
                      ),
                    ),
                    _buildBottomNavigation(width),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(double width) {
    final compact = width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          Text(
            'Estimated Waiting Time',
            style: TextStyle(
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF063E3E),
            ),
          ),

          SizedBox(height: compact ? 72 : 92),

          Center(
            child: SizedBox(
              width: compact ? 150 : 160,
              height: compact ? 150 : 160,
              child: CustomPaint(
                painter: _WaitingCirclePainter(
                  progress: _progress,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_remainingMinutes.clamp(0, 999)} mins',
                        style: TextStyle(
                          fontSize: compact ? 25 : 27,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF00827D),
                        ),
                      ),
                      Text(
                        'left',
                        style: TextStyle(
                          fontSize: compact ? 24 : 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00827D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: compact ? 14 : 18),

          Center(
            child: Column(
              children: [
                const Text(
                  'AVG Time Per Patient',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00827D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.averageMinutesPerPatient} min',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00827D),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 28 : 36),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00827D),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildQueuePreview(),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Est. Wait: 25 mins',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00827D),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${widget.patientsAhead.toString().padLeft(2, '0')} Patient Ahead',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00827D),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 26 : 32),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _openMyTurn,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF00827D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQueuePreview() {
    const numbers = ['07', '08', '09', '10'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: numbers.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final selected = numbers[index] == '09';

          return Container(
            width: 47,
            height: 47,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF39A49E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00827D),
                width: selected ? 0 : 1.5,
              ),
            ),
            child: Text(
              numbers[index],
              style: TextStyle(
                fontSize: 18,
                fontWeight: selected
                    ? FontWeight.w900
                    : FontWeight.w500,
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

  Widget _buildBottomNavigation(double width) {
    return _queueFlowBottomNavigation(
      context: context,
      selectedIndex: _selectedBottomIndex,
      onSelected: (index) {
        setState(() {
          _selectedBottomIndex = index;
        });

        if (index == 0) {
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        }
      },
      width: width,
    );
  }
}

// ============================================================================
// MY TURN SCREEN
// ============================================================================

class MyTurnScreen extends StatefulWidget {
  const MyTurnScreen({super.key});

  @override
  State<MyTurnScreen> createState() => _MyTurnScreenState();
}

class _MyTurnScreenState extends State<MyTurnScreen> {
  static const int _totalSeconds = 5 * 60;

  Timer? _timer;
  int _remainingSeconds = _totalSeconds;

  int _selectedBottomIndex = 0;

  bool _actionCompleted = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _actionCompleted) return;

        if (_remainingSeconds <= 1) {
          _timer?.cancel();

          _goToMissedTurn();

          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _remainingTimeText {
    final minutes =
        (_remainingSeconds ~/ 60).toString();

    final seconds =
        (_remainingSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes min $seconds sec';
  }

  void _onMyWay() {
    if (_actionCompleted) return;

    _actionCompleted = true;
    _timer?.cancel();

    HealthQNotificationStore.instance.addNotification(
      title: 'Appointment Completed',
      body:
          'You confirmed that you are on your way. Your appointment has been marked as completed.',
      time: 'Just now',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Appointment completed successfully.',
        ),
      ),
    );
  }

  void _needMoreTime() {
    if (_actionCompleted) return;

    _actionCompleted = true;
    _timer?.cancel();

    _goToMissedTurn();
  }

  void _goToMissedTurn() {
    if (!mounted) return;

    _actionCompleted = true;
    _timer?.cancel();

    HealthQNotificationStore.instance.addNotification(
      title: 'Missed My Turn',
      body:
          'Your queue turn was missed because no confirmation was received within 5 minutes.',
      time: 'Just now',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MissedMyTurnScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: math.min(
                  width - 28,
                  700.0,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child: _buildContent(width),
                      ),
                    ),
                    _buildBottomNavigation(width),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(double width) {
    final compact = width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),

          Text(
            'My Turn',
            style: TextStyle(
              fontSize: compact ? 20 : 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF063E3E),
            ),
          ),

          SizedBox(height: compact ? 100 : 125),

          Center(
            child: Container(
              width: compact ? 66 : 68,
              height: compact ? 66 : 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF39A49E),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: Text(
              'Its Your Turn',
              style: TextStyle(
                fontSize: compact ? 20 : 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF063E3E),
              ),
            ),
          ),

          const SizedBox(height: 2),

          const Center(
            child: Text(
              'Please Process to consultation',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF00827D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 2),

          const Center(
            child: Text(
              'Room 03',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF00827D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          SizedBox(height: compact ? 120 : 145),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _actionCompleted ? null : _onMyWay,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF39A49E),
                  disabledBackgroundColor:
                      const Color(0xFF39A49E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'On My Way',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _actionCompleted ? null : _needMoreTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF00827D),
                  disabledBackgroundColor:
                      const Color(0xFF00827D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Need More Time',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF00827D),
                ),
                children: [
                  const TextSpan(
                    text: 'No response in ',
                  ),
                  TextSpan(
                    text: _remainingTimeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' → Position is Changed',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(double width) {
    return _queueFlowBottomNavigation(
      context: context,
      selectedIndex: _selectedBottomIndex,
      onSelected: (index) {
        setState(() {
          _selectedBottomIndex = index;
        });

        if (index == 0) {
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        }
      },
      width: width,
    );
  }
}

// ============================================================================
// MISSED MY TURN SCREEN
// ============================================================================

class MissedMyTurnScreen extends StatelessWidget {
  const MissedMyTurnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF39A49E),
                  ),
                  child: const Icon(
                    Icons.access_time_filled,
                    color: Colors.white,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Missed My Turn',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF063E3E),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your queue position has been changed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF00827D),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF00827D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WAITING TIME CIRCLE PAINTER
// ============================================================================

class _WaitingCirclePainter extends CustomPainter {
  final double progress;

  const _WaitingCirclePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2 - 10;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFD5E8E6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF007C70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final startAngle = -math.pi / 2;

    final sweepAngle =
        (2 * math.pi * progress).clamp(0.0, 2 * math.pi);

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WaitingCirclePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// QUEUE FLOW BOTTOM NAVIGATION
// ============================================================================

Widget _queueFlowBottomNavigation({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  required double width,
}) {
  final compact = width < 380;

  final items = [
    (
      Icons.home_outlined,
      Icons.home_rounded,
      'Home',
    ),
    (
      Icons.calendar_today_outlined,
      Icons.calendar_month_rounded,
      'Appointments',
    ),
    (
      Icons.format_list_bulleted,
      Icons.format_list_bulleted,
      'Queue',
    ),
    (
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
      'Alerts',
    ),
  ];

  return Container(
    width: double.infinity,
    height: compact ? 66 : 72,
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
      children: List.generate(
        items.length,
        (index) {
          final item = items[index];
          final selected =
              selectedIndex == index;

          return Expanded(
            child: InkWell(
              onTap: () {
                onSelected(index);
              },
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    selected
                        ? item.$2
                        : item.$1,
                    size: compact ? 21 : 23,
                    color: selected
                        ? const Color(0xFF00827D)
                        : const Color(0xFF789090),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    item.$3,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 8 : 9,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected
                          ? const Color(0xFF00827D)
                          : const Color(0xFF789090),
                    ),
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

// ============================================================================
// SIGNAL PAINTER
// ============================================================================

class _QueueSignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      4,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill,
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

    canvas.drawPath(path1, redPaint);

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

    canvas.drawPath(path2, redPaint);

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

    canvas.drawPath(path3, redPaint);

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

    canvas.drawPath(path4, redPaint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}