import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'queue_flow_controller.dart';
import 'my_turn_screen.dart';

class EstimatedWaitTimeScreen extends StatefulWidget {
  const EstimatedWaitTimeScreen({
    super.key,
  });

  @override
  State<EstimatedWaitTimeScreen> createState() =>
      _EstimatedWaitTimeScreenState();
}

class _EstimatedWaitTimeScreenState
    extends State<EstimatedWaitTimeScreen> {
  final QueueFlowController _queue =
      QueueFlowController.instance;

  final ScrollController _queueScrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    _queue.startQueueFlow();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentQueue();
    });

    _queue.addListener(_queueChanged);
  }

  void _queueChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});

    if (_queue.isMyTurn) {
      _openMyTurn();
    }
  }

  void _scrollToCurrentQueue() {
    if (!_queueScrollController.hasClients) {
      return;
    }

    const itemWidth = 60.0;

    final target =
        (_queue.currentQueueNumber - 5) * itemWidth;

    _queueScrollController.animateTo(
      math.max(0, target),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _openMyTurn() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MyTurnScreen(),
      ),
    );
  }

  void _next() {
    _queue.showMyTurn();

    _openMyTurn();
  }

  @override
  void dispose() {
    _queue.removeListener(_queueChanged);
    _queueScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final contentWidth =
                math.min(width, 430.0);

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: double.infinity,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(),
                            const SizedBox(height: 28),
                            _buildWaitingCircle(),
                            const SizedBox(height: 24),
                            _buildQueueSection(),
                            const SizedBox(height: 26),
                            _buildNextButton(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomNavigation(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const Text(
      'Estimated Waiting Time',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF063A37),
      ),
    );
  }

  Widget _buildWaitingCircle() {
    final progress = _queue.waitingProgress;

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _WaitingCirclePainter(
                progress: progress,
                color: const Color(0xFF006F65),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_queue.remainingMinutes} mins',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF007A75),
                      ),
                    ),
                    const Text(
                      'left',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF007A75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'AVG Time Per Patient',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF008C87),
            ),
          ),
          Text(
            '${_queue.averageMinutesPerPatient} min',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF008C87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Queue',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF007A75),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ListView.builder(
            controller: _queueScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 50,
            itemBuilder: (context, index) {
              final number = index + 1;

              final selected =
                  number == _queue.yourQueueNumber;

              return Container(
                width: 47,
                height: 47,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF329F98)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF329F98)
                        : const Color(0xFF007A75),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF063A37),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Est. Wait: ${_queue.remainingMinutes + 13} mins',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00837E),
              ),
            ),
            Text(
              '${_queue.patientsAhead.toString().padLeft(2, '0')} Patient Ahead',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00837E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00837E),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE4EEEE),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _bottomItem(
            Icons.home_outlined,
            'Home',
            false,
          ),
          _bottomItem(
            Icons.calendar_today_outlined,
            'Appointments',
            false,
          ),
          _bottomItem(
            Icons.format_list_bulleted,
            'Queue',
            true,
          ),
          _bottomItem(
            Icons.notifications_none_outlined,
            'Alerts',
            false,
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(
    IconData icon,
    String label,
    bool selected,
  ) {
    final color = selected
        ? const Color(0xFF00837E)
        : const Color(0xFF6F8D8E);

    return SizedBox(
      width: 65,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: selected
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingCirclePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _WaitingCirclePainter({
    required this.progress,
    required this.color,
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
        math.min(size.width, size.height) / 2 - 9;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.round
      ..color = color;

    const gap = 0.55;

    final available =
        (2 * math.pi) - gap;

    final sweep = available * progress;

    final startAngle =
        -math.pi / 2 + gap / 2;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WaitingCirclePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}