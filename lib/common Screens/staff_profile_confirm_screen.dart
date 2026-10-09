import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/staff_auth_service.dart';
import 'verification_screen.dart';

class StaffProfileConfirmScreen extends StatelessWidget {
  final StaffModel staff;

  const StaffProfileConfirmScreen({
    super.key,
    required this.staff,
  });

  bool get _isDoctor => staff.role.toLowerCase() == 'doctor';

  void _proceedToOtpVerification(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          contactNo: staff.contactNo,
          email: staff.email,
          role: staff.role,
          staffData: staff.toMap(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF007A78);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryTeal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Staff Database Verification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ================= TOP MINISTRY SHIELD & STATUS =================
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryTeal.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: primaryTeal,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'MINISTRY OF HEALTH SRI LANKA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 4),

              const Text(
                'Employee Database Record',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                'Verified employee data found in hospital database. Mandatory 2-factor OTP verification is required to access your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // ================= DATABASE VERIFIED BADGE =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB3DFD7)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: primaryTeal,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Active Employee in Hospital Database',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Registration matched in Cloud Firestore database.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2C6B67),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ================= MANDATORY OTP SECURITY BADGE =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_clock_outlined,
                      color: Color(0xFFB78103),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Mandatory OTP Verification Required',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A5D00),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'By health authority policy, a 6-digit OTP code must be verified before proceeding to your dashboard.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A5D00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ================= DETAILED EMPLOYEE PROFILE CARD =================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCFDFE0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Name + Role Header
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryTeal.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            _isDoctor
                                ? Icons.medical_services_outlined
                                : Icons.health_and_safety_outlined,
                            color: primaryTeal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryTeal,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      staff.role.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    staff.staffId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFEDF2F2)),
                    const SizedBox(height: 14),

                    // Detail items
                    _buildDetailRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Assigned Hospital',
                      value: staff.hospital.isNotEmpty ? staff.hospital : 'Hospital Not Specified',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.apartment_outlined,
                      label: 'Department / Unit',
                      value: (staff.department != null && staff.department!.isNotEmpty)
                          ? staff.department!
                          : 'General OPD',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.biotech_outlined,
                      label: 'Specialty / Clinic',
                      value: (staff.specialty != null && staff.specialty!.isNotEmpty)
                          ? staff.specialty!
                          : (_isDoctor ? 'General Medicine' : 'General Care'),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Room / Counter',
                      value: (staff.room != null && staff.room!.isNotEmpty)
                          ? staff.room!
                          : 'Not Assigned',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.email_outlined,
                      label: 'Official Email (for OTP)',
                      value: staff.email.isNotEmpty ? staff.email : 'Not Registered',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact Number (for SMS)',
                      value: staff.contactNo.isNotEmpty ? staff.contactNo : 'Not Registered',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ================= MANDATORY ACTION BUTTON =================
              // Confirm & Verify with OTP
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _proceedToOtpVerification(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified_user_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Confirm & Verify with OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cancel / Sign in as another employee
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Not your account? Return to Sign In',
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007A78)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
