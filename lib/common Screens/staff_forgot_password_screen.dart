import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/staff_auth_service.dart';
import 'verification_screen.dart';

class StaffForgotPasswordScreen extends StatefulWidget {
  final String? initialStaffId;

  const StaffForgotPasswordScreen({
    super.key,
    this.initialStaffId,
  });

  @override
  State<StaffForgotPasswordScreen> createState() =>
      _StaffForgotPasswordScreenState();
}

class _StaffForgotPasswordScreenState extends State<StaffForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStaffId != null && widget.initialStaffId!.isNotEmpty) {
      _staffIdController.text = widget.initialStaffId!;
    }
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _handleProceedToVerification() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _staffIdController.text.trim();
    setState(() => _isLoading = true);

    try {
      final staff = await StaffAuthService.instance.findStaff(input);

      if (!mounted) return;

      if (staff != null) {
        // Navigate to VerificationScreen with mobile or gmail verification required
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              contactNo: staff.contactNo,
              email: staff.email,
              role: staff.role,
              staffData: staff.toMap(),
              isPasswordReset: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Staff member not found in database. Please verify your Staff ID or official email.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Top Shield Badge
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
                  'Staff Password Recovery',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Enter your official Staff ID or Email. Mobile or Gmail verification is required to verify your identity before resetting your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Security Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB3DFD7)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_clock_outlined, color: primaryTeal, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '2-Step Security: An OTP verification code will be sent to your registered Mobile Number or Gmail.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Staff ID Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'STAFF ID OR OFFICIAL EMAIL',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _staffIdController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Staff ID or Email is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. DOC1001-0001 or NUR1002-0011',
                    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
                    prefixIcon: const Icon(Icons.badge_outlined, color: primaryTeal, size: 20),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCFDFE0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCFDFE0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryTeal, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Continue to Verification Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleProceedToVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Verification',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.gray500),
                  label: const Text(
                    'Back to Staff Portal',
                    style: TextStyle(
                      color: AppColors.gray500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
