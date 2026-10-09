import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../services/staff_auth_service.dart';
import 'opd_bottom_nav.dart';
import 'appointment_details_screen.dart';

class AppointmentsListScreen extends StatefulWidget {
  final String? filterDoctor;
  final String? hospital;
  final bool initialQueueTab;

  const AppointmentsListScreen({
    super.key,
    this.filterDoctor,
    this.hospital,
    this.initialQueueTab = false,
  });

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

enum DateFilterMode { all, today, byDate }

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateFilterMode _dateFilterMode = DateFilterMode.all;
  DateTime _selectedDate = DateTime.now();
  String _selectedStatusFilter = 'All';
  String? _activeDoctorFilter;

  @override
  void initState() {
    super.initState();
    _activeDoctorFilter = widget.filterDoctor;
    if (widget.initialQueueTab) {
      _dateFilterMode = DateFilterMode.today;
      _selectedStatusFilter = 'Waiting';
    } else {
      _dateFilterMode = DateFilterMode.all;
      _selectedStatusFilter = 'All';
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  bool _matchesDate(String docDate, String docDateLabel, DateTime targetDate) {
    final clean = docDate.trim();
    final targetIso =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    if (clean == targetIso || clean.startsWith(targetIso)) return true;

    final slashTarget =
        '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';
    final dashTarget =
        '${targetDate.day.toString().padLeft(2, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.year}';
    if (clean == slashTarget || clean == dashTarget) return true;

    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      if (parsed.year == targetDate.year &&
          parsed.month == targetDate.month &&
          parsed.day == targetDate.day) {
        return true;
      }
    }

    final now = DateTime.now();
    final isTodayTarget = targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;
    if (isTodayTarget) {
      final lDate = clean.toLowerCase();
      final lLabel = docDateLabel.toLowerCase();
      if (lDate.contains('today') || lLabel.contains('today')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2028, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: OpdColors.primary400,
              onPrimary: Colors.white,
              onSurface: OpdColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateFilterMode = DateFilterMode.byDate;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OpdColors.primary100,
      appBar: AppBar(
        backgroundColor: OpdColors.primary400,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointments Management',
              style: TextStyle(
                color: OpdColors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _effectiveHospitalDisplay,
              style: const TextStyle(
                color: Color(0xFFD1E8E6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    decoration: InputDecoration(
                      hintText: 'Search by Token, Patient Name, NIC, or Doctor...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: OpdColors.textMuted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: OpdColors.primary300,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Active Doctor filter banner if present
                if (_activeDoctorFilter != null && _activeDoctorFilter!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14, color: Color(0xFF0369A1)),
                        const SizedBox(width: 6),
                        Text(
                          'Filtered by: $_activeDoctorFilter',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _activeDoctorFilter = null),
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF0369A1)),
                        ),
                      ],
                    ),
                  ),

                // Segmented Toggle: [All Dates] | [Today] | [By Date: Pick Date]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () => setState(() {
                            _dateFilterMode = DateFilterMode.all;
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dateFilterMode == DateFilterMode.all
                                ? OpdColors.primary400
                                : OpdColors.white,
                            foregroundColor: _dateFilterMode == DateFilterMode.all
                                ? OpdColors.white
                                : OpdColors.primary400,
                            elevation: 0,
                            side: const BorderSide(
                              color: OpdColors.primary300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text(
                            'All Dates',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () => setState(() {
                            _dateFilterMode = DateFilterMode.today;
                            _selectedDate = DateTime.now();
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dateFilterMode == DateFilterMode.today
                                ? OpdColors.primary400
                                : OpdColors.white,
                            foregroundColor: _dateFilterMode == DateFilterMode.today
                                ? OpdColors.white
                                : OpdColors.primary400,
                            elevation: 0,
                            side: const BorderSide(
                              color: OpdColors.primary300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setState(() => _dateFilterMode = DateFilterMode.byDate);
                            await _pickDate();
                          },
                          icon: Icon(
                            Icons.calendar_month,
                            size: 13,
                            color: _dateFilterMode == DateFilterMode.byDate
                                ? OpdColors.white
                                : OpdColors.primary400,
                          ),
                          label: Text(
                            _dateFilterMode == DateFilterMode.byDate
                                ? '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                                : 'By Date',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _dateFilterMode == DateFilterMode.byDate
                                ? OpdColors.primary400
                                : OpdColors.white,
                            foregroundColor: _dateFilterMode == DateFilterMode.byDate
                                ? OpdColors.white
                                : OpdColors.primary400,
                            elevation: 0,
                            side: const BorderSide(
                              color: OpdColors.primary300,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Pending'),
                      _buildFilterChip('Confirmed'),
                      _buildFilterChip('Waiting'),
                      _buildFilterChip('In Consult'),
                      _buildFilterChip('Completed'),
                      _buildFilterChip('Cancelled'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Section Label with live count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dateFilterMode == DateFilterMode.today
                          ? "TODAY'S APPOINTMENTS"
                          : _dateFilterMode == DateFilterMode.all
                              ? "ALL HOSPITAL APPOINTMENTS"
                              : "SCHEDULED APPOINTMENTS",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: OpdColors.primary500,
                      ),
                    ),
                    const Text(
                      'Live Cloud Firestore',
                      style: TextStyle(
                        fontSize: 10,
                        color: OpdColors.primary300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Real-time Cloud Firestore Appointments Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: OpdColors.primary400),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Database connection note: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final searchQuery = _searchController.text.trim().toLowerCase();

                // Filter docs using real database data
                final filtered = docs.where((doc) {
                  final d = doc.data();
                  final docDate = (d['date'] ?? '').toString().trim();
                  final docDateLabel = (d['dateLabel'] ?? '').toString().trim();
                  final docStatus = (d['status'] ?? 'Waiting').toString().trim();
                  final docDoctor = (d['doctorName'] ?? d['doctor'] ?? '').toString().trim();
                  final docHospital = (d['hospitalName'] ?? d['hospital'] ?? '').toString().trim();
                  final docHospitalId = (d['hospitalIdentificationNo'] ??
                          d['hospitalCode'] ??
                          d['hospitalId'] ??
                          '')
                      .toString()
                      .trim();

                  // 1. STRICT HOSPITAL FILTER:
                  // Only display appointments belonging to the staff member's registered hospital.
                  final targetHosp = _effectiveHospital;
                  final targetCode = _effectiveHospitalCode;
                  final matchesHospital = Hospital.matchesHospital(
                    targetHospital: targetHosp,
                    targetCode: targetCode,
                    itemHospital: docHospital,
                    itemCode: docHospitalId,
                  );
                  if (!matchesHospital) {
                    return false; // MUST EXCLUDE OTHER HOSPITALS
                  }

                  // 2. Doctor filter
                  if (_activeDoctorFilter != null && _activeDoctorFilter!.isNotEmpty) {
                    if (!docDoctor.toLowerCase().contains(_activeDoctorFilter!.toLowerCase())) {
                      return false;
                    }
                  }

                  // 3. Status filter
                  if (_selectedStatusFilter != 'All') {
                    final sel = _selectedStatusFilter.toLowerCase();
                    final cur = docStatus.toLowerCase();
                    if (sel == 'pending') {
                      if (cur != 'pending') return false;
                    } else if (sel == 'confirmed') {
                      if (cur != 'confirmed' && cur != 'waiting' && cur != 'upcoming') return false;
                    } else if (sel == 'waiting') {
                      if (cur != 'waiting' && cur != 'confirmed' && cur != 'upcoming') return false;
                    } else if (cur != sel) {
                      return false;
                    }
                  }

                  // 4. Date filter
                  if (_dateFilterMode == DateFilterMode.today) {
                    if (!_matchesDate(docDate, docDateLabel, DateTime.now())) {
                      return false;
                    }
                  } else if (_dateFilterMode == DateFilterMode.byDate) {
                    if (!_matchesDate(docDate, docDateLabel, _selectedDate)) {
                      return false;
                    }
                  }

                  // 5. Search text filter (Token, Name, NIC, Doctor)
                  if (searchQuery.isNotEmpty) {
                    final tokenStr = 'T-${(d['queueNo'] ?? '').toString().padLeft(3, '0')}';
                    final nameStr = (d['patientName'] ?? d['name'] ?? '').toString().toLowerCase();
                    final nicStr = (d['nic'] ?? d['userId'] ?? '').toString().toLowerCase();
                    final docStr = docDoctor.toLowerCase();

                    final match = tokenStr.toLowerCase().contains(searchQuery) ||
                        nameStr.contains(searchQuery) ||
                        nicStr.contains(searchQuery) ||
                        docStr.contains(searchQuery);
                    if (!match) return false;
                  }

                  return true;
                }).toList();

                // Sort newest bookings to the top
                filtered.sort((a, b) {
                  final da = a.data();
                  final db = b.data();
                  final ta = da['createdAt'];
                  final tb = db['createdAt'];
                  if (ta is Timestamp && tb is Timestamp) {
                    return tb.compareTo(ta);
                  }
                  final dateA = (da['date'] ?? '').toString();
                  final dateB = (db['date'] ?? '').toString();
                  return dateB.compareTo(dateA);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 54,
                            color: OpdColors.primary300.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No appointments found in database',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: OpdColors.primary500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateFilterMode == DateFilterMode.today
                                ? 'No OPD patients queued for today.'
                                : _dateFilterMode == DateFilterMode.all
                                    ? 'No appointments found for $_effectiveHospital.'
                                    : 'No appointments scheduled for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: OpdColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final d = doc.data();

                    final token = d['queueNo'] != null
                        ? 'T-${d['queueNo'].toString().padLeft(3, '0')}'
                        : (d['token'] ?? 'T-${(index + 1).toString().padLeft(3, '0')}');
                    final patientName = (d['patientName'] ?? d['name'] ?? 'Patient').toString();
                    final nic = (d['nic'] ?? d['userId'] ?? '').toString();
                    final phone = (d['contact'] ?? d['contactNo'] ?? d['phone'] ?? '').toString();
                    final department = (d['speciality'] ?? d['department'] ?? 'General Medicine').toString();
                    final doctor = (d['doctorName'] ?? d['doctor'] ?? 'Doctor').toString();
                    final date = (d['date'] ?? d['dateLabel'] ?? 'Today').toString();
                    final timeSlot = (d['session'] ?? d['timeSlot'] ?? '08:30 AM').toString();
                    final status = (d['status'] ?? 'Waiting').toString();
                    final notes = (d['notes'] ?? 'No notes recorded.').toString();
                    final docHosp = (d['hospitalName'] ?? d['hospital'] ?? '').toString();
                    final docHospId = (d['hospitalIdentificationNo'] ?? d['hospitalCode'] ?? d['hospitalId'] ?? '').toString();

                    return _buildAppointmentCard(
                      context,
                      appointmentId: doc.id,
                      token: token,
                      patientName: patientName,
                      nic: nic,
                      phone: phone,
                      department: department,
                      doctor: doctor,
                      date: date,
                      timeSlot: timeSlot,
                      status: status,
                      notes: notes,
                      hospitalName: docHosp.isNotEmpty ? docHosp : _effectiveHospital,
                      hospitalCode: docHospId.isNotEmpty ? docHospId : _effectiveHospitalCode,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: OpdBottomNav(
        currentIndex: widget.initialQueueTab ? 2 : 1,
        hospital: _effectiveHospital,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedStatusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : OpdColors.primary500,
          ),
        ),
        selected: isSelected,
        selectedColor: OpdColors.primary400,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? OpdColors.primary400 : OpdColors.borderLight,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedStatusFilter = label);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context, {
    required String appointmentId,
    required String token,
    required String patientName,
    required String nic,
    required String phone,
    required String department,
    required String doctor,
    required String date,
    required String timeSlot,
    required String status,
    required String notes,
    String? hospitalName,
    String? hospitalCode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsScreen(
                appointmentId: appointmentId,
                token: token,
                patientName: patientName,
                nic: nic,
                phone: phone,
                department: department,
                doctor: doctor,
                date: date,
                timeSlot: timeSlot,
                status: status,
                notes: notes,
                hospitalName: hospitalName ?? _effectiveHospital,
                hospitalCode: hospitalCode ?? _effectiveHospitalCode,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              // Token Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: OpdColors.primary100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: OpdColors.primary200.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  token,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: OpdColors.primary400,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: OpdColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$doctor • $timeSlot',
                      style: const TextStyle(
                        fontSize: 11,
                        color: OpdColors.textMuted,
                      ),
                    ),
                    if (nic.isNotEmpty)
                      Text(
                        'NIC: $nic',
                        style: const TextStyle(
                          fontSize: 10,
                          color: OpdColors.gray400,
                        ),
                      ),
                  ],
                ),
              ),

              // Status Badge
              _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Pending';
        break;
      case 'confirmed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        label = 'Confirmed';
        break;
      case 'in consult':
      case 'in_consult':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'In Consult';
        break;
      case 'completed':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        label = 'Completed';
        break;
      case 'cancelled':
      case 'absent':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Cancelled';
        break;
      case 'upcoming':
        bg = const Color(0xFFEEF2FF);
        fg = const Color(0xFF4F46E5);
        label = 'Upcoming';
        break;
      case 'waiting':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Waiting';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
