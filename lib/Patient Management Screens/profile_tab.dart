import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../common Screens/login_screen.dart';

class ProfileTab extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onHistory;

  const ProfileTab({super.key, required this.onBack, required this.onHistory});

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500)),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary200,
                child: Text('KP',
                    style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kasun Perera',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500)),
                  SizedBox(height: 2),
                  Text('NIC: 199012345678',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.gray400)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('DETAILS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray400)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary200.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                _row('Full Name', 'Kasun Perera'),
                _row('NIC', '199012345678'),
                _row('DOB', '15 March 1990'),
                _row('Gmail', 'kasun@gmail.com'),
                _row('Contact', '+94 71 234 5678'),
              ],
            ),
          ),
          const Spacer(),
          _btn('Back', onBack),
          const SizedBox(height: 10),
          _btn('Appointments History', onHistory),
          const SizedBox(height: 10),
          _btn('Log out', () => _logout(context)),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            Text(v,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500)),
          ],
        ),
      );

  Widget _btn(String t, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary300,
            side: const BorderSide(color: AppColors.primary300, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}