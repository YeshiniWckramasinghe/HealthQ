import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_dashboard_screen.dart';
import 'appointments_list_screen.dart';

class OpdBottomNav extends StatelessWidget {
  final int currentIndex;

  const OpdBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        (route) => route.isFirst,
      );
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AppointmentsListScreen()),
      );
    } else if (index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Queue Management module'),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OPD Alerts & Notifications'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OpdColors.white,
        border: Border(
          top: BorderSide(color: OpdColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home_outlined, 'Home'),
              _buildNavItem(
                  context, 1, Icons.calendar_today_outlined, 'Appointments'),
              _buildNavItem(
                  context, 2, Icons.format_list_numbered_outlined, 'Queue'),
              _buildNavItem(
                  context, 3, Icons.notifications_none_outlined, 'Alerts'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    final Color color =
        isSelected ? OpdColors.primary300 : OpdColors.textMuted;

    return InkWell(
      onTap: () => _onTap(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
