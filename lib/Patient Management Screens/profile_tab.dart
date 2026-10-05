import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../common Screens/login_screen.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onHistory;

  const ProfileTab({super.key, required this.onBack, required this.onHistory});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final Stream<UserProfile> _stream = BookingService().myProfile();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  String _dob(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso.isEmpty ? '-' : iso;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _v(String s) => s.isEmpty ? '-' : s;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
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
          Expanded(
            child: StreamBuilder<UserProfile>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Could not load profile',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.gray400)));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final u = snap.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.primary200,
                            child: Text(u.initials,
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName.isEmpty ? 'Your name' : u.fullName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500)),
                                const SizedBox(height: 2),
                                Text('NIC: ${_v(u.nic)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray400)),
                              ],
                            ),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.primary200.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            _row('Full Name', _v(u.fullName)),
                            _row('NIC', _v(u.nic)),
                            _row('DOB', _dob(u.dob)),
                            _row('Gmail', _v(u.email)),
                            _row('Contact', _v(u.contact)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _btn('Back', widget.onBack),
          const SizedBox(height: 10),
          _btn('Appointments History', widget.onHistory),
          const SizedBox(height: 10),
          _btn('Log out', _logout),
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
            Flexible(
              child: Text(v,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
            ),
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