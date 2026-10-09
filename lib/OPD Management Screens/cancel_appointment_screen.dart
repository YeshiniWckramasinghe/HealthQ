import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';

class CancelAppointmentScreen extends StatefulWidget {
  final String appointmentId;
  final String token;
  final String patientName;
  final String? nic;
  final String? phone;
  final String? department;
  final String? doctor;
  final String? date;
  final String? timeSlot;
  final String? hospitalName;
  final String? hospitalCode;

  const CancelAppointmentScreen({
    super.key,
    required this.appointmentId,
    required this.token,
    required this.patientName,
    this.nic,
    this.phone,
    this.department,
    this.doctor,
    this.date,
    this.timeSlot,
    this.hospitalName,
    this.hospitalCode,
  });

  @override
  State<CancelAppointmentScreen> createState() => _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState extends State<CancelAppointmentScreen> {
  static const List<String> _cancellationReasons = [
    'Patient Absent / No Show',
    'Patient Requested Cancellation',
    'Doctor Unavailable / Rescheduled',
    'Emergency / Hospital Operational Reason',
    'Duplicate Booking',
    'Other',
  ];

  late String _selectedReason;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _cancellationReasons.first;
    _notesController = TextEditingController(
      text:
          'Patient called and informed they won\'t be able to visit due to emergency personal matters. Requested rescheduling for next week.',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancellation() async {
    setState(() => _isSubmitting = true);
    try {
      final staffName = StaffAuthService.instance.currentStaff?.name;
      await BookingService.instance.cancelAppointment(
        appointmentId: widget.appointmentId,
        reason: _selectedReason,
        cancelNotes: _notesController.text.trim(),
        staffName: staffName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Appointment ${widget.token} cancelled for ${widget.patientName}. Patient has been notified.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to cancel appointment: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      appBar: AppBar(
        backgroundColor: OpdColors.primary400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Appointments Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Cancel Appointment',
              style: TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warning',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You are about to cancel the appointment for ${widget.patientName} (Token ${widget.token}). This action cannot be undone.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFB91C1C),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Reason For Cancellation Section
            const Text(
              'REASON FOR CANCELLATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: OpdColors.primary500,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: OpdColors.primary400,
                  width: 1.4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: OpdColors.primary400,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: OpdColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReason = val);
                    }
                  },
                  items: _cancellationReasons.map((reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: OpdColors.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // More Details / Notes Section
            const Text(
              'MORE DETAILS / NOTES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: OpdColors.primary500,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _notesController,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 13,
                color: OpdColors.textDark,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText:
                    'Patient called and informed they won\'t be able to visit due to emergency personal matters. Requested rescheduling for next week.',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: OpdColors.textMuted,
                  height: 1.4,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: OpdColors.primary400,
                    width: 1.4,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: OpdColors.primary500,
                    width: 2.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirmCancellation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OpdColors.primary400,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Cancellation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OpdColors.primary400,
                  side: const BorderSide(
                    color: OpdColors.primary400,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary400,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 1,
        hospital: widget.hospitalName,
      ),
    );
  }
}
