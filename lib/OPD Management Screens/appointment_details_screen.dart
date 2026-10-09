import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'cancel_appointment_screen.dart';
import 'opd_bottom_nav.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String? appointmentId;
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
  final String? hospitalName;
  final String? hospitalCode;

  const AppointmentDetailsScreen({
    super.key,
    this.appointmentId,
    this.token = 'T-001',
    this.patientName = 'Patient Name',
    this.nic = 'NIC / Patient ID',
    this.phone = 'Contact No',
    this.department = 'General Medicine',
    this.doctor = 'Assigned Doctor',
    this.date = 'Today',
    this.timeSlot = '08:00 AM',
    this.status = 'Waiting',
    this.notes = 'Follow-up visit. Previous BP: 138/92. Requires ECG report review.',
    this.hospitalName,
    this.hospitalCode,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late String _currentStatus;
  late TextEditingController _notesController;
  bool _isSaving = false;
  bool _isEditingNotes = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _notesController = TextEditingController(
      text: widget.notes.isNotEmpty && widget.notes != 'No notes recorded.'
          ? widget.notes
          : 'Follow-up visit. Previous BP: 138/92. Requires ECG report review.',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus, {String? cancelReason}) async {
    setState(() => _isSaving = true);
    try {
      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        if (newStatus.toLowerCase() == 'confirmed') {
          final staffName = StaffAuthService.instance.currentStaff?.name;
          await BookingService.instance.confirmAppointment(
            appointmentId: widget.appointmentId!,
            staffName: staffName,
            staffHospital: widget.hospitalName,
          );
        } else if (newStatus.toLowerCase() == 'cancelled') {
          final staffName = StaffAuthService.instance.currentStaff?.name;
          await BookingService.instance.cancelAppointment(
            appointmentId: widget.appointmentId!,
            reason: cancelReason ?? 'Cancelled by OPD Management',
            staffName: staffName,
          );
        } else {
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(widget.appointmentId)
              .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      if (!mounted) return;
      setState(() => _currentStatus = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newStatus.toLowerCase() == 'cancelled'
              ? Colors.red.shade700
              : OpdColors.primary400,
          content: Text(newStatus.toLowerCase() == 'confirmed'
              ? 'Appointment Confirmed & Patient Notified!'
              : 'Status updated to: $newStatus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to update status: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _navigateToCancelScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CancelAppointmentScreen(
          appointmentId: widget.appointmentId ?? '',
          token: widget.token,
          patientName: widget.patientName,
          nic: widget.nic,
          phone: widget.phone,
          department: widget.department,
          doctor: widget.doctor,
          date: widget.date,
          timeSlot: widget.timeSlot,
          hospitalName: widget.hospitalName,
          hospitalCode: widget.hospitalCode,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _currentStatus = 'cancelled');
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);
    try {
      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .update({
          'notes': _notesController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      setState(() => _isEditingNotes = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: OpdColors.primary400,
          content: Text('Consultation notes saved to database!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to save notes: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            // Details Card - Exactly as Wireframe 1
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
                      Expanded(
                        child: Text(
                          widget.department.contains('OPD')
                              ? widget.department
                              : '${widget.department} OPD',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: OpdColors.primary500,
                          ),
                        ),
                      ),
                      _buildStatusChip(_currentStatus),
                    ],
                  ),
                  const Divider(height: 22, color: OpdColors.borderLight),

                  // Key-Value Rows (Wireframe 1)
                  _buildDetailRow('Token Number', widget.token, isToken: true),
                  _buildDetailRow('Patient Name', widget.patientName, isHighlight: true),
                  _buildDetailRow('NIC / Patient ID', widget.nic),
                  _buildDetailRow('Phone Number', widget.phone),
                  _buildDetailRow('Department', widget.department),
                  _buildDetailRow('Assigned Doctor', widget.doctor),
                  if (widget.hospitalName != null && widget.hospitalName!.isNotEmpty)
                    _buildDetailRow(
                      'Hospital',
                      widget.hospitalCode != null && widget.hospitalCode!.isNotEmpty
                          ? '${widget.hospitalName} (${widget.hospitalCode})'
                          : widget.hospitalName!,
                    ),
                  _buildDetailRow('Date', widget.date),
                  _buildDetailRow('Time Slot', widget.timeSlot),
                  if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty)
                    _buildDetailRow('Database ID', widget.appointmentId!),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Consultation Notes Card (Wireframe 1)
            Container(
              width: double.infinity,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CONSULTATION NOTES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: OpdColors.primary500,
                        ),
                      ),
                      if (!_isEditingNotes)
                        InkWell(
                          onTap: () => setState(() => _isEditingNotes = true),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Icon(Icons.edit_outlined, size: 15, color: OpdColors.primary400),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: _isSaving ? null : _saveNotes,
                          icon: const Icon(Icons.save_outlined, size: 14),
                          label: const Text('Save', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: OpdColors.primary400,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (!_isEditingNotes)
                    Text(
                      _notesController.text.trim().isNotEmpty
                          ? _notesController.text.trim()
                          : 'Follow-up visit. Previous BP: 138/92. Requires ECG report review.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: OpdColors.textDark,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12.5, color: OpdColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Enter clinical observations or notes...',
                        hintStyle: const TextStyle(fontSize: 12, color: OpdColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: OpdColors.primary400),
                        ),
                        filled: true,
                        fillColor: OpdColors.primary100.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Live Action Buttons - Exactly as Wireframe 1
            if (_currentStatus.toLowerCase() == 'waiting' ||
                _currentStatus.toLowerCase() == 'pending' ||
                _currentStatus.toLowerCase() == 'upcoming') ...[
              // Confirm Appointment Button (Solid Dark Teal)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _updateStatus('confirmed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OpdColors.primary400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Appointment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Appointment Button (Outlined Dark Teal)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _navigateToCancelScreen,
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
                    'Cancel Appointment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.primary400,
                    ),
                  ),
                ),
              ),
            ] else if (_currentStatus.toLowerCase() == 'confirmed' ||
                _currentStatus.toLowerCase() == 'in consult' ||
                _currentStatus.toLowerCase() == 'in_consult') ...[
              // Call Patient / In Consult Button (Solid Blue)
              if (_currentStatus.toLowerCase() == 'confirmed') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _updateStatus('In Consult'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Call Patient (In Consult)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Complete Appointment Button (Solid Emerald)
              if (_currentStatus.toLowerCase() == 'in consult' ||
                  _currentStatus.toLowerCase() == 'in_consult') ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : () => _updateStatus('Completed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Complete Consultation',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Cancel Appointment Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _navigateToCancelScreen,
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
                    'Cancel Appointment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.primary400,
                    ),
                  ),
                ),
              ),
            ] else if (_currentStatus.toLowerCase() == 'cancelled') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Color(0xFFB91C1C), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This appointment has been cancelled by OPD Management.',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_currentStatus.toLowerCase() == 'completed') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This appointment consultation has been completed.',
                        style: TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Confirmed';
        break;
      case 'in consult':
      case 'in_consult':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'In Consult';
        break;
      case 'completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        label = 'Completed';
        break;
      case 'cancelled':
      case 'absent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelled';
        break;
      case 'pending':
      case 'waiting':
      case 'upcoming':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Waiting';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isToken = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: OpdColors.textMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isToken ? 15 : 12.5,
                fontWeight: (isToken || isHighlight)
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: isToken
                    ? OpdColors.primary400
                    : (isHighlight
                        ? OpdColors.primary500
                        : OpdColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
