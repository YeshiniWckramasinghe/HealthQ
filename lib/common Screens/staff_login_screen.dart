import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/staff_auth_service.dart';
import 'staff_forgot_password_screen.dart';
import 'staff_profile_confirm_screen.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffIdController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedHospital = 'Government Hospital — Colombo';
  String _selectedRole = 'Doctor'; // 'Doctor' or 'Nurse'
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _hospitals = const [
    'Government Hospital — Colombo',
    'National Hospital of Sri Lanka',
    'Colombo South Teaching Hospital',
    'Teaching Hospital Kandy',
    'Karapitiya Teaching Hospital',
  ];

  @override
  void initState() {
    super.initState();
    // Seed staff into Firestore in background if not already seeded
    StaffAuthService.instance.seedDefaultStaffIfNeeded();
    _staffIdController.text = 'DOC1001-0001';
    _passwordController.text = 'Password123!';
  }

  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleStaffConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final staff = await StaffAuthService.instance.authenticateStaff(
        hospital: _selectedHospital,
        staffId: _staffIdController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole.toLowerCase(),
      );

      if (!mounted) return;

      if (staff != null) {
        // Open page to display that data for that staff person
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StaffProfileConfirmScreen(staff: staff),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              'Employee not registered in database or invalid credentials for $_selectedRole. Please check your Staff ID and Password.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Authentication error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // ================= TOP SHIELD BADGE =================
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF007A78).withValues(alpha: 0.25),
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
                    color: Color(0xFF007A78),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),

                // SUBTITLE: MINISTRY OF HEALTH SRI LANKA
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

                // TITLE: Staff Portal Sign In
                const Text(
                  'Staff Portal Sign In',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 28),

                // ================= SELECT HOSPITAL =================
                _buildFieldLabel('SELECT HOSPITAL'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCFDFE0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedHospital,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.gray500,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary500,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _hospitals.map((h) {
                        return DropdownMenuItem<String>(
                          value: h,
                          child: Text(
                            h,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedHospital = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ================= STAFF ID =================
                _buildFieldLabel('STAFF ID'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _staffIdController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Staff ID is required';
                    }
                    return null;
                  },
                  decoration: _inputDecoration(
                    hintText: 'e.g. DOC1001-0001 or NUR1002-0011',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 18),

                // ================= PASSWORD =================
                _buildFieldLabel('PASSWORD'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                  decoration: _inputDecoration(
                    hintText: '••••••••••••',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ================= SELECT ROLE =================
                _buildFieldLabel('SELECT ROLE'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCFDFE0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRole,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.gray500,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary500,
                        fontWeight: FontWeight.w500,
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Doctor',
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 18,
                                color: Color(0xFF007A78),
                              ),
                              SizedBox(width: 10),
                              Text('Doctor'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Nurse',
                          child: Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 18,
                                color: Color(0xFF007A78),
                              ),
                              SizedBox(width: 10),
                              Text('Nurse'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedRole = val;
                            if (val == 'Doctor' &&
                                _staffIdController.text.startsWith('NUR')) {
                              _staffIdController.text = 'DOC1001-0001';
                            } else if (val == 'Nurse' &&
                                _staffIdController.text.startsWith('DOC')) {
                              _staffIdController.text = 'NUR1002-0011';
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ================= CONFIRM BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStaffConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A78),
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
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Confirm',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ================= FORGOT PASSWORD =================
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffForgotPasswordScreen(
                            initialStaffId: _staffIdController.text.trim(),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF007A78),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ================= BACK TO PATIENT LOGIN =================
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.gray500),
                    label: const Text(
                      'Back to Patient Login',
                      style: TextStyle(
                        color: AppColors.gray500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.gray600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary300, size: 20),
      suffixIcon: suffixIcon,
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
        borderSide: const BorderSide(color: Color(0xFF007A78), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
