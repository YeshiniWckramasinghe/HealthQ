import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import 'patient_details_screen.dart';
import 'doctor_bottom_nav.dart';

class TodayAppointmentsScreen extends StatefulWidget {
  final bool showBottomNav;

  const TodayAppointmentsScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<TodayAppointmentsScreen> createState() => _TodayAppointmentsScreenState();
}

class _TodayAppointmentsScreenState extends State<TodayAppointmentsScreen> {
  final DoctorService _service = DoctorService.instance;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<DoctorPatientModel> get _filteredAppointments {
    final list = _service.appointments;
    return list.where((a) {
      // Filter tab
      final matchesFilter = switch (_selectedFilter) {
        'Scheduled' => a.status.toLowerCase() == 'upcoming' || a.status.toLowerCase() == 'waiting' || a.status.toLowerCase() == 'next',
        'Completed' => a.status.toLowerCase() == 'completed',
        _ => true,
      };

      // Search query
      final matchesSearch = _searchQuery.isEmpty ||
          a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.tokenNo.contains(_searchQuery);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final count = _service.appointments.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // ================= TOP HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.primary400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Appointments",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFormattedDate(),
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

            // ================= FILTER CHIPS =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All', 'All ($count)'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Scheduled', 'Scheduled'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Completed', 'Completed'),
                ],
              ),
            ),

            // ================= SEARCH BAR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search patient name...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ================= APPOINTMENTS LIST =================
            Expanded(
              child: _filteredAppointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 48,
                            color: AppColors.gray300,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No appointments found',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      itemCount: _filteredAppointments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredAppointments[index];
                        return _buildAppointmentCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const DoctorBottomNav(currentIndex: 1)
          : null,
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary400 : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary400 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(DoctorPatientModel item) {
    final isNext = item.name == (_service.nextPatient?.name ?? '') || item.status.toLowerCase() == 'next';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(patient: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNext ? AppColors.primary400 : const Color(0xFFF1F5F9),
            width: isNext ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Teal indicator bar
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Time
            Text(
              item.time.split(' ').first,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 14),

            // Name & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.type} · ${item.room}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            _buildStatusBadge(isNext ? 'Next' : item.status),
            const SizedBox(width: 8),

            // Chevron
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = const Color(0xFFEAF7EE);
        text = const Color(0xFF27AE60);
        break;
      case 'in progress':
        bg = const Color(0xFFFEF8E7);
        text = const Color(0xFFE29500);
        break;
      case 'next':
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        break;
      case 'waiting':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
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
