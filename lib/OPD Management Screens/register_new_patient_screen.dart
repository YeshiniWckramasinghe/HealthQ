import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';
import 'manage_patient_screen.dart';
import 'patient_inquiry_screen.dart';

class RegisterNewPatientScreen extends StatefulWidget {
  final String? hospital;
  final String? hospitalCode;

  const RegisterNewPatientScreen({
    super.key,
    this.hospital,
    this.hospitalCode,
  });

  @override
  State<RegisterNewPatientScreen> createState() =>
      _RegisterNewPatientScreenState();
}

class _RegisterNewPatientScreenState extends State<RegisterNewPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  String _gender = 'Male';
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: OpdColors.primary400,
              onPrimary: OpdColors.white,
              onSurface: OpdColors.primary500,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _confirmRegistration() async {
    // 1. Strict validation of all required fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'All fields are required. Please fix the highlighted errors before submitting.',
          ),
        ),
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final nic = _nicController.text.trim().toUpperCase();
    final dob = _dobController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final contact = _contactController.text.trim();
    final fullName = '$firstName $lastName';
    final userId = nic;

    setState(() => _saving = true);

    try {
      // 1.5 Prepare session: ensure request.auth != null if anonymous sign in is supported
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint('Anonymous auth session prepared for OPD staff');
        } catch (authErr) {
          debugPrint('Anonymous auth attempt note: $authErr');
        }
      }

      // 2. Duplicate Detection: Check if patient with this NIC or Email already exists in users table
      final nicDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (nicDoc.exists) {
        final existing = nicDoc.data() ?? {};
        setState(() => _saving = false);
        if (mounted) {
          _showDuplicateDialog(
            title: 'Patient Already Registered',
            message:
                'A patient with NIC "$nic" is already registered in the database:\n\n'
                '• Name: ${existing['fullName'] ?? existing['firstName'] ?? 'Registered Patient'}\n'
                '• Hospital: ${existing['registeredHospital'] ?? 'Hospital'}\n'
                '• Account Status: ${existing['authLinked'] == true ? 'Online Account Active' : 'OPD Direct Record'}\n\n'
                'Please do not register this patient again to prevent duplicate records.',
            existingNic: nic,
          );
        }
        return;
      }

      // Check by email
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final existing = emailQuery.docs.first.data();
        final existingNic =
            (existing['nic'] ?? existing['userId'] ?? '').toString();
        setState(() => _saving = false);
        if (mounted) {
          _showDuplicateDialog(
            title: 'Email Already In Use',
            message:
                'The email "$email" is already registered for another patient record:\n\n'
                '• Name: ${existing['fullName'] ?? existing['firstName'] ?? 'Patient'}\n'
                '• NIC: ${existingNic.isNotEmpty ? existingNic : 'N/A'}\n\n'
                'Please provide the patient\'s unique email address.',
            existingNic: existingNic.isNotEmpty ? existingNic : null,
          );
        }
        return;
      }

      // 3. Save directly to database users table WITHOUT Firebase Auth authentication
      // (OPD staff cannot authenticate patient credentials and must remain logged in as staff)
      final effectiveHosp = (widget.hospital != null &&
              widget.hospital!.isNotEmpty)
          ? widget.hospital!
          : (StaffAuthService.instance.currentStaff?.hospital ??
              'City General Hospital');
      final effectiveCode = (widget.hospitalCode != null &&
              widget.hospitalCode!.isNotEmpty)
          ? widget.hospitalCode!
          : Hospital.resolveHospitalCode(effectiveHosp);

      final patientData = {
        'userId': userId,
        'nic': nic,
        'patientId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'gender': _gender,
        'dob': dob,
        'email': email,
        'contactNo': contact,
        'role': 'patient',
        // Flag indicating registered in-person by OPD Staff without online password
        'isRegisteredByStaff': true,
        'authLinked': false,
        'registeredBy':
            StaffAuthService.instance.currentStaff?.name ?? 'OPD Staff',
        'registeredStaffId':
            StaffAuthService.instance.currentStaff?.staffId ?? '',
        'registeredHospital': effectiveHosp,
        'registeredHospitalCode': effectiveCode,
        'emailVerified': false,
        'phoneVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(patientData);

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: OpdColors.primary400, size: 28),
              SizedBox(width: 10),
              Text('Registration Successful', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient $fullName has been registered.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'User ID / NIC: $userId\nHospital: $effectiveHosp',
                style: const TextStyle(fontSize: 12, color: OpdColors.textDark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Return to Hub'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: OpdColors.primary400,
                foregroundColor: OpdColors.white,
              ),
              icon: const Icon(Icons.manage_search, size: 18),
              label: const Text('View Patient Inquiry'),
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => PatientInquiryScreen(
                      initialQuery: userId,
                      hospital: effectiveHosp,
                      hospitalCode: effectiveCode,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission-denied') ||
          errorStr.contains('permission') ||
          errorStr.contains('insufficient permissions')) {
        _showPermissionDeniedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Failed to save patient: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showPermissionDeniedDialog() {
    const rulesSnippet = '''rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if true;
    }
    match /staff/{staffId} {
      allow read, write: if true;
    }
    match /hospitals/{hospitalId} {
      allow read, write: if true;
    }
    match /appointments/{appointmentId} {
      allow read, write: if true;
    }
    match /queues/{queueId} {
      allow read, write: if true;
    }
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Firestore Permission Denied',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: OpdColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cloud Firestore in your Firebase Console is blocking the OPD staff from saving to the "users" collection because of security rules.',
                style: TextStyle(
                    fontSize: 13, color: OpdColors.textDark, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'To fix this, update your Security Rules in Firebase Console (Firestore Database > Rules):',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCFDFE0)),
                ),
                child: const SelectableText(
                  rulesSnippet,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF007A78),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close',
                style: TextStyle(color: OpdColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: OpdColors.primary400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Rules'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: rulesSnippet));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: OpdColors.primary400,
                  content: Text(
                      'Firestore rules copied! Paste them in Firebase Console > Firestore > Rules tab.'),
                ),
              );
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog({
    required String title,
    required String message,
    String? existingNic,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: OpdColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: OpdColors.textDark,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: OpdColors.textMuted)),
          ),
          if (existingNic != null && existingNic.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OpdColors.primary400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ManagePatientScreen(
                      searchNic: existingNic,
                      hospital: widget.hospital,
                    ),
                  ),
                );
              },
              child: const Text('View in Manage Patient',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
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
              'Patient Management',
              style: TextStyle(
                color: OpdColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Register New Patient',
              style: TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OpdColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: OpdColors.primary300.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline,
                        size: 20, color: OpdColors.primary400),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All fields marked with * are required. Registered data saves directly to the hospital database without authenticating patient credentials.',
                        style: TextStyle(
                          fontSize: 11,
                          color: OpdColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 1. FIRST NAME
              _buildTextFormField(
                label: 'FIRST NAME *',
                hint: 'e.g. Kamal',
                controller: _firstNameController,
                keyboardType: TextInputType.name,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'First name is required *';
                  if (val.length < 2) {
                    return 'First name must be at least 2 characters';
                  }
                  if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val)) {
                    return 'Enter letters only';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 2. LAST NAME
              _buildTextFormField(
                label: 'LAST NAME *',
                hint: 'e.g. Perera',
                controller: _lastNameController,
                keyboardType: TextInputType.name,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Last name is required *';
                  if (val.length < 2) {
                    return 'Last name must be at least 2 characters';
                  }
                  if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val)) {
                    return 'Enter letters only';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 3. GENDER
              _buildGenderField(),

              const SizedBox(height: 12),

              // 4. DATE OF BIRTH
              _buildTextFormField(
                label: 'DATE OF BIRTH (DOB) *',
                hint: 'DD/MM/YYYY',
                controller: _dobController,
                readOnly: true,
                onTap: _selectDate,
                trailingIcon: Icons.calendar_today_outlined,
                onTrailingTap: _selectDate,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Date of birth is required *';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 5. NIC NO (USER ID)
              _buildTextFormField(
                label: 'NIC NO (USER ID) *',
                hint: 'e.g. 199012345678 or 952345678V (Assigned as User ID)',
                controller: _nicController,
                keyboardType: TextInputType.text,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'NIC number is required *';
                  if (!RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(val)) {
                    return 'Invalid NIC. Use 9 digits+V/X (old) or 12 digits (new)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 6. GMAIL
              _buildTextFormField(
                label: 'GMAIL / EMAIL *',
                hint: 'e.g. kamal.perera@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Gmail is required *';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(val)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 7. CONTACT NO
              _buildTextFormField(
                label: 'CONTACT NO *',
                hint: 'e.g. 0712345678',
                controller: _contactController,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Contact number is required *';
                  if (!RegExp(r'^(?:0|\+?94)?7[0-9]{8}$').hasMatch(val)) {
                    return 'Enter a valid Sri Lankan mobile (e.g. 07XXXXXXXX)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Confirm Registration Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _confirmRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OpdColors.primary400,
                    foregroundColor: OpdColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Registration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OpdColors.primary400,
                    side: const BorderSide(
                      color: OpdColors.primary300,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: widget.hospital,
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GENDER *',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: OpdColors.primary500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = _gender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  margin: EdgeInsets.only(
                    right: g == 'Other' ? 0 : 8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected ? OpdColors.primary400 : OpdColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? OpdColors.primary400
                          : OpdColors.primary300.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? OpdColors.white : OpdColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: OpdColors.primary500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 13,
            color: OpdColors.textDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: OpdColors.white,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12,
              color: OpdColors.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: OpdColors.primary300.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: OpdColors.primary400,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              fontSize: 11,
              color: Colors.redAccent,
              height: 1.2,
            ),
            suffixIcon: trailingIcon != null
                ? IconButton(
                    icon: Icon(
                      trailingIcon,
                      size: 18,
                      color: OpdColors.primary300,
                    ),
                    onPressed: onTrailingTap,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
