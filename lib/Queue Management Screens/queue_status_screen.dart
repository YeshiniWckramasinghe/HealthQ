import 'package:flutter/material.dart';

import 'check_in_screen.dart';

class QueueStatusScreen extends StatelessWidget {
  const QueueStatusScreen({
    super.key,
    required this.appointment,
  });

  final CheckInAppointment appointment;

  static const Color background =
      Color(0xFFF0F7F6);

  static const Color primary =
      Color(0xFF007471);

  static const Color dark =
      Color(0xFF063A37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: true,
        title: const Text(
          'Queue Status',
          style: TextStyle(
            color: dark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // -------------------------------------------------------
              // TEMPORARY QUEUE ICON
              // -------------------------------------------------------

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  size: 55,
                  color: primary,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'You are checked in!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: dark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your queue status will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // -------------------------------------------------------
              // APPOINTMENT INFO
              // -------------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment',
                      style: TextStyle(
                        color: dark,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _infoRow(
                      'Patient',
                      appointment.patient,
                    ),

                    _infoRow(
                      'Hospital',
                      appointment.hospital,
                    ),

                    _infoRow(
                      'Doctor',
                      appointment.doctor,
                    ),

                    _infoRow(
                      'Date',
                      appointment.date,
                    ),

                    _infoRow(
                      'Session',
                      appointment.session,
                    ),

                    _infoRow(
                      'Queue No.',
                      appointment
                              .estimatedQueueNumber
                              .isEmpty
                          ? '-'
                          : appointment
                              .estimatedQueueNumber,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Queue Status screen will be designed\n'
                'according to your high-fidelity screenshot.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 13,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: dark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}