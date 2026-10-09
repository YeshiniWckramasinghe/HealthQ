import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_header_banner.dart';
import 'opd_bottom_nav.dart';
import 'nurse_profile_screen.dart';
import 'register_new_patient_screen.dart';
import 'manage_patient_screen.dart';
import 'patient_inquiry_screen.dart';

class PatientManagementHubScreen extends StatefulWidget {
  final String? hospital;
  final String? nurseId;
  final String? nurseName;
  final String? department;
  final String? phone;
  final String? email;
  final String? shift;
  final String? role;
  final String? photoBase64;
  final String? photoUrl;

  const PatientManagementHubScreen({
    super.key,
    this.hospital,
    this.nurseId,
    this.nurseName,
    this.department,
    this.phone,
    this.email,
    this.shift,
    this.role,
    this.photoBase64,
    this.photoUrl,
  });

  @override
  State<PatientManagementHubScreen> createState() =>
      _PatientManagementHubScreenState();
}

class _PatientManagementHubScreenState
    extends State<PatientManagementHubScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Nurse Profile Information & Live Picture
  String _nursePhotoBase64 = '';
  String _nursePhotoUrl = '';
  String? _nurseName;
  String? _nurseDepartment;
  String? _nurseHospital;
  StreamSubscription? _staffSubscription;

  String get _effectiveHospital {
    if (_nurseHospital != null && _nurseHospital!.trim().isNotEmpty) {
      return _nurseHospital!.trim();
    }
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
    return Hospital.resolveHospitalCode(_effectiveHospital);
  }

  String get _effectiveHospitalDisplay {
    final code = _effectiveHospitalCode;
    final name = _effectiveHospital;
    if (code.isNotEmpty && !name.toUpperCase().contains(code)) {
      return '$name ($code)';
    }
    return name;
  }

  @override
  void initState() {
    super.initState();
    _nurseName = widget.nurseName ?? StaffAuthService.instance.currentStaff?.name;
    _nurseDepartment = widget.department ?? StaffAuthService.instance.currentStaff?.department;
    _nurseHospital = widget.hospital ?? StaffAuthService.instance.currentStaff?.hospital;
    _nursePhotoBase64 = widget.photoBase64 ?? StaffAuthService.instance.currentStaff?.photoBase64 ?? '';
    _nursePhotoUrl = widget.photoUrl ?? StaffAuthService.instance.currentStaff?.photoUrl ?? '';

    _loadNurseData();
    _listenToNurseProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staffSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Nurse Profile Loading & Live Real-Time Updates
  // ---------------------------------------------------------------------------
  Future<void> _loadNurseData() async {
    final staffId = widget.nurseId ??
        StaffAuthService.instance.currentStaff?.staffId ??
        'NUR1002-0011';
    try {
      final staff = await StaffAuthService.instance.findStaff(staffId);
      if (staff != null && mounted) {
        setState(() {
          _nurseName = staff.name;
          _nurseDepartment = staff.department ?? _nurseDepartment;
          _nurseHospital = staff.hospital;
          _nursePhotoBase64 = staff.photoBase64 ?? '';
          _nursePhotoUrl = staff.photoUrl ?? '';
        });
        StaffAuthService.instance.setCurrentStaff(staff);
      }
    } catch (e) {
      debugPrint('Error loading nurse staff data: $e');
    }
  }

  void _listenToNurseProfile() {
    final staffId = (widget.nurseId ??
            StaffAuthService.instance.currentStaff?.staffId ??
            'NUR1002-0011')
        .trim()
        .toUpperCase();

    _staffSubscription = FirebaseFirestore.instance
        .collection('staff')
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data();
        final sid = (d['staffId'] ?? d['id'] ?? doc.id).toString().trim().toUpperCase();
        if (sid == staffId || doc.id.toUpperCase() == staffId) {
          if (mounted) {
            final newHospital = (d['hospital'] ?? d['hospitalName'] ?? '').toString().trim();
            setState(() {
              _nursePhotoBase64 = (d['photoBase64'] ?? '').toString();
              _nursePhotoUrl = (d['photoUrl'] ?? '').toString();
              if (d['name'] != null && d['name'].toString().isNotEmpty) {
                _nurseName = d['name'].toString();
              }
              if (d['department'] != null && d['department'].toString().isNotEmpty) {
                _nurseDepartment = d['department'].toString();
              }
              if (newHospital.isNotEmpty) {
                _nurseHospital = newHospital;
              }
            });
          }
          break;
        }
      }
    }, onError: (e) {
      debugPrint('Live nurse profile listener note: $e');
    });
  }

  Future<void> _openNurseProfile() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NurseProfileScreen(
          nurseName: _nurseName ?? widget.nurseName,
          nurseId: widget.nurseId,
          department: _nurseDepartment ?? widget.department,
          hospital: _nurseHospital ?? widget.hospital,
          phone: widget.phone,
          email: widget.email,
          shift: widget.shift,
          role: widget.role,
        ),
      ),
    );

    // Immediate update from pop result
    if (result is Map && mounted) {
      setState(() {
        if (result['photoBase64'] != null) {
          _nursePhotoBase64 = result['photoBase64'].toString();
        }
        if (result['photoUrl'] != null) {
          _nursePhotoUrl = result['photoUrl'].toString();
        }
        if (result['name'] != null) {
          _nurseName = result['name'].toString();
        }
        if (result['department'] != null) {
          _nurseDepartment = result['department'].toString();
        }
        if (result['hospital'] != null) {
          _nurseHospital = result['hospital'].toString();
        }
      });
    }

    // Secondary reload to ensure full sync with Firestore
    await _loadNurseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      body: Column(
        children: [
          // Header banner with hospital corridor photo and Live Updated Avatar (identical to Home banner)
          OpdHeaderBanner(
            title: _nurseName != null && _nurseName!.isNotEmpty
                ? 'Good Morning, $_nurseName'
                : (widget.nurseName != null && widget.nurseName!.isNotEmpty
                    ? 'Good Morning, ${widget.nurseName}'
                    : 'Good Morning, Nurse'),
            nurseId: widget.nurseId != null && widget.nurseId!.isNotEmpty
                ? 'ID: ${widget.nurseId}'
                : (StaffAuthService.instance.currentStaff?.staffId != null
                    ? 'ID: ${StaffAuthService.instance.currentStaff!.staffId}'
                    : 'Staff Nurse'),
            department: _nurseDepartment ?? widget.department ?? 'General Medicine OPD',
            hospital: _effectiveHospitalDisplay,
            photoBase64: _nursePhotoBase64,
            photoUrl: _nursePhotoUrl,
            onAvatarTap: _openNurseProfile,
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Indicator Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: OpdColors.primary500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_search_outlined,
                          size: 18,
                          color: OpdColors.primary500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Patient Management',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: OpdColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notice Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: OpdColors.primary300,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OpdColors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'OPD Registrar Notice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: OpdColors.primary400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Please verify Government National Identity Card (NIC) with extreme caution before registering new patients.',
                          style: TextStyle(
                            fontSize: 11,
                            color: OpdColors.textDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section: SEARCH PATIENT
                  const Text(
                    'SEARCH PATIENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: OpdColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: OpdColors.primary300.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Enter NIC, Phone or Patient Name...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: OpdColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: OpdColors.primary300,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: OpdColors.primary400),
                          tooltip: 'Search Patient Inquiry',
                          onPressed: () {
                            final val = _searchController.text.trim();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientInquiryScreen(
                                  initialQuery: val.isNotEmpty ? val : null,
                                  hospital: _effectiveHospital,
                                  hospitalCode: _effectiveHospitalCode,
                                  nurseName: _nurseName ?? widget.nurseName,
                                  nurseId: widget.nurseId,
                                  department: _nurseDepartment ?? widget.department,
                                ),
                              ),
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (val) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientInquiryScreen(
                              initialQuery: val.trim().isNotEmpty ? val.trim() : null,
                              hospital: _effectiveHospital,
                              hospitalCode: _effectiveHospitalCode,
                              nurseName: _nurseName ?? widget.nurseName,
                              nurseId: widget.nurseId,
                              department: _nurseDepartment ?? widget.department,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Item 1: Register New Patient
                  _buildNavCard(
                    title: 'Register New Patient',
                    subtitle: 'Create records for unregistered OPD patients.',
                    onTap: () {
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

                  const SizedBox(height: 10),

                  // Action Item 2: Manage Patient
                  _buildNavCard(
                    title: 'Manage Patient',
                    subtitle: 'Update existing demographic and medical info',
                    onTap: () {
                      final query = _searchController.text.trim();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManagePatientScreen(
                            searchNic: query.isNotEmpty ? query : null,
                            hospital: _effectiveHospital,
                            hospitalCode: _effectiveHospitalCode,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Action Item 3: Patient Inquiry
                  _buildNavCard(
                    title: 'Patient Inquiry',
                    subtitle:
                        'Look up history, appointments, and prescriptions',
                    onTap: () {
                      final query = _searchController.text.trim();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientInquiryScreen(
                            initialQuery: query.isNotEmpty ? query : null,
                            hospital: _effectiveHospital,
                            hospitalCode: _effectiveHospitalCode,
                            nurseName: _nurseName ?? widget.nurseName,
                            nurseId: widget.nurseId,
                            department: _nurseDepartment ?? widget.department,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: _effectiveHospital,
        nurseId: widget.nurseId,
        nurseName: _nurseName ?? widget.nurseName,
        department: _nurseDepartment ?? widget.department,
      ),
    );
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: OpdColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OpdColors.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: OpdColors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: OpdColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: OpdColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: OpdColors.primary300,
            ),
          ],
        ),
      ),
    );
  }
}
