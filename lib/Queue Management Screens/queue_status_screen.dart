import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    return _patientsAhead * widget.averageMinutesPerPatient;
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
        separatorBuilder: (_, __) => const SizedBox(width: 13),
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
                  color: const Color(0xFF00827D).withOpacity(0.18),
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
          onPressed: () {
            _moveToNextPatient();
          },
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

  void _moveToNextPatient() {
    if (widget.patients.isEmpty) return;

    final nextIndex =
        (_currentlyServingIndex + 1) % widget.patients.length;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          return QueueStatusScreen(
            yourQueueNumber: widget.yourQueueNumber,
            currentServingIndex: nextIndex,
            averageMinutesPerPatient:
                widget.averageMinutesPerPatient,
            patients: widget.patients,
          );
        },
      ),
    );
  }

  int get _currentlyServingIndex {
    return widget.currentServingIndex;
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
    // Queue screen is already open.
    if (index == 2) return;

    // These will be connected to your existing screens
    // after we see the current HomeScreen navigation code.
    //
    // For now we only change the selected navigation item.
  }
}

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
      ..moveTo(center.dx - 9, center.dy - 8)
      ..quadraticBezierTo(
        center.dx - 16,
        center.dy,
        center.dx - 9,
        center.dy + 8,
      );

    canvas.drawPath(path1, redPaint);

    final path2 = Path()
      ..moveTo(center.dx + 9, center.dy - 8)
      ..quadraticBezierTo(
        center.dx + 16,
        center.dy,
        center.dx + 9,
        center.dy + 8,
      );

    canvas.drawPath(path2, redPaint);

    final path3 = Path()
      ..moveTo(center.dx - 16, center.dy - 14)
      ..quadraticBezierTo(
        center.dx - 27,
        center.dy,
        center.dx - 16,
        center.dy + 14,
      );

    canvas.drawPath(path3, redPaint);

    final path4 = Path()
      ..moveTo(center.dx + 16, center.dy - 14)
      ..quadraticBezierTo(
        center.dx + 27,
        center.dy,
        center.dx + 16,
        center.dy + 14,
      );

    canvas.drawPath(path4, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}