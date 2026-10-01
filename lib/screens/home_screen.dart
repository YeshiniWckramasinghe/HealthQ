import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'appointments_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _HomeTab(onBook: () => setState(() => _index = 1)),
            AppointmentsTab(onBackToHome: () => setState(() => _index = 0)),
            const Center(child: Text('Notifications')),
            const Center(child: Text('Profile')),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
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
}

class _HomeTab extends StatelessWidget {
  final VoidCallback onBook;
  const _HomeTab({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary300,
              child: Text('P',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
            ),
            const Expanded(
              child: Center(
                child: Text('HealthQ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary500)),
              ),
            ),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.white,
              child: Icon(Icons.notifications_none,
                  size: 18, color: AppColors.primary500),
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
              const Text('National Health Drive',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 4),
              Text('Get your health checked, join the queue number and consult today.',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 12)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Announcements',
                    style: TextStyle(color: AppColors.white, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        const Text('UPCOMING APPOINTMENT',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.gray400)),
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
                    child: Text('City General Hospital',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary500)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Queue #12',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Text('Dr. Aris Silva — General OPD',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.primary300),
                  const SizedBox(width: 6),
                  const Text('Today, 10:30 AM',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text('Est. Wait: 25 mins',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.gray400)),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
            _action(Icons.event_available_outlined, 'Book\nAppointment', onBook),
            const SizedBox(width: 10),
            _action(Icons.folder_open_outlined, 'My\nAppointments', () {}),
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
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
            ],
          ),
        ),
      ),
    );
  }
}