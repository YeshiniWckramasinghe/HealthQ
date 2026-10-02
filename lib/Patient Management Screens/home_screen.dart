import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'appointments_tab.dart';
import '../common Screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted && doc.exists) {
          setState(() {
            _userProfile = doc.data();
          });
          return;
        }
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of HealthQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _HomeTab(
              userProfile: _userProfile,
              onBook: () => setState(() => _index = 1),
              onProfileTap: () => setState(() => _index = 3),
            ),
            AppointmentsTab(onBackToHome: () => setState(() => _index = 0)),
            _buildNotificationsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary300,
        unselectedItemColor: AppColors.gray400,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none), label: 'Notifications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Notifications & Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        const SizedBox(height: 12),
        _notificationCard(
          title: 'OPD Queue System Active',
          body:
              'Real-time queue monitoring is now live across City General Hospital OPD clinics.',
          time: 'Today, 08:00 AM',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        ),
        _notificationCard(
          title: 'National Health Drive Notice',
          body:
              'Please arrive 15 minutes before your estimated queue slot with your Government NIC.',
          time: 'Yesterday',
          icon: Icons.info_outline,
          iconColor: AppColors.primary300,
        ),
      ],
    );
  }

  Widget _notificationCard({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDark,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final user = FirebaseAuth.instance.currentUser;
    final name = _userProfile?['fullName'] ??
        _userProfile?['firstName'] ??
        user?.displayName ??
        'Patient';
    final email = _userProfile?['email'] ?? user?.email ?? 'No email';
    final nic = _userProfile?['nic'] ?? 'Not provided';
    final contact = _userProfile?['contactNo'] ?? 'Not provided';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary300,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary200),
                  ),
                  child: const Text(
                    'Registered Patient',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              children: [
                _profileRow(Icons.badge_outlined, 'NIC Number', nic),
                const Divider(height: 20),
                _profileRow(Icons.phone_outlined, 'Contact Number', contact),
                const Divider(height: 20),
                _profileRow(Icons.email_outlined, 'Email Address', email),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary300),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userProfile;
  final VoidCallback onBook;
  final VoidCallback onProfileTap;

  const _HomeTab({
    required this.userProfile,
    required this.onBook,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = userProfile?['firstName'] ??
        user?.displayName?.split(' ').first ??
        'Patient';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary300,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary500,
                    ),
                  ),
                  const Text(
                    'HealthQ OPD Portal',
                    style: TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.white,
              child: const Icon(
                Icons.notifications_none,
                size: 20,
                color: AppColors.primary500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Banner
        Container(
          height: 130,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.primary400, AppColors.primary200],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'National Health Drive',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get your health checked, join the queue number and consult today.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Announcements',
                  style: TextStyle(color: AppColors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text(
          'UPCOMING APPOINTMENT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 8),

        // Upcoming appointment card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'City General Hospital',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Queue #12',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Text('Dr. Aris Silva — General OPD',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              const Divider(height: 24),
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: AppColors.primary300),
                  SizedBox(width: 6),
                  Text('Today, 10:30 AM',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Spacer(),
                  Text('Est. Wait: 25 mins',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 5,
                  backgroundColor: AppColors.gray100,
                  color: AppColors.primary300,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Consultation in progress',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary400)),
                  Text('Next slot',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.gray400)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick actions
        Row(
          children: [
            _action(Icons.local_hospital_outlined, 'Find\nHospital', onBook),
            const SizedBox(width: 10),
            _action(
                Icons.event_available_outlined, 'Book\nAppointment', onBook),
            const SizedBox(width: 10),
            _action(Icons.folder_open_outlined, 'My\nAppointments', onBook),
          ],
        ),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary300),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary300),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}