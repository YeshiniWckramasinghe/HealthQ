import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'doctor_dashboard_screen.dart';

class DoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const DoctorBottomNav({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  void _onTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index == currentIndex) return;

    // Navigate to DoctorDashboard with the selected tab
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DoctorDashboardScreen(initialNavIndex: index),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(context, 1, Icons.calendar_today_outlined, Icons.calendar_today, 'Appointments'),
              _buildNavItem(context, 2, Icons.format_list_bulleted_outlined, Icons.format_list_bulleted, 'Queue'),
              _buildNavItem(context, 3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? AppColors.primary400 : AppColors.gray400;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
