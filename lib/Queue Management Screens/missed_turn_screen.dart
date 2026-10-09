import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'queue_flow_controller.dart';

class MissedTurnScreen extends StatelessWidget {
  const MissedTurnScreen({
    super.key,
  });

  void _rejoinQueue(BuildContext context) {
    QueueFlowController.instance.reset();

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
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
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Missed My Turn',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w800,
                                color:
                                    Color(0xFF063A37),
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration:
                                    const BoxDecoration(
                                  color:
                                      Color(0xFF2E9690),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_off,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'You Missed Your Turn',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.w800,
                                  color:
                                      Color(0xFF063A37),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'Your queue position has been changed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Color(0xFF00837E),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _rejoinQueue(context),
                                style:
                                    ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(
                                    0xFF00837E,
                                  ),
                                  foregroundColor:
                                      Colors.white,
                                  elevation: 0,
                                  shape:
                                      const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Rejoin Queue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop();
                                },
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      const Color(
                                    0xFF00837E,
                                  ),
                                  side:
                                      const BorderSide(
                                    color: Color(
                                      0xFF00837E,
                                    ),
                                  ),
                                  shape:
                                      const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Contact Reception',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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
          _item(
            Icons.home_outlined,
            'Home',
          ),
          _item(
            Icons.calendar_today_outlined,
            'Appointments',
          ),
          _item(
            Icons.format_list_bulleted,
            'Queue',
          ),
          _item(
            Icons.notifications_none_outlined,
            'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String label,
  ) {
    return SizedBox(
      width: 65,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF6F8D8E),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              color: Color(0xFF6F8D8E),
            ),
          ),
        ],
      ),
    );
  }
}