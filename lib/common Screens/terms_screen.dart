import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../Patient Management Screens/home_screen.dart';
import 'login_screen.dart';
import '../Doctor Management Screens/doctor_dashboard_screen.dart';
import '../OPD Management Screens/home_dashboard_screen.dart';
import 'staff_login_screen.dart';
import '../services/staff_auth_service.dart';

class TermsScreen extends StatefulWidget {
  final String role; // 'doctor', 'nurse', or 'patient'
  final Map<String, dynamic>? staffData;

  const TermsScreen({
    super.key,
    this.role = 'patient',
    this.staffData,
  });

  /// Centralized navigation method called both from TermsScreen (upon acceptance)
  /// and from VerificationScreen (when terms were already accepted on previous logins).
  static void navigateToDestination(
    BuildContext context, {
    required String role,
    Map<String, dynamic>? staffData,
  }) {
    final cleanRole = role.toLowerCase().trim();
    if (cleanRole == 'doctor') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => DoctorDashboardScreen(
            doctorName: staffData?['name'] ?? 'Dr. S. Perera',
            staffId: staffData?['staffId'] ?? 'DOC1001-0001',
            hospital: staffData?['hospital'] ?? 'Government Hospital — Colombo',
            specialty: staffData?['specialty'] ?? 'General Medicine',
            room: staffData?['room'] ?? 'Room 01',
          ),
        ),
        (route) => false,
      );
    } else if (cleanRole == 'nurse') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeDashboardScreen(
            nurseName: staffData?['name'],
            nurseId: staffData?['staffId'],
            department: staffData?['department'],
            hospital: staffData?['hospital'],
            phone: staffData?['contactNo'],
            email: staffData?['email'],
            shift: staffData?['shift'],
            role: staffData?['role'],
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  bool get _isStaff =>
      widget.role.toLowerCase() == 'doctor' ||
      widget.role.toLowerCase() == 'nurse';

  String get _staffName =>
      widget.staffData?['name'] ??
      (widget.role.toLowerCase() == 'doctor' ? 'Medical Officer' : 'Nursing Officer');

  String get _staffId =>
      widget.staffData?['staffId'] ??
      (widget.role.toLowerCase() == 'doctor' ? 'DOC1001-0001' : 'NUR1001-0001');

  String get _hospitalName =>
      widget.staffData?['hospital'] ?? 'Government Hospital — Colombo';

  void _decline() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Decline Terms?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          _isStaff
              ? 'Acceptance of the Ministry of Health Sri Lanka Clinical Governance & Data Protection Terms is mandatory to access the hospital OPD portal. If you decline, you will be logged out.'
              : 'Acceptance of the terms is required to use the HealthQ OPD patient portal. If you decline, you will be returned to the login screen.',
          style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Review Terms'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (_isStaff) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                  (route) => false,
                );
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline & Exit'),
          ),
        ],
      ),
    );
  }

  Future<void> _accept() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text(
            'Please check the box to confirm you have read and agreed to the terms.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_isStaff) {
        final staffId = widget.staffData?['staffId']?.toString() ??
            StaffAuthService.instance.currentStaff?.staffId;
        if (staffId != null && staffId.isNotEmpty) {
          await StaffAuthService.instance.recordTermsAccepted(
            staffId: staffId,
            role: widget.role,
          );
        }
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'termsAccepted': true,
            'termsAcceptedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error saving terms acceptance: $e');
      // Continue navigation even if offline / sync delayed so staff is never trapped
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    TermsScreen.navigateToDestination(
      context,
      role: widget.role,
      staffData: widget.staffData,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF007A78);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _isStaff ? 'Staff Clinical Governance & Terms' : 'Patient Terms of Service',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryTeal,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER BANNER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: primaryTeal.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4F1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryTeal.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MINISTRY OF HEALTH SRI LANKA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isStaff
                                  ? 'Healthcare Staff Portal Terms & Conditions'
                                  : 'HealthQ OPD Patient Service Terms',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isStaff) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD6EAE7)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.role.toLowerCase() == 'doctor'
                                ? Icons.medical_services_outlined
                                : Icons.local_hospital_outlined,
                            size: 16,
                            color: primaryTeal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$_staffName ($_staffId) • $_hospitalName',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E524E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 14, color: Color(0xFFB78103)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'One-time registration requirement. Once accepted, you will proceed directly to your clinical dashboard on future logins.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A5D00),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= SCROLLABLE TERMS BODY =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _isStaff ? _buildStaffTerms() : _buildPatientTerms(),
                  ),
                ),
              ),
            ),

            // ================= BOTTOM AGREEMENT & BUTTONS =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox row
                  InkWell(
                    onTap: () {
                      setState(() => _agreedToTerms = !_agreedToTerms);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (val) {
                                setState(() => _agreedToTerms = val ?? false);
                              },
                              activeColor: primaryTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isStaff
                                  ? 'I have read, understood, and agree to strictly comply with the Ministry of Health Sri Lanka Clinical Governance, Data Protection, and Information Security Terms.'
                                  : 'I have read, understood, and agree to the HealthQ OPD Service Terms and Privacy Agreement.',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary500,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Actions row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _decline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gray600,
                            side: const BorderSide(color: Color(0xFFCFD8DC)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: (_agreedToTerms && !_isSubmitting) ? _accept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFB0D5D3),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Accept & Proceed',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStaffTerms() {
    return [
      _sectionHeader(
        number: '1',
        title: 'Statutory Authority & Institutional Scope',
        icon: Icons.account_balance_outlined,
      ),
      _sectionParagraph(
        'This electronic outpatient department (OPD) queue and clinical management portal operates under the statutory authority of the Ministry of Health (MOH) Sri Lanka. Access is strictly restricted to verified healthcare professionals (Medical Officers, Consultants, and Nursing Officers) registered with the Sri Lanka Medical Council (SLMC) or Sri Lanka Nursing Council (SLNC).',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '2',
        title: 'Two-Factor Authentication & Credential Confidentiality',
        icon: Icons.lock_outline,
      ),
      _sectionParagraph(
        'Your designated Staff ID, official password, and two-factor authentication (SMS/Email OTP) credentials are strictly confidential and non-transferable. You must never disclose your credentials or permit unauthorized staff or trainees to operate under your login session. Always lock your terminal or log out when leaving consultation rooms or triage stations.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '3',
        title: 'Patient Privacy & Sri Lanka Data Protection Act (PDPA No. 9 of 2022)',
        icon: Icons.privacy_tip_outlined,
      ),
      _sectionParagraph(
        'All patient electronic medical records (EMR/EHR), triage observations, vital signs, demographic identifiers, and diagnostic histories are classified as confidential health data. In compliance with the Personal Data Protection Act No. 9 of 2022 (Sri Lanka), viewing records of patients not under your active clinical care, capturing screen photographs, or exporting health data to personal devices is strictly prohibited and punishable by law.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '4',
        title: 'Clinical Documentation Integrity & Real-Time Record Keeping',
        icon: Icons.edit_note_outlined,
      ),
      _sectionParagraph(
        'All patient diagnoses, vital signs entries, triage urgency gradings, consultation notes, and queue status transitions must be recorded truthfully, accurately, and contemporaneously during the patient encounter. Falsification, retrospective unauthorized alteration, or intentional misrepresentation of clinical data constitutes gross professional misconduct.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '5',
        title: 'Electronic Prescribing & Essential Medicines Formulary',
        icon: Icons.medication_outlined,
      ),
      _sectionParagraph(
        'Medical Officers agree to prescribe strictly within authorized clinical scopes, conforming to the National List of Essential Medicines (NLEM) Sri Lanka and institutional drug formularies. Prescriptions issued electronically through authenticated accounts carry full legal and clinical accountability.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '6',
        title: 'OPD Queue Management & Impartial Triage Protocols',
        icon: Icons.people_outline,
      ),
      _sectionParagraph(
        'Queue allocation and patient calling must strictly adhere to verified triage categories (Emergency/Resuscitation, Urgent, Semi-Urgent, Routine). Healthcare personnel must not bypass, manipulate, or grant unfair prioritization outside established clinical emergencies. Any patient presenting with red-flag symptoms must be routed immediately to the Emergency Treatment Unit (ETU) or resuscitation area.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '7',
        title: 'Shift Rosters, Room Allocation & Attendance',
        icon: Icons.calendar_today_outlined,
      ),
      _sectionParagraph(
        'Staff members must activate queue consultation and patient calling solely during rostered shift hours (Morning, Evening, Night) and in assigned OPD rooms. Temporary handover of triage or consultation duties must be formally recorded with the OPD Medical Officer-in-Charge or Nursing Sister.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '8',
        title: 'Continuous System Audit Trail & Information Security',
        icon: Icons.history_toggle_off_outlined,
      ),
      _sectionParagraph(
        'Every clinical search, record inspection, status change, and prescription generated within this portal is irrevocably logged with user Staff ID and server timestamps. These audit logs may be reviewed at any time by Hospital Administration, the Ministry of Health, or statutory inquiry boards.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '9',
        title: 'Disciplinary Action & Legal Accountability',
        icon: Icons.gavel_outlined,
      ),
      _sectionParagraph(
        'Failure to comply with these terms, breaches of patient confidentiality, or unauthorized alteration of health records will result in immediate suspension of portal privileges, referral to the Public Service Commission (PSC) under Establishment Code provisions, and formal reporting to the SLMC / SLNC for disciplinary and legal action.',
      ),
    ];
  }

  List<Widget> _buildPatientTerms() {
    return [
      _sectionHeader(
        number: '1',
        title: 'Acceptance of Patient Portal Services',
        icon: Icons.check_circle_outline,
      ),
      _sectionParagraph(
        'By accessing the HealthQ OPD Patient Portal, you agree to comply with system terms and Ministry of Health guidelines. This platform allows you to view hospital clinic appointments, track live queue tokens, and view consultation progress.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '2',
        title: 'Personal Health Information Privacy',
        icon: Icons.privacy_tip_outlined,
      ),
      _sectionParagraph(
        'Your registration information, appointment history, and queue tokens are safeguarded in accordance with the Sri Lanka Personal Data Protection Act No. 9 of 2022. You are responsible for maintaining the privacy of your mobile number and login credentials.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '3',
        title: 'Appointments, Token Allocation & Clinic Etiquette',
        icon: Icons.schedule_outlined,
      ),
      _sectionParagraph(
        'Queue tokens and estimated consultation times are dynamic approximations based on clinic flow. Patients are advised to arrive at the OPD waiting area prior to their token window. Fair queue progression is maintained by triage nursing staff.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '4',
        title: 'Emergency Medical Care Advisory',
        icon: Icons.emergency_outlined,
      ),
      _sectionParagraph(
        'The HealthQ OPD system is for non-critical outpatient scheduling and triage. If you experience acute symptoms (severe chest pain, shortness of breath, severe trauma, loss of consciousness), proceed immediately to the hospital Emergency Treatment Unit (ETU) without waiting in the OPD queue.',
      ),
      const SizedBox(height: 14),

      _sectionHeader(
        number: '5',
        title: 'Fair System Usage & Accuracy of Information',
        icon: Icons.verified_user_outlined,
      ),
      _sectionParagraph(
        'Users must provide accurate personal details (NIC, contact numbers) and refrain from booking frivolous or duplicate appointments. Any fraudulent usage may result in account restriction.',
      ),
    ];
  }

  Widget _sectionHeader({
    required String number,
    required String title,
    required IconData icon,
  }) {
    const primaryTeal = Color(0xFF007A78);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4F1),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryTeal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: primaryTeal),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionParagraph(String body) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 4),
      child: Text(
        body,
        style: const TextStyle(
          color: Color(0xFF4A5568),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }
}