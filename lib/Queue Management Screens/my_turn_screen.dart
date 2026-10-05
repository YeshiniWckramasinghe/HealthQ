import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'queue_flow_controller.dart';
import 'missed_turn_screen.dart';

class MyTurnScreen extends StatefulWidget {
  const MyTurnScreen({
    super.key,
  });

  @override
  State<MyTurnScreen> createState() =>
      _MyTurnScreenState();
}

class _MyTurnScreenState extends State<MyTurnScreen> {
  final QueueFlowController _queue =
      QueueFlowController.instance;

  @override
  void initState() {
    super.initState();

    if (!_queue.isMyTurn &&
        !_queue.isMissedTurn &&
        !_queue.isCompleted) {
      _queue.showMyTurn();
    }

    _queue.addListener(_queueChanged);
  }

  void _queueChanged() {
    if (!mounted) {
      return;
    }

    if (_queue.isMissedTurn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MissedTurnScreen(),
        ),
      );
      return;
    }

    setState(() {});
  }

  void _onMyWay() {
    _queue.onMyWay();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void _needMoreTime() {
    _queue.needMoreTime();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MissedTurnScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _queue.removeListener(_queueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                math.min(constraints.maxWidth, 430.0);

            return Center(
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Turn',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFF063A37),
                                ),
                              ),
                              const SizedBox(height: 140),
                              _buildTurnContent(),
                            ],
                          ),
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

  Widget _buildTurnContent() {
    return Column(
      children: [
        Center(
          child: Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFF2E9690),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Its Your Turn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF063A37),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Please Process to consultation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF00837E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(
          'Room 03',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF00837E),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 126),
        _buildButtons(),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: _onMyWay,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF329F98),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'On My Way',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton(
            onPressed: _needMoreTime,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF00837E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Need More Time',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'No response in 5 min → Position is Changed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF00837E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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