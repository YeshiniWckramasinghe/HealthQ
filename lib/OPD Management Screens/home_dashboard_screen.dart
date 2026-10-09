import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_header_banner.dart';
import 'opd_bottom_nav.dart';
import 'patient_management_hub_screen.dart';
import 'appointments_list_screen.dart';
import 'nurse_profile_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final String? nurseName;
  final String? nurseId;
  final String? department;
  final String? hospital;
  final String? phone;
  final String? email;
  final String? shift;
  final String? role;

  const HomeDashboardScreen({
    super.key,
    this.nurseName,
    this.nurseId,
    this.department,
    this.hospital,
    this.phone,
    this.email,
    this.shift,
    this.role,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Nurse Profile Information & Live Picture
  String _nursePhotoBase64 = '';
  String _nursePhotoUrl = '';
  String? _nurseName;
  String? _nurseDepartment;
  String? _nurseHospital;

  // Real Database Doctors & Queue data
  List<Doctor> _doctors = [];
  Map<String, int> _doctorQueueCounts = {};
  bool _isLoadingDoctors = true;
  StreamSubscription? _staffSubscription;
  StreamSubscription? _appointmentsSubscription;

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

    _loadNurseData();
    _listenToNurseProfile();
    _loadDoctorsFromDatabase();
    _listenToAppointmentsQueue();

    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staffSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 1. Nurse Profile Loading & Live Real-Time Updates
  // ---------------------------------------------------------------------------
  Future<void> _loadNurseData() async {
    final staffId = widget.nurseId ??
        StaffAuthService.instance.currentStaff?.staffId ??
        'NUR1002-0011';
    try {
      final staff = await StaffAuthService.instance.findStaff(staffId);
      if (staff != null && mounted) {
        final bool hospitalChanged = _nurseHospital != staff.hospital;
        setState(() {
          _nurseName = staff.name;
          _nurseDepartment = staff.department ?? _nurseDepartment;
          _nurseHospital = staff.hospital;
          _nursePhotoBase64 = staff.photoBase64 ?? '';
          _nursePhotoUrl = staff.photoUrl ?? '';
        });
        StaffAuthService.instance.setCurrentStaff(staff);
        if (hospitalChanged) {
          _loadDoctorsFromDatabase();
          _listenToAppointmentsQueue();
        }
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
            final bool hospitalChanged = newHospital.isNotEmpty && newHospital != _nurseHospital;
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
            if (hospitalChanged) {
              _loadDoctorsFromDatabase();
              _listenToAppointmentsQueue();
            }
          }
          break;
        }
      }
    }, onError: (e) {
      debugPrint('Live nurse profile listener note: $e');
    });
  }

  // ---------------------------------------------------------------------------
  // 2. Load Real Doctors strictly for Nurse's Registered Hospital
  // ---------------------------------------------------------------------------
  Future<void> _loadDoctorsFromDatabase() async {
    setState(() => _isLoadingDoctors = true);
    try {
      final targetHosp = _effectiveHospital;
      final docs = await BookingService.instance.getDoctors(
        targetHosp,
        hospitalName: targetHosp,
      );

      if (mounted) {
        setState(() {
          _doctors = docs;
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors from database: $e');
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Real-Time Live Queue Count strictly for Nurse's Registered Hospital
  // ---------------------------------------------------------------------------
  void _listenToAppointmentsQueue() {
    _appointmentsSubscription?.cancel();
    final targetHosp = _effectiveHospital;
    final targetCode = _effectiveHospitalCode;

    _appointmentsSubscription = FirebaseFirestore.instance
        .collection('appointments')
        .snapshots()
        .listen((snap) {
      final Map<String, int> counts = {};

      for (final doc in snap.docs) {
        final d = doc.data();
        final docHospital = (d['hospitalName'] ?? d['hospital'] ?? '').toString().trim();
        final docHospitalId = (d['hospitalIdentificationNo'] ??
                d['hospitalCode'] ??
                d['hospitalId'] ??
                '')
            .toString()
            .trim();

        // STRICT HOSPITAL MATCH:
        // Exclude appointments belonging to other hospitals
        if (!Hospital.matchesHospital(
          targetHospital: targetHosp,
          targetCode: targetCode,
          itemHospital: docHospital,
          itemCode: docHospitalId,
        )) {
          continue;
        }

        final docStatus = (d['status'] ?? 'Waiting').toString().toLowerCase();

        // Count patients who are waiting or currently in consultation
        if (docStatus == 'waiting' || docStatus == 'in consult' || docStatus == 'upcoming') {
          final docName = (d['doctorName'] ?? d['doctor'] ?? '').toString().toLowerCase().trim();
          if (docName.isNotEmpty) {
            counts[docName] = (counts[docName] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _doctorQueueCounts = counts;
        });
      }
    }, onError: (e) {
      debugPrint('Queue count listener note: $e');
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
    // Search query filtering real doctors
    final query = _searchController.text.trim().toLowerCase();
    final displayedDoctors = query.isEmpty
        ? _doctors
        : _doctors.where((d) {
            final nameMatch = d.name.toLowerCase().contains(query);
            final specMatch = d.speciality.toLowerCase().contains(query);
            final roomMatch = (d.room ?? '').toLowerCase().contains(query);
            return nameMatch || specMatch || roomMatch;
          }).toList();

    return Scaffold(
      backgroundColor: OpdColors.primary100,
      body: Column(
        children: [
          // Header banner with hospital corridor photo and Live Updated Avatar
          OpdHeaderBanner(
            title: _nurseName != null && _nurseName!.isNotEmpty
                ? 'Good Morning, $_nurseName'
                : (widget.nurseName != null && widget.nurseName!.isNotEmpty
                    ? 'Good Morning, ${widget.nurseName}'
                    : 'Good Morning, Nurse'),
            nurseId: widget.nurseId != null && widget.nurseId!.isNotEmpty
                ? 'ID: ${widget.nurseId}'
                : 'ID: NUR1002-0011',
            department: widget.department ?? 'General Medicine OPD',
            hospital: widget.hospital ?? 'Government Hospital — Colombo',
            onAvatarTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of the Nurse Portal?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OpdColors.primary400,
                        foregroundColor: OpdColors.white,
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Main body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: OpdColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: OpdColors.primary300.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OpdColors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search registered doctors, specialties, rooms...',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          color: OpdColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: OpdColors.primary300,
                        ),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Hub (3 Columns)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.person_search_outlined,
                          title: 'Patient\nManagement',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientManagementHubScreen(
                                  hospital: _effectiveHospital,
                                  nurseId: widget.nurseId ?? StaffAuthService.instance.currentStaff?.staffId,
                                  nurseName: _nurseName,
                                  department: _nurseDepartment,
                                  phone: widget.phone,
                                  email: widget.email,
                                  shift: widget.shift,
                                  role: widget.role,
                                  photoBase64: _nursePhotoBase64,
                                  photoUrl: _nursePhotoUrl,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'Appointments\nDatabase',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppointmentsListScreen(
                                  hospital: _effectiveHospital,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionTile(
                          icon: Icons.format_list_numbered_outlined,
                          title: 'Live Queue\nManagement',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppointmentsListScreen(
                                  initialQueueTab: true,
                                  hospital: _effectiveHospital,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // TODAY'S OPD Section Header with Hospital Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "TODAY'S ${_effectiveHospitalCode.isNotEmpty ? '$_effectiveHospitalCode ' : ''}OPD CLINICS & DOCTORS",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: OpdColors.primary500,
                          ),
                        ),
                      ),
                      Text(
                        '${displayedDoctors.length} On Duty',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: OpdColors.primary300,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Real Hospital Database Doctor Cards
                  if (_isLoadingDoctors)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: OpdColors.primary400),
                      ),
                    )
                  else if (displayedDoctors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OpdColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.medical_services_outlined, size: 36, color: OpdColors.primary300),
                          const SizedBox(height: 8),
                          Text(
                            query.isNotEmpty
                                ? 'No doctors matching "$query"'
                                : 'No doctors registered for $_effectiveHospital',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: OpdColors.primary500),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'OPD schedules are fetched from Cloud Firestore database.',
                            style: TextStyle(fontSize: 11, color: OpdColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...displayedDoctors.map((doc) => _buildRealDoctorCard(doc)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 0,
        hospital: _effectiveHospital,
        nurseId: widget.nurseId ?? StaffAuthService.instance.currentStaff?.staffId,
        nurseName: _nurseName,
        department: _nurseDepartment,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: OpdColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: OpdColors.primary200.withValues(alpha: 0.4),
            width: 1,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: OpdColors.primary300,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: OpdColors.primary500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealDoctorCard(Doctor doc) {
    // Compute live queue count from Firestore appointments or doc.waiting
    final docKey = doc.name.toLowerCase().trim();
    final liveQueueCount = _doctorQueueCounts[docKey] ?? doc.waiting;
    final roomDisplay = doc.room != null && doc.room!.isNotEmpty ? doc.room! : 'Room 01';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          // Tapping doctor navigates to this doctor's appointments queue!
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentsListScreen(
                filterDoctor: doc.name,
                hospital: _effectiveHospital,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              // Doctor Avatar Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Icon(
                  Icons.medical_information_outlined,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.speciality} • $roomDisplay',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpdColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Real-Time Queue Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: OpdColors.primary100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: OpdColors.primary200.withValues(alpha: 0.7),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Queue: $liveQueueCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
