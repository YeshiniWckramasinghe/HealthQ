import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'my_turn_screen.dart';
import 'queue_status_screen.dart';

class EstimatedWaitingTimeScreen extends StatefulWidget {
  const EstimatedWaitingTimeScreen({
    super.key,
    required this.yourQueueNumber,
    required this.averageMinutesPerPatient,
    required this.patients,
  });

  final int yourQueueNumber;
  final int averageMinutesPerPatient;
  final List<QueuePatient> patients;

  @override
  State<EstimatedWaitingTimeScreen> createState() =>
      _EstimatedWaitingTimeScreenState();
}

class _EstimatedWaitingTimeScreenState
    extends State<EstimatedWaitingTimeScreen> {
  Timer? _timer;

  late int _remainingSeconds;

  late int _estimatedMinutes;

  int get _patientsAhead {
    int count = 0;

    for (final patient in widget.patients) {
      final number = int.tryParse(patient.queueNumber);

      if (number != null &&
          number < widget.yourQueueNumber &&
          patient.status.toLowerCase() != 'completed') {
        count++;
      }
    }

    return count;
  }

  int get _initialMinutes {
    if (_patientsAhead == 0) {
      return 2;
    }

    return math.max(
      12,
      _patientsAhead * widget.averageMinutesPerPatient,
    );
  }

  @override
  void initState() {
    super.initState();

    _estimatedMinutes = _initialMinutes;

    _remainingSeconds = _estimatedMinutes * 60;

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (_remainingSeconds <= 0) {
          _timer?.cancel();
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
    if (_estimatedMinutes <= 0) return 0;

    return (_remainingSeconds /
            (_estimatedMinutes * 60))
        .clamp(0.0, 1.0);
  }

  String get _queueText {
    return widget.yourQueueNumber
        .toString()
        .padLeft(2, '0');
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
                        physics:
                            const BouncingScrollPhysics(),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            0,
                            4,
                            0,
                            14,
                          ),
                          child: _buildContent(width),
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

  Widget _buildContent(double width) {
    final compact = width < 380;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(height: compact ? 8 : 12),

        Text(
          'Estimated Waiting Time',
          style: TextStyle(
            fontSize: compact ? 22 : 25,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF063E3E),
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: compact ? 70 : 90),

        _buildTimerCircle(compact),

        SizedBox(height: compact ? 12 : 14),

        Center(
          child: Text(
            'AVG Time Per Patient',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: const Color(0xFF00827D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Center(
          child: Text(
            '${widget.averageMinutesPerPatient} min',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: const Color(0xFF00827D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        SizedBox(height: compact ? 26 : 30),

        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'Current Queue',
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF00827D),
            ),
          ),
        ),

        SizedBox(height: compact ? 12 : 14),

        _buildQueueScroller(compact),

        SizedBox(height: compact ? 18 : 20),

        _buildQueueInformation(compact),

        SizedBox(height: compact ? 22 : 30),

        _buildNextButton(compact),
      ],
    );
  }

  Widget _buildTimerCircle(bool compact) {
    return Center(
      child: SizedBox(
        width: compact ? 150 : 160,
        height: compact ? 150 : 160,
        child: CustomPaint(
          painter: _WaitingTimePainter(
            progress: _progress,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '$_remainingMinutes mins',
                  style: TextStyle(
                    fontSize: compact ? 24 : 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00827D),
                  ),
                ),
                Text(
                  'left',
                  style: TextStyle(
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00827D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueScroller(bool compact) {
    return SizedBox(
      height: compact ? 58 : 62,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount: widget.patients.length,
        separatorBuilder: (_, index) =>
            const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final patient = widget.patients[index];

          final number =
              int.tryParse(patient.queueNumber);

          final isYourNumber =
              number == widget.yourQueueNumber;

          return Container(
            width: compact ? 48 : 48,
            height: compact ? 48 : 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isYourNumber
                  ? const Color(0xFF39A49E)
                  : Colors.white,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color:
                    const Color(0xFF00827D),
                width:
                    isYourNumber ? 0 : 1.6,
              ),
            ),
            child: Text(
              patient.queueNumber,
              style: TextStyle(
                fontSize: compact ? 18 : 19,
                fontWeight: isYourNumber
                    ? FontWeight.w900
                    : FontWeight.w500,
                color: isYourNumber
                    ? Colors.white
                    : const Color(0xFF063E3E),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueueInformation(bool compact) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Est. Wait: $_estimatedMinutes mins',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: const Color(0xFF00827D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$_patientsAhead Patient Ahead',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: const Color(0xFF00827D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(bool compact) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        height: compact ? 44 : 48,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MyTurnScreen(
                  yourQueueNumber:
                      widget.yourQueueNumber,
                ),
              ),
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

  Widget _buildBottomNavigation(double width) {
    final compact = width < 380;

    return Container(
      width: double.infinity,
      height: compact ? 66 : 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE1E9E8),
          ),
        ),
      ),
      child: Row(
        children: [
          _navItem(
            Icons.home_outlined,
            'Home',
            compact,
          ),
          _navItem(
            Icons.calendar_today_outlined,
            'Appointments',
            compact,
          ),
          _navItem(
            Icons.format_list_bulleted,
            'Queue',
            compact,
          ),
          _navItem(
            Icons.notifications_none_rounded,
            'Alerts',
            compact,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool compact,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: compact ? 21 : 23,
            color: const Color(0xFF789090),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 8 : 9,
              color: const Color(0xFF789090),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingTimePainter extends CustomPainter {
  final double progress;

  _WaitingTimePainter({
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
        math.min(size.width, size.height) / 2 - 8;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE2ECEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF00827D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final sweepAngle =
        2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WaitingTimePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}