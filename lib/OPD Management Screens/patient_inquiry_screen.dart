import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'manage_patient_screen.dart';
import 'register_new_patient_screen.dart';
import 'appointment_details_screen.dart';

class PatientInquiryScreen extends StatefulWidget {
  final String? initialQuery;
  final String? hospital;
  final String? hospitalCode;
  final String? nurseName;
  final String? nurseId;
  final String? department;

  const PatientInquiryScreen({
    super.key,
    this.initialQuery,
    this.hospital,
    this.hospitalCode,
    this.nurseName,
    this.nurseId,
    this.department,
  });

  @override
  State<PatientInquiryScreen> createState() => _PatientInquiryScreenState();
}

class _PatientInquiryScreenState extends State<PatientInquiryScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // Selected Patient Details
  Map<String, dynamic>? _patientData;
  String? _patientDocId;

  // Multiple search results if name or partial match found
  List<DocumentSnapshot<Map<String, dynamic>>> _searchResults = [];

  String get _effectiveHospital {
    if (widget.hospital != null && widget.hospital!.trim().isNotEmpty) {
      return widget.hospital!.trim();
    }
    if (StaffAuthService.instance.currentStaff?.hospital != null &&
        StaffAuthService.instance.currentStaff!.hospital.trim().isNotEmpty) {
      return StaffAuthService.instance.currentStaff!.hospital.trim();
    }
    return 'City General Hospital';
  }

  String get _effectiveHospitalCode {
    if (widget.hospitalCode != null && widget.hospitalCode!.trim().isNotEmpty) {
      return widget.hospitalCode!.trim();
    }
    return Hospital.resolveHospitalCode(_effectiveHospital);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Comprehensive Multi-Field Patient Search Logic
  // ---------------------------------------------------------------------------
  Future<void> _performSearch([String? rawQuery]) async {
    final query = (rawQuery ?? _searchController.text).trim();
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _patientData = null;
        _patientDocId = null;
        _searchResults = [];
        _errorMessage = 'Please enter an NIC, User ID, Mobile number, or Name to search.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      final upper = query.toUpperCase();
      final lower = query.toLowerCase();
      final usersRef = FirebaseFirestore.instance.collection('users');

      // 1. Direct Document ID lookup (e.g. users/{NIC_OR_USERID})
      final docById = await usersRef.doc(upper).get();
      if (docById.exists && docById.data() != null) {
        _selectPatient(docById.id, docById.data()!);
        return;
      }

      // 2. Exact match queries by userId or nic
      final qUser = await usersRef.where('userId', isEqualTo: upper).limit(5).get();
      if (qUser.docs.isNotEmpty) {
        if (qUser.docs.length == 1) {
          _selectPatient(qUser.docs.first.id, qUser.docs.first.data());
          return;
        } else {
          _showMultipleResults(qUser.docs);
          return;
        }
      }

      final qNic = await usersRef.where('nic', isEqualTo: upper).limit(5).get();
      if (qNic.docs.isNotEmpty) {
        if (qNic.docs.length == 1) {
          _selectPatient(qNic.docs.first.id, qNic.docs.first.data());
          return;
        } else {
          _showMultipleResults(qNic.docs);
          return;
        }
      }

      // 3. Contact Number search (supports 071..., 71..., +94...)
      final qContact1 = await usersRef.where('contactNo', isEqualTo: query).limit(5).get();
      if (qContact1.docs.isNotEmpty) {
        if (qContact1.docs.length == 1) {
          _selectPatient(qContact1.docs.first.id, qContact1.docs.first.data());
          return;
        } else {
          _showMultipleResults(qContact1.docs);
          return;
        }
      }

      final qContact2 = await usersRef.where('contact', isEqualTo: query).limit(5).get();
      if (qContact2.docs.isNotEmpty) {
        if (qContact2.docs.length == 1) {
          _selectPatient(qContact2.docs.first.id, qContact2.docs.first.data());
          return;
        } else {
          _showMultipleResults(qContact2.docs);
          return;
        }
      }

      // 4. Email search
      final qEmail = await usersRef.where('email', isEqualTo: lower).limit(5).get();
      if (qEmail.docs.isNotEmpty) {
        if (qEmail.docs.length == 1) {
          _selectPatient(qEmail.docs.first.id, qEmail.docs.first.data());
          return;
        } else {
          _showMultipleResults(qEmail.docs);
          return;
        }
      }

      // 5. Name match: retrieve recent patient records and filter locally
      final recentPatients = await usersRef
          .where('role', isEqualTo: 'patient')
          .limit(60)
          .get();

      final matchingDocs = recentPatients.docs.where((doc) {
        final d = doc.data();
        final fn = (d['fullName'] ?? d['name'] ?? '').toString().toLowerCase();
        final first = (d['firstName'] ?? '').toString().toLowerCase();
        final last = (d['lastName'] ?? '').toString().toLowerCase();
        final nic = (d['nic'] ?? d['userId'] ?? '').toString().toLowerCase();
        final phone = (d['contactNo'] ?? d['contact'] ?? '').toString();

        return fn.contains(lower) ||
            first.contains(lower) ||
            last.contains(lower) ||
            nic.contains(lower) ||
            phone.contains(query);
      }).toList();

      if (matchingDocs.isNotEmpty) {
        if (matchingDocs.length == 1) {
          _selectPatient(matchingDocs.first.id, matchingDocs.first.data());
        } else {
          _showMultipleResults(matchingDocs);
        }
        return;
      }

      // 6. Secondary check in appointments collection (in case patient was booked directly)
      final apptQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('nic', isEqualTo: upper)
          .limit(1)
          .get();

      if (apptQuery.docs.isNotEmpty) {
        final appt = apptQuery.docs.first.data();
        final fallbackPatient = {
          'userId': appt['userId'] ?? upper,
          'nic': upper,
          'fullName': appt['patientName'] ?? 'OPD Patient',
          'firstName': appt['patientName'] ?? 'OPD Patient',
          'contactNo': appt['contact'] ?? '',
          'dob': appt['dob'] ?? '',
          'gender': appt['gender'] ?? 'Not Specified',
          'registeredHospital': appt['hospitalName'] ?? _effectiveHospital,
          'isRegisteredByStaff': true,
          'role': 'patient',
        };
        _selectPatient(upper, fallbackPatient);
        return;
      }

      // If nothing found
      setState(() {
        _patientData = null;
        _patientDocId = null;
        _searchResults = [];
        _errorMessage = 'No patient found matching "$query".';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Search error: $e';
        _patientData = null;
        _patientDocId = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectPatient(String docId, Map<String, dynamic> data) {
    setState(() {
      _patientDocId = docId;
      _patientData = data;
      _searchResults = [];
      _errorMessage = null;
      _searchController.text = (data['nic'] ?? data['userId'] ?? docId).toString();
    });
  }

  void _showMultipleResults(List<DocumentSnapshot<Map<String, dynamic>>> docs) {
    setState(() {
      _searchResults = docs;
      _patientData = null;
      _patientDocId = null;
      _errorMessage = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Helper: Age calculation from DOB (e.g. DD/MM/YYYY or YYYY-MM-DD)
  // ---------------------------------------------------------------------------
  String _calculateAge(String? dob) {
    if (dob == null || dob.trim().isEmpty) return '';
    try {
      DateTime? birthDate;
      if (dob.contains('/')) {
        final parts = dob.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            birthDate = DateTime(y, m, d);
          }
        }
      } else if (dob.contains('-')) {
        birthDate = DateTime.tryParse(dob);
      }

      if (birthDate != null) {
        final now = DateTime.now();
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        return age >= 0 ? '$age Yrs' : '';
      }
    } catch (_) {}
    return '';
  }

  // ---------------------------------------------------------------------------
  // Add Clinical Note / Prescription Dialog
  // ---------------------------------------------------------------------------
  Future<void> _showAddClinicalNoteDialog() async {
    if (_patientData == null) return;

    final docNameCtrl = TextEditingController(
      text: widget.nurseName != null ? 'Dr. / Staff ${widget.nurseName}' : 'Attending OPD Medical Officer',
    );
    final diagnosisCtrl = TextEditingController();
    final prescriptionCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: OpdColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Record Clinical Note / Prescription',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: docNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prescribing Doctor / Staff',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: diagnosisCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis / Observation',
                    hintText: 'e.g. Acute Upper Respiratory Tract Infection',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: prescriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Prescription & Medication',
                    hintText: 'e.g. Paracetamol 500mg TDS x 3 days\nAmoxicillin 500mg TDS x 5 days',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: instructionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Special Advice / Instructions',
                    hintText: 'e.g. Take after meals, plenty of fluids, follow-up if fever persists.',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OpdColors.primary400,
                      foregroundColor: OpdColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Note to Patient Record'),
                    onPressed: () async {
                      if (prescriptionCtrl.text.trim().isEmpty && diagnosisCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a diagnosis or prescription.')),
                        );
                        return;
                      }

                      final targetDoc = _patientDocId ?? (_patientData!['nic'] ?? _patientData!['userId']).toString();

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(targetDoc)
                            .collection('clinical_notes')
                            .add({
                          'doctor': docNameCtrl.text.trim(),
                          'diagnosis': diagnosisCtrl.text.trim(),
                          'prescription': prescriptionCtrl.text.trim(),
                          'instructions': instructionsCtrl.text.trim(),
                          'hospital': _effectiveHospital,
                          'hospitalCode': _effectiveHospitalCode,
                          'createdAt': FieldValue.serverTimestamp(),
                          'recordedBy': widget.nurseName ?? 'OPD Staff',
                        });

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: OpdColors.primary400,
                              content: Text('Clinical note recorded successfully.'),
                            ),
                          );
                          setState(() {});
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('Failed to save note: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          children: [
            const Text(
              'Patient Inquiry',
              style: TextStyle(
                color: OpdColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'History, Appointments & Prescriptions • $_effectiveHospital',
              style: const TextStyle(
                color: OpdColors.white,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Register New Patient',
            icon: const Icon(Icons.person_add_alt_1, color: OpdColors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegisterNewPatientScreen(
                    hospital: _effectiveHospital,
                    hospitalCode: _effectiveHospitalCode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          _buildSearchBox(),

          // Body Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: OpdColors.primary400),
                  )
                : _searchResults.isNotEmpty
                    ? _buildMultipleResultsList()
                    : _patientData != null
                        ? _buildPatientInquiryView()
                        : _buildIdleOrEmptyState(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Search Field
  // ---------------------------------------------------------------------------
  Widget _buildSearchBox() {
    return Container(
      color: OpdColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: OpdColors.primary100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: OpdColors.primary300.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search, color: OpdColors.primary400, size: 22),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Enter NIC, User ID, Mobile, or Patient Name...',
                      hintStyle: TextStyle(fontSize: 12, color: OpdColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (val) => _performSearch(val),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: OpdColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _patientData = null;
                        _patientDocId = null;
                        _hasSearched = false;
                        _searchResults = [];
                        _errorMessage = null;
                      });
                    },
                  ),
                InkWell(
                  onTap: () => _performSearch(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: OpdColors.primary400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        color: OpdColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Multiple Matches Selection View
  // ---------------------------------------------------------------------------
  Widget _buildMultipleResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OpdColors.primary500.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_outline, color: OpdColors.primary500, size: 20),
              const SizedBox(width: 8),
              Text(
                'Found ${_searchResults.length} matching patients. Select one:',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: OpdColors.primary500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map((doc) {
          final d = doc.data() ?? {};
          final name = (d['fullName'] ?? d['name'] ?? 'Unknown Name').toString();
          final nic = (d['nic'] ?? d['userId'] ?? doc.id).toString();
          final phone = (d['contactNo'] ?? d['contact'] ?? 'No contact').toString();
          final gender = (d['gender'] ?? 'Not Specified').toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: OpdColors.borderLight),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: gender == 'Female'
                    ? Colors.pink.shade50
                    : OpdColors.primary200.withValues(alpha: 0.2),
                child: Icon(
                  gender == 'Female' ? Icons.female : Icons.male,
                  color: gender == 'Female' ? Colors.pink : OpdColors.primary400,
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text('NIC: $nic • Mobile: $phone\nGender: $gender'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: OpdColors.primary400,
                  foregroundColor: OpdColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _selectPatient(doc.id, d),
                child: const Text('View Inquiry', style: TextStyle(fontSize: 11)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Active Patient Inquiry View (Header Profile + 3 Tabs)
  // ---------------------------------------------------------------------------
  Widget _buildPatientInquiryView() {
    final d = _patientData!;
    final name = (d['fullName'] ?? d['name'] ?? 'Patient Name').toString();
    final nic = (d['nic'] ?? d['userId'] ?? _patientDocId ?? 'N/A').toString();
    final phone = (d['contactNo'] ?? d['contact'] ?? 'N/A').toString();
    final email = (d['email'] ?? 'Not provided').toString();
    final gender = (d['gender'] ?? 'Male').toString();
    final dob = (d['dob'] ?? '').toString();
    final ageStr = _calculateAge(dob);
    final isStaffRegistered = d['isRegisteredByStaff'] == true;
    final isAuthLinked = d['authLinked'] == true || d['authUid'] != null;
    final hospitalName = (d['registeredHospital'] ?? _effectiveHospital).toString();

    return Column(
      children: [
        // Patient Profile Overview Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: OpdColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: OpdColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: OpdColors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: gender == 'Female'
                        ? Colors.pink.shade50
                        : OpdColors.primary200.withValues(alpha: 0.15),
                    child: Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: gender == 'Female' ? Colors.pink : OpdColors.primary400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: OpdColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: gender == 'Female'
                                    ? Colors.pink.shade50
                                    : OpdColors.primary100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ageStr.isNotEmpty ? '$ageStr • $gender' : gender,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: gender == 'Female' ? Colors.pink : OpdColors.primary400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // NIC with 1-Tap Copy
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: OpdColors.gray100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'NIC: ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: OpdColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    nic,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: OpdColors.primary400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: nic));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied NIC $nic to clipboard'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: OpdColors.primary300,
                              ),
                            ),
                            const Spacer(),
                            // Account Type Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAuthLinked
                                    ? Colors.blue.shade50
                                    : isStaffRegistered
                                        ? Colors.teal.shade50
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isAuthLinked
                                      ? Colors.blue.shade200
                                      : OpdColors.primary200,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isAuthLinked
                                    ? 'Online Portal'
                                    : 'OPD Direct Record',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isAuthLinked ? Colors.blue.shade700 : OpdColors.primary400,
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

              const Divider(height: 18),

              // Contact & Hospital Row
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: OpdColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 11, color: OpdColors.textDark),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.email_outlined, size: 14, color: OpdColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(fontSize: 11, color: OpdColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: 14, color: OpdColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Registered at: $hospitalName',
                      style: const TextStyle(fontSize: 11, color: OpdColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Action Buttons Row: Manage Record / Add Clinical Note
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: OpdColors.primary400,
                        side: const BorderSide(color: OpdColors.primary300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Manage Record', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManagePatientScreen(
                              searchNic: nic,
                              hospital: _effectiveHospital,
                              hospitalCode: _effectiveHospitalCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpdColors.primary400,
                        foregroundColor: OpdColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_comment_outlined, size: 15),
                      label: const Text('+ Record Note', style: TextStyle(fontSize: 11)),
                      onPressed: _showAddClinicalNoteDialog,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tabs Header
        Container(
          color: OpdColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: OpdColors.primary500,
            unselectedLabelColor: OpdColors.textMuted,
            indicatorColor: OpdColors.primary400,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: const [
              Tab(
                icon: Icon(Icons.calendar_month_outlined, size: 18),
                text: 'Visits & OPD',
              ),
              Tab(
                icon: Icon(Icons.medication_outlined, size: 18),
                text: 'Prescriptions',
              ),
              Tab(
                icon: Icon(Icons.badge_outlined, size: 18),
                text: 'Demographics',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentsTab(nic, phone),
              _buildPrescriptionsTab(nic),
              _buildDemographicsTab(d, nic),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Appointments & OPD Visits
  // ---------------------------------------------------------------------------
  Widget _buildAppointmentsTab(String patientNic, String patientPhone) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: OpdColors.primary400),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final nicClean = patientNic.trim().toUpperCase();
        final phoneClean = patientPhone.trim();

        // Filter appointments strictly belonging to this patient
        final patientAppts = allDocs.where((doc) {
          final a = doc.data();
          final apptNic = (a['nic'] ?? a['userId'] ?? a['patientId'] ?? '').toString().trim().toUpperCase();
          final apptPhone = (a['contact'] ?? a['phone'] ?? '').toString().trim();

          return apptNic == nicClean || (phoneClean.isNotEmpty && apptPhone == phoneClean);
        }).toList();

        if (patientAppts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 48, color: OpdColors.gray400),
                  const SizedBox(height: 12),
                  const Text(
                    'No OPD Appointments Found',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This patient has no booked OPD consultations or previous visits recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: OpdColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        // Summary Counters
        final total = patientAppts.length;
        final completed = patientAppts.where((doc) =>
            (doc.data()['status'] ?? '').toString().toLowerCase() == 'completed').length;
        final pending = total - completed;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Row
            Row(
              children: [
                _buildStatPill('Total Booked', '$total', OpdColors.primary500),
                const SizedBox(width: 8),
                _buildStatPill('Completed', '$completed', Colors.green.shade700),
                const SizedBox(width: 8),
                _buildStatPill('Pending / Queued', '$pending', Colors.orange.shade800),
              ],
            ),
            const SizedBox(height: 14),

            // Appointment Cards
            ...patientAppts.map((doc) {
              final a = doc.data();
              final tokenStr = 'T-${(a['queueNo'] ?? '001').toString().padLeft(3, '0')}';
              final docName = (a['doctorName'] ?? a['doctor'] ?? 'Assigned Doctor').toString();
              final speciality = (a['speciality'] ?? a['department'] ?? 'OPD Consultation').toString();
              final date = (a['date'] ?? a['dateLabel'] ?? 'Today').toString();
              final session = (a['session'] ?? a['timeSlot'] ?? '08:00 AM').toString();
              final hosp = (a['hospitalName'] ?? a['hospital'] ?? _effectiveHospital).toString();
              final status = (a['status'] ?? 'Waiting').toString();
              final notes = (a['notes'] ?? a['instructions'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: OpdColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OpdColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: OpdColors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsScreen(
                          appointmentId: doc.id,
                          token: tokenStr,
                          patientName: (a['patientName'] ?? _patientData!['fullName']).toString(),
                          nic: patientNic,
                          phone: (a['contact'] ?? patientPhone).toString(),
                          department: speciality,
                          doctor: docName,
                          date: date,
                          timeSlot: session,
                          status: status,
                          notes: notes.isNotEmpty ? notes : 'No clinical notes recorded.',
                          hospitalName: hosp,
                          hospitalCode: (a['hospitalCode'] ?? _effectiveHospitalCode).toString(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: OpdColors.primary500.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Token $tokenStr',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: OpdColors.primary500,
                                ),
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          docName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: OpdColors.textDark,
                          ),
                        ),
                        Text(
                          speciality,
                          style: const TextStyle(fontSize: 11, color: OpdColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: OpdColors.textMuted),
                            const SizedBox(width: 4),
                            Text(date, style: const TextStyle(fontSize: 11, color: OpdColors.textDark)),
                            const SizedBox(width: 10),
                            const Icon(Icons.access_time_outlined, size: 12, color: OpdColors.textMuted),
                            const SizedBox(width: 4),
                            Text(session, style: const TextStyle(fontSize: 11, color: OpdColors.textDark)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: OpdColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hosp,
                                style: const TextStyle(fontSize: 10, color: OpdColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: OpdColors.gray100.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes, size: 14, color: OpdColors.primary400),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    notes,
                                    style: const TextStyle(fontSize: 11, color: OpdColors.textDark),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildStatPill(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: OpdColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OpdColors.borderLight),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: OpdColors.textMuted),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;

    if (s.contains('completed')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (s.contains('consult') || s.contains('in consultation')) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    } else if (s.contains('cancel') || s.contains('absent')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.amber.shade50;
      fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Prescriptions & Clinical Notes
  // ---------------------------------------------------------------------------
  Widget _buildPrescriptionsTab(String patientNic) {
    final targetDoc = _patientDocId ?? patientNic;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetDoc)
          .collection('clinical_notes')
          .snapshots(),
      builder: (context, snapshot) {
        final notesDocs = snapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
          builder: (context, apptSnap) {
            final apptDocs = apptSnap.data?.docs ?? [];
            final nicClean = patientNic.trim().toUpperCase();

            // Find appointments with clinical notes or prescriptions
            final apptNotes = apptDocs.where((doc) {
              final a = doc.data();
              final aNic = (a['nic'] ?? a['userId'] ?? '').toString().trim().toUpperCase();
              final note = (a['notes'] ?? a['prescriptions'] ?? a['diagnosis'] ?? '').toString().trim();
              return aNic == nicClean && note.isNotEmpty;
            }).toList();

            if (notesDocs.isEmpty && apptNotes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication_liquid_outlined, size: 48, color: OpdColors.gray400),
                      const SizedBox(height: 12),
                      const Text(
                        'No Prescriptions or Clinical Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: OpdColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No medications or clinical prescriptions recorded for this patient yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: OpdColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OpdColors.primary400,
                          foregroundColor: OpdColors.white,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Clinical Note / Prescription'),
                        onPressed: _showAddClinicalNoteDialog,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clinical Records (${notesDocs.length + apptNotes.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary500,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: OpdColors.primary400,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Record Note', style: TextStyle(fontSize: 12)),
                      onPressed: _showAddClinicalNoteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dedicated clinical notes
                ...notesDocs.map((doc) {
                  final n = doc.data();
                  final doctor = (n['doctor'] ?? 'Attending Doctor').toString();
                  final diagnosis = (n['diagnosis'] ?? '').toString();
                  final pres = (n['prescription'] ?? '').toString();
                  final instructions = (n['instructions'] ?? '').toString();
                  final hosp = (n['hospital'] ?? _effectiveHospital).toString();

                  return _buildPrescriptionCard(
                    doctor: doctor,
                    diagnosis: diagnosis,
                    prescription: pres,
                    instructions: instructions,
                    hospital: hosp,
                    badgeText: 'CLINICAL NOTE',
                  );
                }),

                // Notes extracted from appointments
                ...apptNotes.map((doc) {
                  final a = doc.data();
                  final doctor = (a['doctorName'] ?? a['doctor'] ?? 'Attending Doctor').toString();
                  final date = (a['date'] ?? a['dateLabel'] ?? 'Appointment Date').toString();
                  final notes = (a['notes'] ?? '').toString();
                  final pres = (a['prescriptions'] ?? '').toString();
                  final hosp = (a['hospitalName'] ?? _effectiveHospital).toString();

                  return _buildPrescriptionCard(
                    doctor: doctor,
                    diagnosis: 'Consultation Note ($date)',
                    prescription: pres.isNotEmpty ? pres : notes,
                    instructions: notes != pres ? notes : '',
                    hospital: hosp,
                    badgeText: 'OPD CONSULTATION',
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPrescriptionCard({
    required String doctor,
    required String diagnosis,
    required String prescription,
    required String instructions,
    required String hospital,
    required String badgeText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OpdColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OpdColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: OpdColors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                doctor,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: OpdColors.primary500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: OpdColors.primary100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary400,
                  ),
                ),
              ),
            ],
          ),
          Text(hospital, style: const TextStyle(fontSize: 10, color: OpdColors.textMuted)),
          const Divider(height: 16),
          if (diagnosis.isNotEmpty) ...[
            const Text(
              'DIAGNOSIS / CLINICAL REASON',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: OpdColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              diagnosis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OpdColors.textDark),
            ),
            const SizedBox(height: 8),
          ],
          if (prescription.isNotEmpty) ...[
            const Text(
              'PRESCRIPTION & MEDICATIONS',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: OpdColors.primary400,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OpdColors.primary100.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: OpdColors.primary200.withValues(alpha: 0.3)),
              ),
              child: Text(
                prescription,
                style: const TextStyle(fontSize: 12, color: OpdColors.textDark, height: 1.3),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (instructions.isNotEmpty) ...[
            const Text(
              'INSTRUCTIONS & ADVICE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: OpdColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              instructions,
              style: const TextStyle(fontSize: 11, color: OpdColors.textDark),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Demographics & Registration Audit
  // ---------------------------------------------------------------------------
  Widget _buildDemographicsTab(Map<String, dynamic> d, String nic) {
    final address = (d['address'] ?? 'Not specified').toString();
    final dob = (d['dob'] ?? 'Not specified').toString();
    final gender = (d['gender'] ?? 'Male').toString();
    final registeredBy = (d['registeredBy'] ?? 'OPD Staff').toString();
    final staffId = (d['registeredStaffId'] ?? 'N/A').toString();
    final hospital = (d['registeredHospital'] ?? _effectiveHospital).toString();
    final hospitalCode = (d['registeredHospitalCode'] ?? _effectiveHospitalCode).toString();
    final isStaffRegistered = d['isRegisteredByStaff'] == true;
    final isAuthLinked = d['authLinked'] == true || d['authUid'] != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoSection(
          title: 'IDENTITY & PERSONAL DETAILS',
          icon: Icons.person_outline,
          items: [
            MapEntry('Full Name', (d['fullName'] ?? d['name'] ?? 'N/A').toString()),
            MapEntry('First Name', (d['firstName'] ?? 'N/A').toString()),
            MapEntry('Last Name', (d['lastName'] ?? 'N/A').toString()),
            MapEntry('National ID (NIC)', nic),
            MapEntry('User ID / Patient ID', (d['userId'] ?? nic).toString()),
            MapEntry('Date of Birth', dob),
            MapEntry('Gender', gender),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoSection(
          title: 'CONTACT & RESIDENCE',
          icon: Icons.location_city_outlined,
          items: [
            MapEntry('Mobile Phone', (d['contactNo'] ?? d['contact'] ?? 'N/A').toString()),
            MapEntry('Email Address', (d['email'] ?? 'Not provided').toString()),
            MapEntry('Residential Address', address),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoSection(
          title: 'REGISTRATION AUDIT & RECORD STATUS',
          icon: Icons.verified_user_outlined,
          items: [
            MapEntry('Account Mode', isAuthLinked ? 'Active Online Account' : 'OPD Direct Record (In-Person)'),
            MapEntry('Direct OPD Registered', isStaffRegistered ? 'Yes' : 'No (Online Signup)'),
            MapEntry('Registered By', registeredBy),
            MapEntry('Staff ID', staffId),
            MapEntry('Hospital Name', hospital),
            MapEntry('Hospital Code', hospitalCode),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OpdColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OpdColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: OpdColors.primary400),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: OpdColors.primary500,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpdColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: OpdColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Idle / Empty State (Shows Recent Registered Patients Directory)
  // ---------------------------------------------------------------------------
  Widget _buildIdleOrEmptyState() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final recentPatients = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Guidance Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OpdColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OpdColors.primary300.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OpdColors.primary100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.manage_search, color: OpdColors.primary400, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasSearched ? 'Search Completed' : 'Look Up Patient Inquiry',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: OpdColors.primary500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Search by Government NIC, User ID, Mobile Phone, or Patient Name to access visits, clinical history, and prescriptions.',
                          style: TextStyle(fontSize: 11, color: OpdColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent Patients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT REGISTERED PATIENTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: OpdColors.primary500,
                  ),
                ),
                Text(
                  '${recentPatients.length} Patients',
                  style: const TextStyle(fontSize: 10, color: OpdColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (recentPatients.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: OpdColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OpdColors.borderLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, size: 36, color: OpdColors.gray400),
                      const SizedBox(height: 8),
                      const Text(
                        'No patients registered yet',
                        style: TextStyle(fontSize: 12, color: OpdColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OpdColors.primary400,
                          foregroundColor: OpdColors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RegisterNewPatientScreen(
                                hospital: _effectiveHospital,
                                hospitalCode: _effectiveHospitalCode,
                              ),
                            ),
                          );
                        },
                        child: const Text('Register First Patient'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentPatients.map((doc) {
                final d = doc.data();
                final name = (d['fullName'] ?? d['name'] ?? 'Patient').toString();
                final nic = (d['nic'] ?? d['userId'] ?? doc.id).toString();
                final phone = (d['contactNo'] ?? d['contact'] ?? 'No phone').toString();
                final gender = (d['gender'] ?? 'Male').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: OpdColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OpdColors.borderLight),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: gender == 'Female'
                          ? Colors.pink.shade50
                          : OpdColors.primary100,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P',
                        style: TextStyle(
                          color: gender == 'Female' ? Colors.pink : OpdColors.primary400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text('NIC: $nic • Phone: $phone', style: const TextStyle(fontSize: 11)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpdColors.primary400,
                        foregroundColor: OpdColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _selectPatient(doc.id, d),
                      child: const Text('View Inquiry', style: TextStyle(fontSize: 10)),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
