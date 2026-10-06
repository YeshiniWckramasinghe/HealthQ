import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'estimated_waiting_time_screen.dart';
import 'queue_flow_controller.dart';
import 'queue_status_screen.dart';

class NewQueueStatusScreen extends StatelessWidget {
  const NewQueueStatusScreen({
    super.key,
    required this.newQueueNumber,
  });

  final int newQueueNumber;

  List<QueuePatient> _patients() {
    final current =
        QueueFlowController.instance
            .currentQueueNumber;

    final your =
        QueueFlowController.instance
            .yourQueueNumber;

    return [
      QueuePatient(
        queueNumber:
            current.toString().padLeft(2, '0'),
        patientName: 'Patient $current',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber:
            (current + 1)
                .toString()
                .padLeft(2, '0'),
        patientName: 'Patient ${current + 1}',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber:
            your.toString().padLeft(2, '0'),
        patientName: 'You',
        doctorName: 'Dr. R. Fernando',
      ),
      QueuePatient(
        queueNumber:
            (your + 1)
                .toString()
                .padLeft(2, '0'),
        patientName: 'Patient ${your + 1}',
        doctorName: 'Dr. R. Fernando',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        QueueFlowController.instance;

    final patients = _patients();

    final current =
        controller.currentQueueNumber;

    final wait =
        controller.estimatedWaitMinutes;

    final ahead =
        controller.patientsAhead;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF1F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

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
                  horizontalPadding * 2,
              700.0,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    Expanded(
                      child:
                          SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        child:
                            _buildContent(
                          width,
                          patients,
                          current,
                          wait,
                          ahead,
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

  Widget _buildContent(
    double width,
    List<QueuePatient> patients,
    int current,
    int wait,
    int ahead,
  ) {
    final compact = width < 380;

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        0,
        4,
        0,
        14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 8 : 12,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 0,
            ),
            child: Text(
              'New Queue Status',
              style: TextStyle(
                fontSize:
                    compact ? 22 : 25,
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(0xFF063E3E),
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 8),

          _currentlyServing(
            compact,
            current,
          ),

          SizedBox(
            height: compact ? 34 : 42,
          ),

          Center(
            child: Icon(
              Icons.sensors_rounded,
              size: 34,
              color:
                  const Color(0xFFFF0000),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Your New Position',
              style: TextStyle(
                fontSize:
                    compact ? 20 : 22,
                fontWeight:
                    FontWeight.w800,
                color:
                    const Color(0xFF063E3E),
              ),
            ),
          ),

          const SizedBox(height: 2),

          Center(
            child: Text(
              '#${newQueueNumber.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize:
                    compact ? 48 : 54,
                height: 1,
                fontWeight:
                    FontWeight.w900,
                color:
                    const Color(0xFF00827D),
              ),
            ),
          ),

          SizedBox(
            height: compact ? 30 : 38,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Text(
              'Current Queue',
              style: TextStyle(
                fontSize:
                    compact ? 13 : 14,
                color:
                    const Color(0xFF00827D),
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 58,
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
                  patients.length,
              separatorBuilder:
                  (_, index) =>
                      const SizedBox(
                width: 13,
              ),
              itemBuilder:
                  (context, index) {
                final number =
                    patients[index]
                        .queueNumber;

                final isYou =
                    int.tryParse(
                          number,
                        ) ==
                        newQueueNumber;

                return Container(
                  width: 48,
                  height: 54,
                  alignment:
                      Alignment.center,
                  decoration:
                      BoxDecoration(
                    color: isYou
                        ? const Color(
                            0xFF39A49E,
                          )
                        : Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFF00827D,
                      ),
                      width:
                          isYou ? 0 : 1.6,
                    ),
                  ),
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: isYou
                          ? FontWeight.w900
                          : FontWeight.w500,
                      color: isYou
                          ? Colors.white
                          : const Color(
                              0xFF063E3E,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 22,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  'Est. Wait: $wait mins',
                  style: const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF00827D),
                  ),
                ),
                Text(
                  '$ahead Patient Ahead',
                  style: const TextStyle(
                    fontSize: 10,
                    color:
                        Color(0xFF00827D),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EstimatedWaitingTimeScreen(
                        yourQueueNumber:
                            newQueueNumber,
                        averageMinutesPerPatient:
                            QueueFlowController
                                .instance
                                .averageMinutesPerPatient,
                        patients: patients,
                      ),
                    ),
                  );
                },
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
                        BorderRadius
                            .circular(
                      24,
                    ),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentlyServing(
    bool compact,
    int current,
  ) {
    return Container(
      width: double.infinity,
      height: compact ? 116 : 118,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFF00827D),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENTLY SERVING',
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  compact ? 9 : 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
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
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    7,
                  ),
                ),
                child: Text(
                  'T-${current.toString().padLeft(3, '0')}',
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF00827D),
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Dr. R. Fernando',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
              const Text(
                'In Consult',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
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