import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/doctor_service.dart';
import '../common Screens/login_screen.dart';
import 'edit_doctor_profile_screen.dart';
import 'available_time_slots_screen.dart';
import 'availability_requests_screen.dart';
import 'request_availability_change_screen.dart';
import 'doctor_bottom_nav.dart';

class DoctorProfileScreen extends StatefulWidget {
  final bool showBottomNav;

  const DoctorProfileScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _service = DoctorService.instance;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
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
    final profile = _service.profile;
    final pendingCount = _service.pendingRequestsCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  Container(
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
                      Icons.notifications_none_rounded,
                      color: AppColors.primary400,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ================= DOCTOR INFO CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Doctor avatar
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary300, width: 2.5),
                        color: const Color(0xFFE6F6F4),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 52,
                          color: AppColors.primary400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.hospital,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.staffId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary400,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Edit Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditDoctorProfileScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary400, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: AppColors.primary400,
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _onLogout,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: const Color(0xFFDC2626),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ================= AVAILABILITY SUMMARY CARD =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Availability Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Next Active & Total Slots
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.nextActiveDate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Slots',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${profile.totalSlots} Scheduled',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pending Requests Banner
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AvailabilityRequestsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pending Change Requests',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$pendingCount Pending',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= MY AVAILABILITY SECTION =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Availability',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AvailableTimeSlotsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View Calendar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Day selection horizontal cards
              Row(
                children: [
                  Expanded(
                    child: _buildDaySlotCard(
                      index: 0,
                      day: 'Sun',
                      date: '20 Sep',
                      slots: '6 slots',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDaySlotCard(
                      index: 1,
                      day: 'Mon',
                      date: '21 Sep',
                      slots: '4 slots',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDaySlotCard(
                      index: 2,
                      day: 'Tue',
                      date: '22 Sep',
                      slots: '5 slots',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Request Availability Change Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RequestAvailabilityChangeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 20),
                  label: const Text(
                    'Request Availability Change',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary400,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const DoctorBottomNav(currentIndex: 3)
          : null,
    );
  }

  Widget _buildDaySlotCard({
    required int index,
    required String day,
    required String date,
    required String slots,
  }) {
    final isSelected = _selectedDayIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedDayIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary400 : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary400 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFD4ECEA) : AppColors.gray400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.white : AppColors.primary500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slots,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFFD4ECEA) : AppColors.primary400,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
