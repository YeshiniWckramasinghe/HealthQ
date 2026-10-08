import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import 'appointments_tab.dart';
import 'notifications_tab.dart';
import 'profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _apptKey = GlobalKey<AppointmentsTabState>();
  final _service = BookingService();
  late final _appointments = _service.myAppointments();
  late final _profile = _service.myProfile();

  void _openHistory() {
    _apptKey.currentState?.showHistory();
    setState(() => _index = 1);
  }

  void _openFindHospital() {
    _apptKey.currentState?.openFindHospital();
    setState(() => _index = 1);
  }

  void _openBookAppointment() {
    _apptKey.currentState?.openBookAppointment();
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Inside the booking flow: go back one step
        if (_index == 1 && (_apptKey.currentState?.goBack() ?? false)) return;
        // Any other tab: go to Home first
        if (_index != 0) {
          setState(() => _index = 0);
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _HomeTab(
              appointments: _appointments,
              profile: _profile,
              onFindHospital: _openFindHospital,
              onBook: _openBookAppointment,
              onHistory: _openHistory,
              onNotifications: () => setState(() => _index = 2),
            ),
            AppointmentsTab(key: _apptKey, onBackToHome: () => setState(() => _index = 0)),
            const NotificationsTab(),
            ProfileTab(
              onBack: () => setState(() => _index = 0),
              onHistory: () {
                _apptKey.currentState?.showHistory();
                setState(() => _index = 1);
              },
            ),
          ],
        ),
      ),
      // hide the bottom bar while the keyboard is open
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == 1) {
            _openBookAppointment();
          } else {
            setState(() => _index = i);
          }
        },
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
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Stream<List<AppointmentRecord>> appointments;
  final Stream<UserProfile> profile;
  final VoidCallback onFindHospital, onBook, onHistory, onNotifications;

  const _HomeTab({
    required this.appointments,
    required this.profile,
    required this.onFindHospital,
    required this.onBook,
    required this.onHistory,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            StreamBuilder<UserProfile>(
              stream: profile,
              builder: (context, snap) {
                final u = snap.data;
                if (u != null && u.photoBase64.isNotEmpty) {
                  try {
                    final raw = u.photoBase64.contains(',')
                        ? u.photoBase64.split(',')[1]
                        : u.photoBase64;
                    return CircleAvatar(
                      radius: 16,
                      backgroundImage: MemoryImage(base64Decode(raw)),
                    );
                  } catch (_) {}
                }
                if (u != null &&
                    u.photoUrl.isNotEmpty &&
                    u.photoUrl.startsWith('http')) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(u.photoUrl),
                  );
                }
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary300,
                  child: Text(snap.data?.initials ?? '',
                      style:
                          const TextStyle(color: AppColors.white, fontSize: 13)),
                );
              },
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
            InkWell(
              onTap: onNotifications,
              customBorder: const CircleBorder(),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.white,
                child: Icon(Icons.notifications_none,
                    size: 18, color: AppColors.primary500),
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

        // Upcoming appointment card (data from Firestore)
        StreamBuilder<List<AppointmentRecord>>(
          stream: appointments,
          builder: (context, snap) {
            if (!snap.hasData) {
              return Container(
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: snap.hasError
                    ? const Text('Could not load appointments',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.gray400))
                    : const CircularProgressIndicator(),
              );
            }
            final upcoming = snap.data!
                .where((a) => a.status == 'upcoming')
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            if (upcoming.isEmpty) {
              return InkWell(
                onTap: onBook,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                      'No upcoming appointment. Tap "Book Appointment" to make one.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                ),
              );
            }
            final a = upcoming.first;
            return Container(
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
                      Expanded(
                        child: Text(a.hospitalName,
                            style: const TextStyle(
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
                        child: Text(
                            'Queue #${a.queueNo.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Text(a.doctorName,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray400)),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: AppColors.primary300),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('${a.dateLabel} · ${a.session}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Text(
                          a.queueNo <= 1
                              ? 'You are first'
                              : 'Est. Wait: ~${(a.queueNo - 1) * 5} mins',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray400)),
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
                          style: TextStyle(
                              fontSize: 10, color: AppColors.gray400)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Quick actions
        Row(
          children: [
            _action(Icons.local_hospital_outlined, 'Find\nHospital', onFindHospital),
            const SizedBox(width: 10),
            _action(Icons.event_available_outlined, 'Book\nAppointment', onBook),
            const SizedBox(width: 10),
            _action(Icons.folder_open_outlined, 'My\nAppointments', onHistory),
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