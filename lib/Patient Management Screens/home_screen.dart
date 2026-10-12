import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import 'appointments_tab.dart';
import 'notifications_tab.dart';
import 'profile_tab.dart';
import '../Queue Management Screens/check_in_screen.dart';
import '../Queue Management Screens/queue_status_screen.dart';

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

  @override
  void initState() {
    super.initState();
    QueueNavigationCenter.requestedTab.addListener(_onQueueTabRequested);
  }

  void _onQueueTabRequested() {
    final target = QueueNavigationCenter.requestedTab.value;
    if (target != null && mounted) {
      setState(() => _index = target);
    }
  }

  @override
  void dispose() {
    QueueNavigationCenter.requestedTab.removeListener(_onQueueTabRequested);
    super.dispose();
  }

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

  void _openLiveQueue(List<AppointmentRecord> upcomingList) {
    if (upcomingList.isNotEmpty) {
      final a = upcomingList.first;
      if (a.checkedIn) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QueueStatusScreen(appointmentId: a.id),
          ),
        );
        return;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckInScreen(
              bookedAppointment: CheckInAppointment(
                appointmentId: a.id,
                nic: a.nic.isNotEmpty ? a.nic : a.userId,
                hospital: a.hospitalName,
                date: a.dateLabel.isNotEmpty ? a.dateLabel : a.date,
                session: a.session,
                doctor: a.doctorName,
                speciality: '',
                patient: a.patientName,
                contact: a.contact,
                estimatedQueueNumber: a.queueNo.toString(),
              ),
            ),
          ),
        );
        return;
      }
    }
    // If no upcoming appointment, open CheckInScreen so patient can enter NIC
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckInScreen(),
      ),
    );
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
              onLiveQueue: _openLiveQueue,
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

class HomeTab extends StatelessWidget {
  final Stream<List<AppointmentRecord>> appointments;
  final Stream<UserProfile> profile;
  final VoidCallback onFindHospital, onBook, onHistory, onNotifications;
  final void Function(List<AppointmentRecord>)? onLiveQueue;

  const HomeTab({
    super.key,
    required this.appointments,
    required this.profile,
    required this.onFindHospital,
    required this.onBook,
    required this.onHistory,
    required this.onNotifications,
    this.onLiveQueue,
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                  ),
                  _buildQuickActions([]),
                ],
              );
            }
            final upcoming = snap.data!
                .where((a) {
                  final s = a.status.toLowerCase();
                  return s == 'pending' || s == 'confirmed' || s == 'waiting' || s == 'upcoming';
                })
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            if (upcoming.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onBook,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                          'No upcoming appointment. Tap "Book Appointment" to make one.',
                          style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ),
                  ),
                  _buildQuickActions([]),
                ],
              );
            }
            final a = upcoming.first;
            final isPending = a.status.toLowerCase() == 'pending';
            final isCheckedIn = a.checkedIn;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: isCheckedIn
                                  ? const Color(0xFF10B981)
                                  : isPending
                                      ? const Color(0xFFFEF3C7)
                                      : AppColors.primary300,
                              borderRadius: BorderRadius.circular(20),
                              border: isPending
                                  ? Border.all(color: const Color(0xFFFCD34D))
                                  : null,
                            ),
                            child: Text(
                                isCheckedIn
                                    ? 'Checked In · Queue #${a.queueNo.toString().padLeft(2, '0')}'
                                    : isPending
                                        ? 'Pending (#${a.queueNo.toString().padLeft(2, '0')})'
                                        : 'Confirmed · Queue #${a.queueNo.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    color: isPending
                                        ? const Color(0xFFB45309)
                                        : AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text(a.doctorName,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray400)),
                      const Divider(height: 20),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              isCheckedIn
                                  ? 'Live Queue Active'
                                  : isPending
                                      ? 'Pending OPD Confirmation'
                                      : 'Confirmed by OPD',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCheckedIn
                                      ? const Color(0xFF10B981)
                                      : isPending
                                          ? const Color(0xFFD97706)
                                          : AppColors.primary400)),
                          Text('Queue #${a.queueNo.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.gray400)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: isCheckedIn
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QueueStatusScreen(
                                        appointmentId: a.id,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.queue_play_next_rounded, size: 16),
                                label: Text(
                                    'Track Live Queue (#${a.queueNo.toString().padLeft(2, '0')})'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007A78),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                              )
                            : (!isPending)
                                ? ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CheckInScreen(
                                            bookedAppointment: CheckInAppointment(
                                              appointmentId: a.id,
                                              nic: a.nic.isNotEmpty ? a.nic : a.userId,
                                              hospital: a.hospitalName,
                                              date: a.dateLabel.isNotEmpty
                                                  ? a.dateLabel
                                                  : a.date,
                                              session: a.session,
                                              doctor: a.doctorName,
                                              speciality: '',
                                              patient: a.patientName,
                                              contact: a.contact,
                                              estimatedQueueNumber:
                                                  a.queueNo.toString(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.how_to_reg_rounded, size: 16),
                                    label: const Text('Check In to Queue'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF007A78),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)),
                                    ),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Appointment pending OPD confirmation. You can check in once confirmed.'),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.hourglass_top_rounded,
                                        size: 16, color: Color(0xFFD97706)),
                                    label: const Text(
                                      'Awaiting OPD Confirmation',
                                      style: TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFFCD34D)),
                                      backgroundColor: const Color(0xFFFEF3C7),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
                _buildQuickActions(upcoming),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(List<AppointmentRecord> upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'MAIN SERVICES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.gray400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        // Row 1: Find Hospital & Book Appointment
        Row(
          children: [
            _action(
              icon: Icons.local_hospital_rounded,
              iconColor: const Color(0xFF007471),
              iconBgColor: const Color(0xFFE0F2F1),
              label: 'Find Hospital',
              subtitle: 'Search OPD hospitals',
              onTap: onFindHospital,
            ),
            const SizedBox(width: 10),
            _action(
              icon: Icons.event_available_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              label: 'Book Appointment',
              subtitle: 'Reserve doctor slot',
              onTap: onBook,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Row 2: My Appointments & Live Queue
        Row(
          children: [
            _action(
              icon: Icons.folder_open_rounded,
              iconColor: const Color(0xFF6D28D9),
              iconBgColor: const Color(0xFFEDE9FE),
              label: 'My Appointments',
              subtitle: 'History & bookings',
              onTap: onHistory,
            ),
            const SizedBox(width: 10),
            _action(
              icon: Icons.queue_play_next_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              label: 'Live Queue',
              subtitle: 'Track waiting & turn',
              onTap: () => onLiveQueue?.call(upcoming),
            ),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE8E7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.gray300,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _HomeTab = HomeTab;