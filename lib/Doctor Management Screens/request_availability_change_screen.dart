import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'request_submitted_screen.dart';
import 'doctor_bottom_nav.dart';

class RequestAvailabilityChangeScreen extends StatefulWidget {
  const RequestAvailabilityChangeScreen({super.key});

  @override
  State<RequestAvailabilityChangeScreen> createState() => _RequestAvailabilityChangeScreenState();
}

class _RequestAvailabilityChangeScreenState extends State<RequestAvailabilityChangeScreen> {
  String _selectedDate = '20 September 2026';
  String _selectedTimeSlot = '11:00 - 12:00';
  String _requestedStatus = 'Unavailable'; // 'Available' or 'Unavailable'
  final TextEditingController _reasonController = TextEditingController(
    text: 'Attending a medical conference',
  );

  final List<String> _dates = [
    '20 September 2026',
    '21 September 2026',
    '22 September 2026',
    '23 September 2026',
  ];

  final List<String> _timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final createdReq = DoctorService.instance.submitAvailabilityRequest(
      targetDate: _selectedDate,
      timeSlot: _selectedTimeSlot,
      requestedStatus: _requestedStatus,
      reason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : 'Schedule adjustment request',
      currentStatus: _requestedStatus == 'Unavailable' ? 'Available' : 'Unavailable',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RequestSubmittedScreen(request: createdReq),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = DoctorService.instance.profile.name;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Request Change',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE CONTENT =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Dropdown
                          _buildFieldLabel('Date'),
                          _buildDropdownField(
                            value: _selectedDate,
                            items: _dates,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDate = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Time Slot Dropdown
                          _buildFieldLabel('Time Slot'),
                          _buildDropdownField(
                            value: _selectedTimeSlot,
                            items: _timeSlots,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTimeSlot = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Requested Status Toggle
                          _buildFieldLabel('Requested Status'),
                          Container(
                            height: 46,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _requestedStatus = 'Available'),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _requestedStatus == 'Available'
                                            ? AppColors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _requestedStatus == 'Available'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        'Available',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _requestedStatus == 'Available'
                                              ? const Color(0xFF047857)
                                              : AppColors.gray400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setState(() => _requestedStatus = 'Unavailable'),
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _requestedStatus == 'Unavailable'
                                            ? AppColors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _requestedStatus == 'Unavailable'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.04),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        'Unavailable',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _requestedStatus == 'Unavailable'
                                              ? const Color(0xFFDC2626)
                                              : AppColors.gray400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reason / Note
                          _buildFieldLabel('Reason / Note'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: _reasonController,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter reason for change...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Current Status
                          _buildFieldLabel('Current Status'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      size: 16,
                                      color: AppColors.gray400,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _requestedStatus == 'Unavailable' ? 'Available' : 'Unavailable',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: _requestedStatus == 'Unavailable'
                                            ? const Color(0xFF047857)
                                            : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Change Summary Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Summary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$doctorName requests $_selectedTimeSlot on $_selectedDate to be marked as $_requestedStatus.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Send Request Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary400,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Request to Hospital Staff',
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
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Info footer
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.gray400,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your request will be reviewed by hospital staff. The availability status will change only after approval.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.gray500,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary400),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
