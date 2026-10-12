import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';

class OpdQueuePatientDetailsScreen extends StatefulWidget {
  final String? appointmentId;
  final String token;
  final String patientName;
  final String nic;
  final String phone;
  final String department;
  final String doctor;
  final String scheduledTime;
  final String currentStatus;
  final String? hospital;
  final String? hospitalCode;

  const OpdQueuePatientDetailsScreen({
    super.key,
    this.appointmentId,
    required this.token,
    required this.patientName,
    required this.nic,
    required this.phone,
    required this.department,
    required this.doctor,
    required this.scheduledTime,
    required this.currentStatus,
    this.hospital,
    this.hospitalCode,
  });

  @override
  State<OpdQueuePatientDetailsScreen> createState() =>
      _OpdQueuePatientDetailsScreenState();
}

class _OpdQueuePatientDetailsScreenState
    extends State<OpdQueuePatientDetailsScreen> {
  static const Color headerTeal = Color(0xFF006760);
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color bgMint = Color(0xFFF3F8F7);

  static const List<String> _statusOptions = [
    'Waiting',
    'Next',
    'In Consult',
    'Completed',
    'Absent',
    'Cancelled',
  ];

  late String _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Normalize initial status to match one of the options
    final norm = _statusOptions.firstWhere(
      (opt) => opt.toLowerCase() == widget.currentStatus.toLowerCase(),
      orElse: () => 'Waiting',
    );
    _selectedStatus = norm;
  }

  Future<void> _handleConfirmStatusUpdate() async {
    setState(() => _isUpdating = true);

    try {
      final staffName = StaffAuthService.instance.currentStaff?.name;
      final staffId = StaffAuthService.instance.currentStaff?.staffId;

      if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointmentId)
            .set({
          'status': _selectedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByStaff': staffName,
          'updatedByStaffId': staffId,
        }, SetOptions(merge: true));
      } else {
        final effectiveHosp = widget.hospital ?? 'City General Hospital';
        final effectiveHospCode = widget.hospitalCode ?? Hospital.resolveHospitalCode(effectiveHosp);
        final tokenNum = int.tryParse(widget.token.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;

        await FirebaseFirestore.instance.collection('appointments').add({
          'patientName': widget.patientName,
          'name': widget.patientName,
          'nic': widget.nic,
          'contactNo': widget.phone,
          'phone': widget.phone,
          'department': widget.department,
          'speciality': widget.department,
          'doctor': widget.doctor,
          'doctorName': widget.doctor,
          'hospital': effectiveHosp,
          'hospitalName': effectiveHosp,
          'hospitalCode': effectiveHospCode,
          'hospitalId': effectiveHospCode,
          'session': widget.scheduledTime,
          'timeSlot': widget.scheduledTime,
          'token': widget.token,
          'queueNo': tokenNum,
          'status': _selectedStatus,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedByStaff': staffName,
          'updatedByStaffId': staffId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: primaryTeal,
          content: Text(
            'Queue status for ${widget.patientName} (${widget.token}) updated to "$_selectedStatus"',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return the updated status to the queue management screen
      Navigator.of(context).pop(_selectedStatus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Failed to update status: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    Color border;

    switch (status.toLowerCase()) {
      case 'in consult':
      case 'in_consult':
        bg = const Color(0xFFE6F4F1);
        fg = primaryTeal;
        border = primaryTeal;
        break;
      case 'next':
        bg = const Color(0xFFEBF5FF);
        fg = const Color(0xFF2563EB);
        border = const Color(0xFFBFDBFE);
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        border = const Color(0xFFBBF7D0);
        break;
      case 'absent':
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        break;
      case 'waiting':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        border = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required Widget valueWidget,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              Flexible(child: valueWidget),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 0.8,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  Widget _buildDetailTextRow(String label, String value, {bool isBold = true}) {
    return _buildDetailRow(
      label: label,
      valueWidget: Text(
        value.isNotEmpty ? value : '—',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: const Color(0xFF0F2E2C),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgMint,
      appBar: AppBar(
        backgroundColor: headerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Queue Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Patient Verification Profile',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= SECTION: PATIENT DETAILS =================
              const Text(
                'Patient Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2E2C),
                ),
              ),
              const SizedBox(height: 10),

              // Patient Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Token Number row with bordered pill
                    _buildDetailRow(
                      label: 'Token Number',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryTeal,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          widget.token,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ),
                    _buildDetailTextRow('Patient Name', widget.patientName),
                    _buildDetailTextRow('NIC Number', widget.nic),
                    _buildDetailTextRow('Contact No', widget.phone),
                    _buildDetailTextRow('Department', widget.department),
                    _buildDetailTextRow('Assigned Doctor', widget.doctor),
                    _buildDetailTextRow('Scheduled Time', widget.scheduledTime),
                    // Current Status row
                    _buildDetailRow(
                      label: 'Current Status',
                      valueWidget: _buildStatusBadge(widget.currentStatus),
                      showDivider: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ================= SECTION: UPDATE STATUS =================
              const Text(
                'UPDATE STATUS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 8),

              // Status Dropdown selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryTeal,
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: primaryTeal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2E2C),
                    ),
                    items: _statusOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: opt == 'In Consult'
                                    ? primaryTeal
                                    : opt == 'Next'
                                        ? const Color(0xFF2563EB)
                                        : opt == 'Waiting'
                                            ? const Color(0xFFD97706)
                                            : opt == 'Completed'
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(opt),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatus = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Confirm Status Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleConfirmStatusUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Status Update',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFF94A3B8), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 2,
        hospital: widget.hospital,
      ),
    );
  }
}
