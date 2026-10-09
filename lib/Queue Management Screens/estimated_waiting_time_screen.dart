import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'queue_status_screen.dart';
import '../Patient Management Screens/home_screen.dart';
import '../Patient Management Screens/appointments_tab.dart';

class EstimatedWaitingTimeScreen extends StatefulWidget {
  final int yourQueueNumber;
  final int averageMinutesPerPatient;
  final List<QueuePatient> patients;

  const EstimatedWaitingTimeScreen({
    super.key,
    required this.yourQueueNumber,
    required this.averageMinutesPerPatient,
    required this.patients,
  });

  @override
  State<EstimatedWaitingTimeScreen> createState() =>
      _EstimatedWaitingTimeScreenState();
}

class _EstimatedWaitingTimeScreenState
    extends State<EstimatedWaitingTimeScreen> {
  Timer? _timer;

  int _remainingSeconds = 0;
  int _estimatedMinutes = 0;
  int _patientsAhead = 0;

  int _initialMinutes = 0;
  double _progress = 1.0;

  String _queueText = '';

  @override
  void initState() {
    super.initState();
    _calculateWaitingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateWaitingTime() {
    _patientsAhead = widget.patients
        .where((patient) =>
            int.tryParse(patient.queueNumber) != null &&
            int.parse(patient.queueNumber) < widget.yourQueueNumber)
        .length;

    _estimatedMinutes =
        _patientsAhead * widget.averageMinutesPerPatient;

    _initialMinutes = _estimatedMinutes;
    _remainingSeconds = _estimatedMinutes * 60;

    _progress = _initialMinutes > 0 ? 1.0 : 0.0;

    if (_patientsAhead > 0) {
      _queueText =
          'There are $_patientsAhead patients ahead of you.';
    } else {
      _queueText = 'You are next in the queue.';
    }
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 0) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingSeconds--;


          if (_initialMinutes > 0) {
            _progress =
                _remainingSeconds /
                    (_initialMinutes * 60);

            _progress = _progress.clamp(0.0, 1.0);
          } else {
            _progress = 0.0;
          }
        });
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
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
                    : math.min(
                        width * 0.08,
                        70.0,
                      );

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
                    _buildBottomNavigation(
                      context,
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

  Widget _buildContent(double width) {
    final compact = width < 380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -------------------------------------------------------------
        // HEADER + BACK BUTTON
        // Same style as Check In screen
        // -------------------------------------------------------------
        Row(
          children: [
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const QueueStatusScreen(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF063A37),
                    size: 19,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Estimated Waiting Time',
              style: TextStyle(
                fontSize: compact ? 22 : 25,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF063E3E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // WAITING TIME CIRCLE
        Center(
          child: SizedBox(
            width: compact ? 190 : 220,
            height: compact ? 190 : 220,
            child: CustomPaint(
              painter: _WaitingTimePainter(
                progress: _progress,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: compact ? 34 : 40,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF063E3E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Estimated Wait',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6D8585),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // AVERAGE TIME
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Color(0xFF0A7771),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Time Per Patient',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF718585),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.averageMinutesPerPatient} minutes',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF063E3E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // CURRENT QUEUE
        const Text(
          'Current Queue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF063E3E),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics:
                const BouncingScrollPhysics(),
            itemCount: widget.patients.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final patient = widget.patients[index];
              final number = int.tryParse(patient.queueNumber) ?? 0;
              final isYourNumber =
                number == widget.yourQueueNumber;

              return Container(
                width: 52,
                decoration: BoxDecoration(
                  color: isYourNumber
                      ? const Color(0xFF0A7771)
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: isYourNumber
                        ? const Color(0xFF0A7771)
                        : const Color(0xFFDCE8E6),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isYourNumber
                          ? Colors.white
                          : const Color(0xFF063E3E),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        // QUEUE INFORMATION
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF0A7771),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _queueText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF315858),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // NEXT BUTTON
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyTurnScreen(
                    yourQueueNumber:
                        widget.yourQueueNumber,
                    patients: widget.patients,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF0A7771),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    double width,
  ) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context,
            icon: Icons.home_outlined,
            label: 'Home',
            selected: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const HomeScreen(),
                ),
              );
            },
          ),
          _navItem(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Appointments',
            selected: false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AppointmentsTab(),
                ),
              );
            },
          ),
          _navItem(
            context,
            icon: Icons.confirmation_number_outlined,
            label: 'Queue',
            selected: true,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const QueueStatusScreen(),
                ),
              );
            },
          ),
          _navItem(
            context,
            icon: Icons.notifications_none,
            label: 'Alerts',
            selected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected
        ? const Color(0xFF0A7771)
        : const Color(0xFF829292);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
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
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFDCEBE8);

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0A7771);

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