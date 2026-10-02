import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'opd_bottom_nav.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final String token;
  final String patientName;
  final String nic;
  final String phone;
  final String department;
  final String doctor;
  final String date;
  final String timeSlot;
  final String status;
  final String notes;

  const AppointmentDetailsScreen({
    super.key,
    this.token = 'T-003',
    this.patientName = 'Suresh Jayawardena',
    this.nic = '952345678V',
    this.phone = '071-234-5678',
    this.department = 'General Medicine',
    this.doctor = 'Dr. R. Fernando',
    this.date = '16 Sep 2026',
    this.timeSlot = '09:00 AM',
    this.status = 'Waiting',
    this.notes =
        'Follow-up visit. Previous BP: 138/92. Requires ECG report review.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      appBar: AppBar(
        backgroundColor: OpdColors.primary400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OpdColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Appointments Management',
              style: TextStyle(
                color: OpdColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Appointment Details',
              style: TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OpdColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: OpdColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: OpdColors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Department & Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$department OPD',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: OpdColors.primary500,
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const Divider(height: 22, color: OpdColors.borderLight),

                  // Key-Value Rows
                  _buildDetailRow('Token Number', token, isToken: true),
                  _buildDetailRow('Patient Name', patientName, isHighlight: true),
                  _buildDetailRow('NIC / Patient ID', nic),
                  _buildDetailRow('Phone Number', phone),
                  _buildDetailRow('Department', department),
                  _buildDetailRow('Assigned Doctor', doctor),
                  _buildDetailRow('Date', date),
                  _buildDetailRow('Time Slot', timeSlot),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Consultation Notes Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OpdColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: OpdColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: OpdColors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONSULTATION NOTES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: OpdColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OpdColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Appointment Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: OpdColors.primary400,
                      content: Text('Appointment $token confirmed!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: OpdColors.primary400,
                  foregroundColor: OpdColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Confirm Appointment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Cancel Appointment Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appointment cancelled.'),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: OpdColors.primary400,
                  side: const BorderSide(
                    color: OpdColors.primary300,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Cancel Appointment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
      bottomNavigationBar: const OpdBottomNav(currentIndex: 1),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isToken = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: OpdColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: (isToken || isHighlight)
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: isToken
                  ? OpdColors.primary300
                  : isHighlight
                      ? OpdColors.primary500
                      : OpdColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case 'In Consult':
        bg = OpdColors.statusInConsultBg;
        fg = OpdColors.statusInConsultText;
        border = OpdColors.statusInConsultBorder;
        break;
      case 'Absent':
        bg = OpdColors.statusAbsentBg;
        fg = OpdColors.statusAbsentText;
        border = OpdColors.statusAbsentBorder;
        break;
      case 'Waiting':
      default:
        bg = OpdColors.statusWaitingBg;
        fg = OpdColors.statusWaitingText;
        border = OpdColors.statusWaitingBorder;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
