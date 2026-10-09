import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/staff_auth_service.dart';
import 'home_dashboard_screen.dart';
import 'appointments_list_screen.dart';

class OpdBottomNav extends StatelessWidget {
  final int currentIndex;
  final String? hospital;
  final String? nurseId;
  final String? nurseName;
  final String? department;

  const OpdBottomNav({
    super.key,
    required this.currentIndex,
    this.hospital,
    this.nurseId,
    this.nurseName,
    this.department,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) {
      if (index == 0 && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final effectiveHospital = (hospital != null && hospital!.trim().isNotEmpty)
        ? hospital!.trim()
        : StaffAuthService.instance.currentStaff?.hospital;
    final effectiveNurseId = (nurseId != null && nurseId!.trim().isNotEmpty)
        ? nurseId!.trim()
        : StaffAuthService.instance.currentStaff?.staffId;
    final effectiveNurseName = (nurseName != null && nurseName!.trim().isNotEmpty)
        ? nurseName!.trim()
        : StaffAuthService.instance.currentStaff?.name;
    final effectiveDept = (department != null && department!.trim().isNotEmpty)
        ? department!.trim()
        : StaffAuthService.instance.currentStaff?.department;

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeDashboardScreen(
            hospital: effectiveHospital,
            nurseId: effectiveNurseId,
            nurseName: effectiveNurseName,
            department: effectiveDept,
          ),
        ),
        (route) => route.isFirst,
      );
    } else if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentsListScreen(
            hospital: effectiveHospital,
          ),
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentsListScreen(
            initialQueueTab: true,
            hospital: effectiveHospital,
          ),
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
