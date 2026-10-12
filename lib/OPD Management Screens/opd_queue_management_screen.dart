import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';
import 'opd_queue_patient_details_screen.dart';

class OpdQueueManagementScreen extends StatefulWidget {
  final String? hospital;
  final String? hospitalCode;
  final String? department;
  final String? initialDoctorFilter;

  const OpdQueueManagementScreen({
    super.key,
    this.hospital,
    this.hospitalCode,
    this.department,
    this.initialDoctorFilter,
  });

  @override
  State<OpdQueueManagementScreen> createState() =>
      _OpdQueueManagementScreenState();
}

class _OpdQueueManagementScreenState extends State<OpdQueueManagementScreen> {
  static const Color headerTeal = Color(0xFF006760);
  static const Color primaryTeal = Color(0xFF007A78);
  static const Color bgMint = Color(0xFFF3F8F7);

  String? _selectedDoctor;
  List<String> _availableDoctors = [];
  final Map<String, String> _localStatusOverrides = {};

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
    return 'City General Hospital';
  }

  String get _effectiveHospitalCode {
    if (widget.hospitalCode != null && widget.hospitalCode!.trim().isNotEmpty) {
      return widget.hospitalCode!.trim();
    }
    return Hospital.resolveHospitalCode(_effectiveHospital);
  }

  String get _effectiveDepartment {
    if (widget.department != null && widget.department!.trim().isNotEmpty) {
      return widget.department!.trim();
    }
    try {
      if (StaffAuthService.instance.currentStaff?.department != null &&
          StaffAuthService.instance.currentStaff!.department!.trim().isNotEmpty) {
        return StaffAuthService.instance.currentStaff!.department!.trim();
      }
    } catch (_) {}
    return 'General Medicine OPD';
  }

  @override
  void initState() {
    super.initState();
    _selectedDoctor = widget.initialDoctorFilter;
    _loadHospitalDoctors();
  }

  Future<void> _loadHospitalDoctors() async {
    try {
      final doctors = await BookingService.instance.getDoctors(
        _effectiveHospital,
        hospitalName: _effectiveHospital,
      );
      if (doctors.isNotEmpty && mounted) {
        setState(() {
          final names = doctors.map((d) => d.name.trim()).toSet().toList();
          names.sort();
          _availableDoctors = names;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors for queue filter: $e');
    }
  }

  int _statusSortPriority(String status) {
    switch (status.toLowerCase()) {
      case 'in consult':
      case 'in_consult':
        return 0;
      case 'next':
        return 1;
      case 'waiting':
        return 2;
      case 'confirmed':
        return 3;
      case 'absent':
        return 4;
      case 'completed':
        return 5;
      case 'cancelled':
        return 6;
      default:
        return 2;
    }
  }

  String _calculateWaitTime(int queuePosition, String status) {
    final s = status.toLowerCase();
    if (s == 'in consult' || s == 'in_consult') return '0 min';
    if (s == 'absent' || s == 'cancelled') return '—';
    if (s == 'completed') return 'Done';
    if (queuePosition <= 1 && s == 'next') return '12 min';

    final waitMinutes = queuePosition * 12 + 1;
    return '$waitMinutes min';
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    Color border;

    switch (status.toLowerCase()) {
      case 'in consult':
      case 'in_consult':
        bg = const Color(0xFFE6F4F1);
        fg = primaryTeal;
        border = primaryTeal;
        break;
      case 'next':
        bg = const Color(0xFFEBF5FF);
        fg = const Color(0xFF2563EB);
        border = const Color(0xFFBFDBFE);
        break;
      case 'completed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        border = const Color(0xFFBBF7D0);
        break;
      case 'absent':
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        break;
      case 'waiting':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        border = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openPatientDetails({
    String? appointmentId,
    required String token,
    required String patientName,
    required String nic,
    required String phone,
    required String department,
    required String doctor,
    required String scheduledTime,
    required String currentStatus,
  }) async {
    final effectiveStatus = _localStatusOverrides[token] ?? currentStatus;
    final updated = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => OpdQueuePatientDetailsScreen(
          appointmentId: appointmentId,
          token: token,
          patientName: patientName,
          nic: nic,
          phone: phone,
          department: department,
          doctor: doctor,
          scheduledTime: scheduledTime,
          currentStatus: effectiveStatus,
          hospital: _effectiveHospital,
          hospitalCode: _effectiveHospitalCode,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _localStatusOverrides[token] = updated;
      });
    }
  }

  void _showDoctorFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Filter by Doctor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2E2C),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Doctors', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _selectedDoctor == null
                    ? const Icon(Icons.check, color: primaryTeal)
                    : null,
                onTap: () {
                  setState(() => _selectedDoctor = null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ..._availableDoctors.map((doc) {
                final isSelected = _selectedDoctor == doc;
                return ListTile(
                  title: Text(doc, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: primaryTeal)
                      : null,
                  onTap: () {
                    setState(() => _selectedDoctor = doc);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? get _appointmentsStream {
    try {
      return FirebaseFirestore.instance
          .collection('appointments')
          .snapshots();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Queue Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _effectiveDepartment,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _appointmentsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            // 1. Filter by Hospital and Doctor
            final hospitalDocs = docs.where((doc) {
              final d = doc.data();
              final docHosp = (d['hospitalName'] ?? d['hospital'] ?? '').toString().trim();
              final docHospId = (d['hospitalIdentificationNo'] ??
                      d['hospitalCode'] ??
                      d['hospitalId'] ??
                      '')
                  .toString()
                  .trim();

              final matchesHospital = Hospital.matchesHospital(
                targetHospital: _effectiveHospital,
                targetCode: _effectiveHospitalCode,
                itemHospital: docHosp,
                itemCode: docHospId,
              );
              if (!matchesHospital) return false;

              // Doctor filter
              if (_selectedDoctor != null && _selectedDoctor!.isNotEmpty) {
                final docDoctor = (d['doctorName'] ?? d['doctor'] ?? '').toString().trim().toLowerCase();
                if (!docDoctor.contains(_selectedDoctor!.toLowerCase())) {
                  return false;
                }
              }

              return true;
            }).toList();

            // Collect doctor names if not yet populated
            if (_availableDoctors.isEmpty && hospitalDocs.isNotEmpty) {
              final foundDocs = hospitalDocs
                  .map((d) => (d.data()['doctorName'] ?? d.data()['doctor'] ?? '').toString().trim())
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList();
              if (foundDocs.isNotEmpty) {
                _availableDoctors = foundDocs..sort();
              }
            }

            final List<Map<String, dynamic>> queueItems = [];

            if (hospitalDocs.isNotEmpty) {
              // Convert Firestore documents
              for (int i = 0; i < hospitalDocs.length; i++) {
                final d = hospitalDocs[i].data();
                final rawStatus = (d['status'] ?? 'Waiting').toString().trim();

                final token = d['queueNo'] != null
                    ? 'T-${d['queueNo'].toString().padLeft(3, '0')}'
                    : (d['token'] ?? 'T-${(i + 1).toString().padLeft(3, '0')}');

                final effectiveStatus = _localStatusOverrides[token] ?? rawStatus;

                queueItems.add({
                  'appointmentId': hospitalDocs[i].id,
                  'token': token,
                  'patientName': (d['patientName'] ?? d['name'] ?? 'Patient').toString().trim(),
                  'nic': (d['nic'] ?? d['userId'] ?? '952345678V').toString().trim(),
                  'phone': (d['contact'] ?? d['contactNo'] ?? d['phone'] ?? '071-234-5678').toString().trim(),
                  'department': (d['speciality'] ?? d['department'] ?? _effectiveDepartment).toString().trim(),
                  'doctor': (d['doctorName'] ?? d['doctor'] ?? (_selectedDoctor ?? 'Dr. R. Fernando')).toString().trim(),
                  'scheduledTime': (d['session'] ?? d['timeSlot'] ?? '09:00 AM').toString().trim(),
                  'status': effectiveStatus,
                  'queueNo': d['queueNo'] is int ? d['queueNo'] : i + 1,
                  'createdAt': d['createdAt'],
                });
              }

              // Sort queue: Status Priority first, then token/queueNo
              queueItems.sort((a, b) {
                final pa = _statusSortPriority(a['status']);
                final pb = _statusSortPriority(b['status']);
                if (pa != pb) return pa.compareTo(pb);
                final qa = a['queueNo'] as int? ?? 0;
                final qb = b['queueNo'] as int? ?? 0;
                return qa.compareTo(qb);
              });
            } else {
              // Seed Wireframe Default Mock Data
              final defaultDoctor = _selectedDoctor ?? 'Dr. R. Fernando';
              queueItems.addAll([
                {
                  'appointmentId': '',
                  'token': 'T-001',
                  'patientName': 'Kamal Perera',
                  'nic': '842345678V',
                  'phone': '077-123-4567',
                  'department': _effectiveDepartment,
                  'doctor': defaultDoctor,
                  'scheduledTime': '08:30 AM',
                  'status': _localStatusOverrides['T-001'] ?? 'In Consult',
                  'queueNo': 1,
                },
                {
                  'appointmentId': '',
                  'token': 'T-002',
                  'patientName': 'Nimali Bandara',
                  'nic': '917654321V',
                  'phone': '071-987-6543',
                  'department': _effectiveDepartment,
                  'doctor': defaultDoctor,
                  'scheduledTime': '08:45 AM',
                  'status': _localStatusOverrides['T-002'] ?? 'Next',
                  'queueNo': 2,
                },
                {
                  'appointmentId': '',
                  'token': 'T-003',
                  'patientName': 'Suresh Jayawardena',
                  'nic': '952345678V',
                  'phone': '071-234-5678',
                  'department': _effectiveDepartment,
                  'doctor': defaultDoctor,
                  'scheduledTime': '09:00 AM',
                  'status': _localStatusOverrides['T-003'] ?? 'Waiting',
                  'queueNo': 3,
                },
                {
                  'appointmentId': '',
                  'token': 'T-004',
                  'patientName': 'Dilrukshi Fernando',
                  'nic': '895432167V',
                  'phone': '075-345-6789',
                  'department': _effectiveDepartment,
                  'doctor': defaultDoctor,
                  'scheduledTime': '09:15 AM',
                  'status': _localStatusOverrides['T-004'] ?? 'Waiting',
                  'queueNo': 4,
                },
                {
                  'appointmentId': '',
                  'token': 'T-005',
                  'patientName': 'Rohan Wickrama',
                  'nic': '781234567V',
                  'phone': '076-456-7890',
                  'department': _effectiveDepartment,
                  'doctor': defaultDoctor,
                  'scheduledTime': '09:30 AM',
                  'status': _localStatusOverrides['T-005'] ?? 'Absent',
                  'queueNo': 5,
                },
              ]);
            }

            // Identify Currently Serving Patient (status 'In Consult')
            Map<String, dynamic>? currentlyServing = queueItems.firstWhere(
              (item) {
                final st = item['status'].toString().toLowerCase();
                return st == 'in consult' || st == 'in_consult';
              },
              orElse: () => queueItems.isNotEmpty ? queueItems.first : {},
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= 1. CURRENTLY SERVING =================
                  const Text(
                    'CURRENTLY SERVING',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF5BA7A0),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Currently Serving Card
                  InkWell(
                    onTap: currentlyServing.isNotEmpty
                        ? () => _openPatientDetails(
                              appointmentId: currentlyServing['appointmentId'],
                              token: currentlyServing['token'],
                              patientName: currentlyServing['patientName'],
                              nic: currentlyServing['nic'],
                              phone: currentlyServing['phone'],
                              department: currentlyServing['department'],
                              doctor: currentlyServing['doctor'],
                              scheduledTime: currentlyServing['scheduledTime'],
                              currentStatus: currentlyServing['status'],
                            )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBCE3DC), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Token Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBCE3DC)),
                            ),
                            child: Text(
                              currentlyServing['token'] ?? 'T-001',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Patient Name & Doctor
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentlyServing['patientName'] ?? 'No patient in consult',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2E2C),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentlyServing['doctor'] ?? (_selectedDoctor ?? 'Dr. R. Fernando'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5A7C78),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // In Consult Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryTeal,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              currentlyServing['status'] ?? 'In Consult',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= 2. DOCTOR FILTER CARD =================
                  InkWell(
                    onTap: _showDoctorFilterDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6EAE7), width: 1.2),
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
                          const Text(
                            'Doctor: ',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2E2C),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _selectedDoctor ?? 'All Doctors',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007A78),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: primaryTeal,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= 3. QUEUE ORDER =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUEUE ORDER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: primaryTeal,
                        ),
                      ),
                      Text(
                        '${queueItems.length} Patients',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Queue List Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: queueItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = queueItems[index];
                      final waitTime = _calculateWaitTime(index, item['status']);

                      return InkWell(
                        onTap: () => _openPatientDetails(
                          appointmentId: item['appointmentId'],
                          token: item['token'],
                          patientName: item['patientName'],
                          nic: item['nic'],
                          phone: item['phone'],
                          department: item['department'],
                          doctor: item['doctor'],
                          scheduledTime: item['scheduledTime'],
                          currentStatus: item['status'],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                              // Token Badge (Bordered)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primaryTeal,
                                    width: 1.3,
                                  ),
                                ),
                                child: Text(
                                  item['token'],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Patient Name & Wait time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['patientName'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F2E2C),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Wait: $waitTime',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Pill
                              _buildStatusPill(item['status']),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: 2,
        hospital: _effectiveHospital,
      ),
    );
  }
}
