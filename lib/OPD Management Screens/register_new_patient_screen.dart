import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'opd_bottom_nav.dart';

class RegisterNewPatientScreen extends StatefulWidget {
  const RegisterNewPatientScreen({super.key});

  @override
  State<RegisterNewPatientScreen> createState() =>
      _RegisterNewPatientScreenState();
}

class _RegisterNewPatientScreenState extends State<RegisterNewPatientScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
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
    }
  }

  Future<void> _confirmRegistration() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final nic = _nicController.text.trim().toUpperCase();

    if (firstName.isEmpty || nic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least First Name and NIC.'),
        ),
      );
      return;
    }

    // User ID strictly defaults to NIC number
    final userId = nic;
    final fullName = lastName.isNotEmpty ? '$firstName $lastName' : firstName;
    final dob = _dobController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();

    setState(() => _saving = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await docRef.set({
        'userId': userId,
        'nic': nic,
        'patientId': userId,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'dob': dob,
        'email': email,
        'contactNo': contact,
        'role': 'patient',
        'registeredBy': 'OPD Staff',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: OpdColors.primary400,
          content: Text(
            'Patient $fullName registered with User ID: $userId',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Failed to save patient: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              label: 'FIRST NAME',
              hint: 'e.g. Kamal',
              controller: _firstNameController,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'LAST NAME',
              hint: 'e.g. Perera',
              controller: _lastNameController,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'DATE OF BIRTH (DOB)',
              hint: 'DD/MM/YYYY',
              controller: _dobController,
              trailingIcon: Icons.calendar_today_outlined,
              onTrailingTap: _selectDate,
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'NIC NO (USER ID)',
              hint: 'e.g. 199012345678 or 952345678V (Assigned as User ID)',
              controller: _nicController,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'GMAIL',
              hint: 'e.g. kamal.perera@gmail.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'CONTACT NO',
              hint: 'e.g. 0712345678',
              controller: _contactController,
              keyboardType: TextInputType.phone,
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
      bottomNavigationBar: const OpdBottomNav(currentIndex: 0),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
        Container(
          decoration: BoxDecoration(
            color: OpdColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: OpdColors.primary300.withValues(alpha: 0.7),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 13,
              color: OpdColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: OpdColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: InputBorder.none,
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
        ),
      ],
    );
  }
}
