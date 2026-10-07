import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import '../common Screens/login_screen.dart';
import 'today_appointments_screen.dart';
import 'consultation_queue_screen.dart';
import 'doctor_profile_screen.dart';
import 'patient_details_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String doctorName;
  final String? staffId;
  final String? hospital;
  final int initialNavIndex;

  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'Dr. S. Perera',
    this.staffId = 'DOC1001-0001',
    this.hospital = 'Government Hospital — Colombo',
    this.initialNavIndex = 0,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late int _currentNavIndex;
  final DoctorService _service = DoctorService.instance;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialNavIndex;
    _service.addListener(_onServiceUpdate);

    // Sync profile name/hospital from login if passed
    if (widget.doctorName.isNotEmpty && widget.doctorName != 'Dr. S. Perera') {
      _service.updateDoctorProfile(
        name: widget.doctorName,
        specialty: _service.profile.specialty,
        hospital: widget.hospital ?? _service.profile.hospital,
        email: _service.profile.email,
        phone: _service.profile.phone,
      );
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of the Doctor Portal?'),
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
              backgroundColor: AppColors.primary400,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildDashboardHome(),
          const TodayAppointmentsScreen(showBottomNav: false),
          const ConsultationQueueScreen(showBottomNav: false),
          const DoctorProfileScreen(showBottomNav: false),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================= TAB 0: DASHBOARD HOME =================
  Widget _buildDashboardHome() {
    final nextPatient = _service.nextPatient;
    final totalAppts = _service.totalAppointmentsCount;
    final waitingCount = _service.waitingPatientsCount;
    final inConsultCount = _service.inConsultationCount;
    final completedCount = _service.completedTasksCount;

    final progressValue = totalAppts > 0 ? (completedCount / totalAppts).clamp(0.0, 1.0) : 0.0;
    final progressPercent = (progressValue * 100).toInt();

    // Display first 3 appointments for preview
    final previewList = _service.appointments.take(3).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TOP HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, ${widget.doctorName}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _onLogout,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary400,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ================= 4 STATS CARDS (2x2 GRID) =================
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: const Color(0xFF2F80ED),
                    iconBg: const Color(0xFFEBF3FE),
                    value: '$totalAppts',
                    label: 'Total Appointments',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.access_time_rounded,
                    iconColor: const Color(0xFFF2994A),
                    iconBg: const Color(0xFFFEF5EB),
                    value: '$waitingCount',
                    label: 'Waiting Patients',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.medical_services_outlined,
                    iconColor: const Color(0xFF00A389),
                    iconBg: const Color(0xFFE6F6F3),
                    value: '$inConsultCount',
                    label: 'In Consultation',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF27AE60),
                    iconBg: const Color(0xFFEAF7EE),
                    value: '$completedCount',
                    label: 'Completed Tasks',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ================= TODAY'S OVERVIEW =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 6,
                          backgroundColor: const Color(0xFFE2EFF0),
                          color: AppColors.primary400,
                        ),
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Overview",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount out of $totalAppts Appointments done',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ================= NEXT PATIENT BANNER =================
            const Text(
              'Next Patient',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(height: 10),
            if (nextPatient != null)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PatientDetailsScreen(patient: nextPatient),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary400,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary400.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005653),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nextPatient.time.split(' ').first,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              nextPatient.time.contains('AM') ? 'AM' : 'PM',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextPatient.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Token #${nextPatient.tokenNo} · ${nextPatient.room}',
                              style: const TextStyle(
                                color: Color(0xFFD4ECEA),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No upcoming patient in queue',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ================= TODAY APPOINTMENT =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentNavIndex = 1),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Appointment List Cards
            for (final appt in previewList) ...[
              _buildAppointmentRow(appt),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentRow(DoctorPatientModel appt) {
    Color statusColor;
    Color statusBg;

    switch (appt.status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF27AE60);
        statusBg = const Color(0xFFEAF7EE);
        break;
      case 'in progress':
        statusColor = const Color(0xFFE29500);
        statusBg = const Color(0xFFFEF8E7);
        break;
      case 'next':
        statusColor = const Color(0xFF0284C7);
        statusBg = const Color(0xFFE0F2FE);
        break;
      default:
        statusColor = const Color(0xFFF2994A);
        statusBg = const Color(0xFFFEF5EB);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(patient: appt),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE6F6F4),
              child: Text(
                appt.initials,
                style: const TextStyle(
                  color: AppColors.primary400,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appt.time} · Token #${appt.tokenNo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appt.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary400,
        unselectedItemColor: AppColors.gray400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_outlined),
            activeIcon: Icon(Icons.format_list_bulleted),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }
}
