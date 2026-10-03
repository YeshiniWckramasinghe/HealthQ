import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/staff_auth_service.dart';
import 'login_screen.dart';
import 'staff_login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String role; // 'doctor', 'nurse', or 'patient'
  final String? email;
  final String? contactNo;
  final Map<String, dynamic>? staffData;

  const ResetPasswordScreen({
    super.key,
    this.role = 'patient',
    this.email,
    this.contactNo,
    this.staffData,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool get _isStaff => widget.role == 'doctor' || widget.role == 'nurse' || widget.staffData != null;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text.trim();
    setState(() => _isLoading = true);

    try {
      if (_isStaff) {
        // Staff password update in database
        final staffId = widget.staffData?['staffId']?.toString() ?? widget.email ?? '';
        final success = await StaffAuthService.instance.updatePassword(
          staffIdOrEmail: staffId,
          newPassword: newPass,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.primary400,
                content: Text('Staff password updated successfully! Please sign in with your new password.'),
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text('Failed to update staff password. Please try again.'),
              ),
            );
          }
        }
      } else {
        // Patient password update in Cloud Firestore 'users' & Firebase Auth
        bool updated = false;

        // 1. Update in Firestore users collection
        if (widget.email != null && widget.email!.isNotEmpty) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.email!.trim())
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.set({
              'password': newPass,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            updated = true;
          }
        }

        if (!updated && widget.contactNo != null && widget.contactNo!.isNotEmpty) {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('contactNo', isEqualTo: widget.contactNo!.trim())
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.set({
              'password': newPass,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            updated = true;
          }
        }

        // 2. If logged in through Firebase Auth, update password
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          try {
            await currentUser.updatePassword(newPass);
          } catch (e) {
            debugPrint('FirebaseAuth updatePassword note: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.primary400,
              content: Text('Password reset successfully! Please sign in with your new password.'),
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error updating password: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _isStaff ? const Color(0xFF007A78) : AppColors.primary400;
    final accountLabel = _isStaff
        ? '${widget.staffData?['name'] ?? 'Staff Member'} (${widget.staffData?['staffId'] ?? widget.role.toUpperCase()})'
        : (widget.email ?? widget.contactNo ?? 'Patient Account');

    return Scaffold(
      backgroundColor: _isStaff ? const Color(0xFFF3F7F7) : AppColors.primary100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset_outlined,
                      color: primaryColor,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isStaff ? AppColors.primary500 : AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your identity has been verified via OTP. Please enter and confirm your new password below.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Verified Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB3DFD7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF007A78), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verified for: $accountLabel',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007A78),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // New Password Field
                Text(
                  'NEW PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter a new password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'At least 6 characters',
                    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
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
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Confirm Password Field
                Text(
                  'CONFIRM NEW PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your new password';
                    if (v != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Re-enter your new password',
                    hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.gray400,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
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
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Save New Password Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
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
                        : const Text(
                            'Save New Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.gray500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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