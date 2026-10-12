import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';
import 'opd_doctor_profile_screen.dart';

class OpdDoctorManagementScreen extends StatefulWidget {
  final String? hospital;
  final String? hospitalCode;
  final String? department;
  final List<Map<String, dynamic>>? initialDoctors;

  const OpdDoctorManagementScreen({
    super.key,
    this.hospital,
    this.hospitalCode,
    this.department,
    this.initialDoctors,
  });

  @override
  State<OpdDoctorManagementScreen> createState() =>
      _OpdDoctorManagementScreenState();
}

class _OpdDoctorManagementScreenState extends State<OpdDoctorManagementScreen> {
  static const Color headerTeal = Color(0xFF006760);
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color bgMint = Color(0xFFF3F8F7);

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _doctors = [];

  String get _effectiveHospital {
    if (widget.hospital != null && widget.hospital!.trim().isNotEmpty) {
      return widget.hospital!.trim();
    }
    try {
      if (StaffAuthService.instance.currentStaff?.hospital != null &&
          StaffAuthService.instance.currentStaff!.hospital.trim().isNotEmpty) {
        return StaffAuthService.instance.currentStaff!.hospital.trim();
      }
    } catch (_) {}
    return 'Government Hospital Colombo';
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
    _loadDoctors();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    if (widget.initialDoctors != null) {
      setState(() {
        _doctors = List.from(widget.initialDoctors!);
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fetched = await BookingService.instance.getDoctors(
        _effectiveHospital,
        hospitalName: _effectiveHospital,
      );

      final List<Map<String, dynamic>> mapped = [];

      for (int i = 0; i < fetched.length; i++) {
        final d = fetched[i];
        final days = _computeDoctorDays(i, d.speciality);
        mapped.add({
          'id': d.id,
          'name': d.name,
          'speciality': d.speciality,
          'department': d.speciality,
          'opdDays': days,
          'regNo': 'SLMC-${(d.name.hashCode.abs() % 89999 + 10000)}',
          'phone': d.contactNo ?? '011-234-5678',
          'email': d.email ?? _formatEmail(d.name),
          'session': '08:30 - 13:00',
          'designation': _formatDesignation(d.speciality),
          'room': d.room ?? 'Room 01',
          'hospital': _effectiveHospital,
        });
      }

      if (mapped.isEmpty) {
        mapped.addAll(_wireframeDefaultDoctors);
      }

      if (mounted) {
        setState(() {
          _doctors = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors in doctor management: $e');
      if (mounted) {
        setState(() {
          _doctors = List.from(_wireframeDefaultDoctors);
          _isLoading = false;
        });
      }
    }
  }

  String _computeDoctorDays(int index, String speciality) {
    if (speciality.toLowerCase().contains('general')) return 'Daily';
    if (index % 3 == 0) return 'Mon/Wed/Fri';
    if (index % 3 == 1) return 'Tue/Thu';
    return 'Mon/Thu/Sat';
  }

  String _formatEmail(String name) {
    final clean = name.toLowerCase().replaceAll('dr.', '').replaceAll(' ', '.').trim();
    return '$clean@govhosp.lk';
  }

  String _formatDesignation(String speciality) {
    if (speciality.toLowerCase().contains('cardio')) return 'Consultant Cardiologist';
    if (speciality.toLowerCase().contains('pediatr')) return 'Consultant Pediatrician';
    if (speciality.toLowerCase().contains('ortho')) return 'Consultant Orthopedic Surgeon';
    if (speciality.toLowerCase().contains('neuro')) return 'Consultant Neurologist';
    if (speciality.toLowerCase().contains('dermat')) return 'Consultant Dermatologist';
    return 'Consultant Physician';
  }

  List<Map<String, dynamic>> get _wireframeDefaultDoctors => [
        {
          'id': 'doc_01',
          'name': 'Dr. S. Perera',
          'speciality': 'Cardiology',
          'department': 'Cardiology OPD',
          'opdDays': 'Mon/Wed/Fri',
          'regNo': 'SLMC-18492',
          'phone': '011-234-5671',
          'email': 's.perera@govhosp.lk',
          'session': '08:30 - 12:30',
          'designation': 'Consultant Cardiologist',
          'room': 'Room 04',
          'hospital': _effectiveHospital,
        },
        {
          'id': 'doc_02',
          'name': 'Dr. R. Fernando',
          'speciality': 'General Medicine',
          'department': 'General Medicine',
          'opdDays': 'Daily',
          'regNo': 'SLMC-20045',
          'phone': '011-234-5678',
          'email': 'r.fernando@govhosp.lk',
          'session': '08:30 - 13:00',
          'designation': 'Consultant Physician',
          'room': 'Room 01',
          'hospital': _effectiveHospital,
        },
        {
          'id': 'doc_03',
          'name': 'Dr. A. Wijesuriya',
          'speciality': 'Pediatrics',
          'department': 'Pediatrics OPD',
          'opdDays': 'Tue/Thu',
          'regNo': 'SLMC-21890',
          'phone': '011-234-5673',
          'email': 'a.wijesuriya@govhosp.lk',
          'session': '09:00 - 13:00',
          'designation': 'Consultant Pediatrician',
          'room': 'Room 03',
          'hospital': _effectiveHospital,
        },
        {
          'id': 'doc_04',
          'name': 'Dr. N. Gunawardena',
          'speciality': 'Dermatology',
          'department': 'Dermatology OPD',
          'opdDays': 'Mon/Wed/Fri',
          'regNo': 'SLMC-22340',
          'phone': '011-234-5675',
          'email': 'n.gunawardena@govhosp.lk',
          'session': '08:30 - 12:00',
          'designation': 'Consultant Dermatologist',
          'room': 'Room 05',
          'hospital': _effectiveHospital,
        },
        {
          'id': 'doc_05',
          'name': 'Dr. K. Dissanayake',
          'speciality': 'Orthopedics',
          'department': 'Orthopedics OPD',
          'opdDays': 'Tue/Thu/Sat',
          'regNo': 'SLMC-19870',
          'phone': '011-234-5679',
          'email': 'k.dissanayake@govhosp.lk',
          'session': '09:00 - 14:00',
          'designation': 'Consultant Orthopedic Surgeon',
          'room': 'Room 02',
          'hospital': _effectiveHospital,
        },
      ];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _doctors
        : _doctors.where((d) {
            final name = (d['name'] ?? '').toString().toLowerCase();
            final spec = (d['speciality'] ?? '').toString().toLowerCase();
            final reg = (d['regNo'] ?? '').toString().toLowerCase();
            final days = (d['opdDays'] ?? '').toString().toLowerCase();
            return name.contains(query) ||
                spec.contains(query) ||
                reg.contains(query) ||
                days.contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: bgMint,
      appBar: AppBar(
        backgroundColor: headerTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _effectiveHospitalCode.isNotEmpty
                  ? '$_effectiveHospital ($_effectiveHospitalCode)'
                  : _effectiveHospital,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD6EAE7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF0F2E2C),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search doctor by name, specialty, reg no...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 21,
                      color: primaryTeal,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Doctor List Count Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ON DUTY DOCTORS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: primaryTeal,
                    ),
                  ),
                  Text(
                    '${filtered.length} Doctors Registered',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Doctors List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            query.isNotEmpty ? 'No doctors matching "$query"' : 'No doctors found.',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final name = (doc['name'] ?? 'Doctor').toString();
                            final spec = (doc['speciality'] ?? 'General Medicine').toString();
                            final days = (doc['opdDays'] ?? 'Daily').toString();
                            final session = (doc['session'] ?? '08:30 - 13:00').toString();

                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OpdDoctorProfileScreen(
                                      doctor: doc,
                                      hospital: _effectiveHospital,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFBAE6FD)),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services_rounded,
                                        color: Color(0xFF0284C7),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F2E2C),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$spec • $days',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Hours: $session',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: primaryTeal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: _effectiveHospital,
      ),
    );
  }
}
