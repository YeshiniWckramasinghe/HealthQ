import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'doctor_bottom_nav.dart';

class RequestDetailsScreen extends StatelessWidget {
  final AvailabilityRequestModel request;

  const RequestDetailsScreen({
    super.key,
    required this.request,
  });

  void _onCancelRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: Text('Are you sure you want to cancel request ${request.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No, Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              DoctorService.instance.cancelRequest(request.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request ${request.id} has been cancelled.'),
                  backgroundColor: AppColors.primary400,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: AppColors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = request.status.toLowerCase() == 'pending';

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
                    'Request Details',
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
                    // Status Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPending ? 'Pending Review' : request.status,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFB45309),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Main Details Card
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
                          _buildDetailRow('Request ID', request.id),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow('Doctor', request.doctorName),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow('Target Date', request.targetDate),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow('Time Slot', request.timeSlot),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            'Current Status',
                            request.currentStatus,
                            color: const Color(0xFF047857),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow(
                            'Requested Status',
                            request.requestedStatus,
                            color: const Color(0xFFDC2626),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          const Text(
                            'Reason for Change',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.reason,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary500,
                            ),
                          ),
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _buildDetailRow('Submitted Time', request.submittedTime),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Request Progress Stepper
                    const Text(
                      'Request Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Step 1: Submitted
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.primary400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 36,
                              color: AppColors.primary400,
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submitted successfully',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              request.submittedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Step 2: Review
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Pending medical superintendent review',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'In Progress',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Cancel Request Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _onCancelRequest(context),
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                        label: const Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary500,
          ),
        ),
      ],
    );
  }
}
