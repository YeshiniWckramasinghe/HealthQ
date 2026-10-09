import 'package:flutter/material.dart';

import 'new_queue_status_screen.dart';
import 'queue_flow_controller.dart';

class MissedMyTurnScreen extends StatelessWidget {
  const MissedMyTurnScreen({
    super.key,
  });

  void _rejoin(BuildContext context) {
    final newPosition =
        QueueFlowController.instance
            .generateNewQueuePosition();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewQueueStatusScreen(
          newQueueNumber: newPosition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return Center(
              child: SizedBox(
                width:
                    width < 600 ? width : 700,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          _buildContent(
                        width,
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

  Widget _buildContent(double width) {
    final compact = width < 380;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 8 : 12,
          ),

          Text(
            'Missed My Turn',
            style: TextStyle(
              fontSize: compact ? 22 : 25,
              fontWeight: FontWeight.w800,
              color:
                  const Color(0xFF063E3E),
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(
            height: compact ? 130 : 150,
          ),

          Center(
            child: CustomPaint(
              size: const Size(72, 72),
              painter:
                  _WarningPainter(),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              'You Missed Your Turn',
              style: TextStyle(
                fontSize: compact ? 20 : 21,
                fontWeight: FontWeight.w800,
                color:
                    const Color(0xFF063E3E),
              ),
            ),
          ),

          const SizedBox(height: 2),

          Center(
            child: Text(
              "Don't Worry, You Can Rejoin The Queue",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color:
                    const Color(0xFF00827D),
              ),
            ),
          ),

          SizedBox(
            height: compact ? 115 : 130,
          ),

          _button(
            title: 'Rejoin',
            color: const Color(0xFF39A49E),
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _button(
            title: 'Contact Support',
            color: const Color(0xFF00827D),
            onTap: () {},
          ),

          const SizedBox(height: 10),

          _button(
            title: 'Cancel',
            color: const Color(0xFF00827D),
            onTap: () {},
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'No response in 5 min → Position is Changed',
              style: TextStyle(
                fontSize: 10,
                color:
                    Color(0xFF00827D),
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: title == 'Rejoin'
                ? () => _rejoin(context)
                : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
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
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(
    double width,
  ) {
    final compact = width < 380;

    return Container(
      height: compact ? 66 : 72,
      color: Colors.white,
      child: Row(
        children: [
          _nav(Icons.home_outlined, 'Home'),
          _nav(
            Icons.calendar_today_outlined,
            'Appointments',
          ),
          _nav(
            Icons.format_list_bulleted,
            'Queue',
          ),
          _nav(
            Icons.notifications_none_rounded,
            'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _nav(
    IconData icon,
    String label,
  ) {
    return Expanded(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color:
                const Color(0xFF789090),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color:
                  Color(0xFF789090),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color =
          const Color(0xFF39A49E)
      ..style =
          PaintingStyle.fill;

    final path = Path();

    path.moveTo(
      size.width / 2,
      2,
    );

    path.lineTo(
      size.width - 5,
      size.height - 4,
    );

    path.lineTo(
      5,
      size.height - 4,
    );

    path.close();

    canvas.drawPath(path, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight:
              FontWeight.w900,
        ),
      ),
      textDirection:
          TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 -
            textPainter.width / 2,
        size.height / 2 -
            textPainter.height / 2 +
            7,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}