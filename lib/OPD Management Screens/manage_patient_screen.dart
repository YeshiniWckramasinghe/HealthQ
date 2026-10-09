import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'opd_bottom_nav.dart';
import 'patient_inquiry_screen.dart';

class ManagePatientScreen extends StatefulWidget {
  final String? searchNic;
  final String? hospital;
  final String? hospitalCode;

  const ManagePatientScreen({
    super.key,
    this.searchNic,
    this.hospital,
    this.hospitalCode,
  });

  @override
  State<ManagePatientScreen> createState() => _ManagePatientScreenState();
}

class _ManagePatientScreenState extends State<ManagePatientScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _nicController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;

  String _gender = 'Male';
  bool _isEditing = false;
  bool _isLoading = false;
  String? _loadedDocId;

  @override
  void initState() {
    super.initState();
    final initialNic = widget.searchNic?.trim() ?? '';
    _searchController = TextEditingController(text: initialNic);
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dobController = TextEditingController();
    _nicController = TextEditingController(text: initialNic);
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();

    if (initialNic.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchPatient(initialNic);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nicController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _searchPatient([String? query]) async {
    final term = (query ?? _searchController.text).trim().toUpperCase();
    if (term.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Please enter an NIC or User ID to search'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      DocumentSnapshot<Map<String, dynamic>>? foundDoc;

      // 1. Check direct doc users/{term}
      final directDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(term)
          .get();
      if (directDoc.exists && directDoc.data() != null) {
        foundDoc = directDoc;
      }

      // 2. Query where userId == term
      if (foundDoc == null) {
        final qUser = await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: term)
            .limit(1)
            .get();
        if (qUser.docs.isNotEmpty) {
          foundDoc = qUser.docs.first;
        }
      }

      // 3. Query where nic == term
      if (foundDoc == null) {
        final qNic = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: term)
            .limit(1)
            .get();
        if (qNic.docs.isNotEmpty) {
          foundDoc = qNic.docs.first;
        }
      }

      // 4. Query contactNo or contact
      if (foundDoc == null) {
        final qPhone1 = await FirebaseFirestore.instance
            .collection('users')
            .where('contactNo', isEqualTo: term)
            .limit(1)
            .get();
        if (qPhone1.docs.isNotEmpty) {
          foundDoc = qPhone1.docs.first;
        } else {
          final qPhone2 = await FirebaseFirestore.instance
              .collection('users')
              .where('contact', isEqualTo: term)
              .limit(1)
              .get();
          if (qPhone2.docs.isNotEmpty) {
            foundDoc = qPhone2.docs.first;
          }
        }
      }

      // 5. Query email
      if (foundDoc == null) {
        final qEmail = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: term.toLowerCase())
            .limit(1)
            .get();
        if (qEmail.docs.isNotEmpty) {
          foundDoc = qEmail.docs.first;
        }
      }

      // 6. Name match fallback from recent patients
      if (foundDoc == null) {
        final recent = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'patient')
            .limit(40)
            .get();
        final match = recent.docs.where((doc) {
          final m = doc.data();
          final fn = (m['fullName'] ?? m['name'] ?? '').toString().toLowerCase();
          return fn.contains(term.toLowerCase());
        }).toList();
        if (match.isNotEmpty) {
          foundDoc = match.first;
        }
      }

      if (foundDoc != null && foundDoc.data() != null) {
        final d = foundDoc.data()!;
        _loadedDocId = foundDoc.id;

        final fullName = (d['fullName'] ?? d['name'] ?? '').toString();
        final firstName = (d['firstName'] ?? '').toString();
        final lastName = (d['lastName'] ?? '').toString();

        if (firstName.isNotEmpty) {
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
        } else if (fullName.isNotEmpty) {
          final parts = fullName.split(' ');
          _firstNameController.text = parts.first;
          _lastNameController.text =
              parts.length > 1 ? parts.sublist(1).join(' ') : '';
        } else {
          _firstNameController.text = '';
          _lastNameController.text = '';
        }

        final resolvedNic = (d['nic'] ?? d['userId'] ?? term).toString();
        _nicController.text = resolvedNic;
        _searchController.text = resolvedNic;
        _dobController.text = (d['dob'] ?? '').toString();
        _addressController.text = (d['address'] ?? '').toString();
        _emailController.text = (d['email'] ?? '').toString();
        _contactController.text =
            (d['contactNo'] ?? d['contact'] ?? d['phone'] ?? '').toString();

        final g = (d['gender'] ?? 'Male').toString();
        _gender = ['Male', 'Female', 'Other'].contains(g) ? g : 'Male';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: OpdColors.primary400,
              content: Text('Patient found: ${_firstNameController.text} (User ID: $resolvedNic)'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.orange.shade800,
              content: Text('No patient found for User ID / NIC: $term'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Search failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 5, 14),
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

  Future<void> _saveRecord() async {
    final nic = _nicController.text.trim().toUpperCase();
    if (nic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('NIC / User ID cannot be empty'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final docId = _loadedDocId ?? nic;
      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final fullName = ('$fName $lName').trim();

      final patientData = {
        'userId': nic,
        'patientId': nic,
        'nic': nic,
        'firstName': fName,
        'lastName': lName,
        'fullName': fullName.isNotEmpty ? fullName : nic,
        'name': fullName.isNotEmpty ? fullName : nic,
        'dob': _dobController.text.trim(),
        'gender': _gender,
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNo': _contactController.text.trim(),
        'contact': _contactController.text.trim(),
        'role': 'patient',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.set(
        FirebaseFirestore.instance.collection('users').doc(docId),
        patientData,
        SetOptions(merge: true),
      );
      if (docId != nic) {
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(nic),
          patientData,
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: OpdColors.primary400,
            content: Text('Patient record (User ID: $nic) updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update record: $e'),
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
              'Manage Patient Record',
              style: TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View Patient Inquiry & History',
            icon: const Icon(Icons.manage_search, color: OpdColors.white),
            onPressed: () {
              final term = _nicController.text.trim().isNotEmpty
                  ? _nicController.text.trim()
                  : _searchController.text.trim();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PatientInquiryScreen(
                    initialQuery: term.isNotEmpty ? term : null,
                    hospital: widget.hospital,
                    hospitalCode: widget.hospitalCode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(
                backgroundColor: OpdColors.primary200,
                valueColor: AlwaysStoppedAnimation<Color>(OpdColors.primary400),
              ),
              const SizedBox(height: 12),
            ],
            // Search / NIC Lookup bar
            Container(
              decoration: BoxDecoration(
                color: OpdColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: OpdColors.primary300.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (val) => _searchPatient(val),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OpdColors.primary500,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: OpdColors.primary300,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: OpdColors.primary400, size: 20),
                    onPressed: () => _searchPatient(_searchController.text),
                    tooltip: 'Search by User ID / NIC',
                  ),
                  hintText: 'Search by User ID / NIC No...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: OpdColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildField(
              label: 'FIRST NAME',
              controller: _firstNameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'LAST NAME',
              controller: _lastNameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'DOB',
              controller: _dobController,
              enabled: _isEditing,
              trailingIcon: Icons.calendar_today_outlined,
              onTrailingTap: _selectDate,
              readOnly: true,
              onTap: _selectDate,
            ),
            const SizedBox(height: 10),

            // Gender Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GENDER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: OpdColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: OpdColors.primary300.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: OpdColors.primary300,
                      ),
                      onChanged: _isEditing
                          ? (newVal) {
                              if (newVal != null) {
                                setState(() => _gender = newVal);
                              }
                            }
                          : null,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'NIC NO / USER ID',
              controller: _nicController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'ADDRESS',
              controller: _addressController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'GMAIL',
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),

            _buildField(
              label: 'CONTACT NO',
              controller: _contactController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // Action Buttons Row: Edit | Save | Cancel
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpdColors.primary400,
                        side: const BorderSide(
                          color: OpdColors.primary300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpdColors.primary400,
                        foregroundColor: OpdColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        if (_isEditing) {
                          setState(() => _isEditing = false);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpdColors.textMuted,
                        side: BorderSide(
                          color: OpdColors.borderLight,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_loadedDocId != null || _nicController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.manage_search, size: 20, color: OpdColors.primary400),
                  label: const Text(
                    'View Patient Inquiry & History',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.primary400,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: OpdColors.primary300, width: 1.2),
                    backgroundColor: OpdColors.primary100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () {
                    final term = _nicController.text.trim().isNotEmpty
                        ? _nicController.text.trim()
                        : _searchController.text.trim();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PatientInquiryScreen(
                          initialQuery: term.isNotEmpty ? term : null,
                          hospital: widget.hospital,
                          hospitalCode: widget.hospitalCode,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: widget.hospital,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
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
            color: enabled ? OpdColors.white : const Color(0xFFF9FBFA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? OpdColors.primary300.withValues(alpha: 0.7)
                  : OpdColors.borderLight,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 12,
              color: OpdColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
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
