import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import 'appointments_tab.dart';
import '../Queue Management Screens/check_in_screen.dart';
import '../Queue Management Screens/queue_status_screen.dart';
import '../common Screens/login_screen.dart';

// ===================================================================
// HEALTHQ NOTIFICATION MODEL
// ===================================================================

class HealthQNotification {
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconColor;

  const HealthQNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconColor,
  });
}

// ===================================================================
// HEALTHQ NOTIFICATION CENTER
// ===================================================================

class HealthQNotificationCenter {
  static final ValueNotifier<List<HealthQNotification>> notifications =
      ValueNotifier<List<HealthQNotification>>([
    const HealthQNotification(
      title: 'OPD Queue System Active',
      body:
          'Real-time queue monitoring is now live across City General Hospital OPD clinics.',
      time: 'Today, 08:00 AM',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    ),
    const HealthQNotification(
      title: 'National Health Drive Notice',
      body:
          'Please arrive 15 minutes before your estimated queue slot with your Government NIC.',
      time: 'Yesterday',
      icon: Icons.info_outline,
      iconColor: AppColors.primary300,
    ),
  ]);

  static void add(HealthQNotification notification) {
    notifications.value = [
      notification,
      ...notifications.value,
    ];
  }

  static void clear() {
    notifications.value = [];
  }
}

// ===================================================================
// HEALTHQ QUEUE STATE
//
// Queue Status screen can update this shared state.
// Home screen will automatically refresh the Queue card.
// ===================================================================

class HealthQQueueState {
  final String queueNumber;
  final String hospital;
  final String doctor;
  final String speciality;
  final String date;
  final String session;
  final int estimatedWaitMinutes;
  final int patientsAhead;
  final String status;
  final bool active;

  const HealthQQueueState({
    required this.queueNumber,
    required this.hospital,
    required this.doctor,
    required this.speciality,
    required this.date,
    required this.session,
    required this.estimatedWaitMinutes,
    required this.patientsAhead,
    required this.status,
    this.active = true,
  });
}

// ===================================================================
// HEALTHQ QUEUE CENTER
//
// QueueStatusScreen can call:
//
// HealthQQueueCenter.update(
//   queueNumber: '#19',
//   hospital: 'City General Hospital',
//   doctor: 'Dr. R. Fernando',
//   speciality: 'Internal Medicine',
//   date: '22 Sep 2026',
//   session: 'Morning (9:00 - 12:00)',
//   estimatedWaitMinutes: 45,
//   patientsAhead: 10,
//   status: 'Waiting',
// );
//
// Home page Queue card will automatically update.
// ===================================================================

class HealthQQueueCenter {
  static final ValueNotifier<HealthQQueueState?> state =
      ValueNotifier<HealthQQueueState?>(null);

  static void update({
    required String queueNumber,
    required String hospital,
    required String doctor,
    required String speciality,
    required String date,
    required String session,
    required int estimatedWaitMinutes,
    required int patientsAhead,
    required String status,
  }) {
    state.value = HealthQQueueState(
      queueNumber: queueNumber,
      hospital: hospital,
      doctor: doctor,
      speciality: speciality,
      date: date,
      session: session,
      estimatedWaitMinutes: estimatedWaitMinutes,
      patientsAhead: patientsAhead,
      status: status,
    );
  }

  static void clear() {
    state.value = null;
  }
}

// ===================================================================
// HOME SCREEN
// ===================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Map<String, dynamic>? _userProfile;

  int _nextQueueNumber = 12;

  CheckInAppointment _currentAppointment =
      const CheckInAppointment(
    appointmentId: '',
    nic: '199012345678',
    hospital: 'City General Hospital',
    date: '22 Sep 2026',
    session: 'Morning (9:00 - 12:00)',
    doctor: 'Dr. S. Perera',
    speciality: 'Internal Medicine',
    patient: 'Patient',
    contact: '',
    dateOfBirth: '',
    estimatedQueueNumber: '#12',
  );

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();

    // Listen for bottom-bar taps coming from the Queue Status screens.
    QueueNavigationCenter.requestedTab
        .addListener(_onQueueTabRequested);
  }

  @override
  void dispose() {
    QueueNavigationCenter.requestedTab
        .removeListener(_onQueueTabRequested);
    super.dispose();
  }

  // =================================================================
  // QUEUE SCREENS -> HOME TAB REQUEST
  //
  // Queue screens bottom bar indexes:
  // 0 = Home, 1 = Appointments, 2 = Queue (Check In), 3 = Alerts
  //
  // These match HomeScreen's internal IndexedStack indexes:
  // 0 = Home, 1 = Appointments, 2 = Check In, 3 = Notifications
  // =================================================================

  void _onQueueTabRequested() {
    final requested =
        QueueNavigationCenter.requestedTab.value;

    if (requested == null || !mounted) return;

    setState(() {
      _index = requested;
    });

    QueueNavigationCenter.requestedTab.value = null;
  }

  // =================================================================
  // FETCH USER PROFILE
  // =================================================================

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
        }
      } catch (e) {
        debugPrint(
          'Error fetching user profile: $e',
        );
      }
    }
  }

  // =================================================================
  // SIGN OUT
  // =================================================================

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of HealthQ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  // =================================================================
  // MAIN NAVIGATION
  // =================================================================

  void _goToHome() {
    setState(() {
      _index = 0;
    });
  }

  void _goToAppointments() {
    setState(() {
      _index = 1;
    });
  }

  void _goToCheckIn() {
    setState(() {
      _index = 2;
    });
  }

  void _goToNotifications() {
    setState(() {
      _index = 3;
    });
  }

  void _goToProfile() {
    setState(() {
      _index = 4;
    });
  }

  // =================================================================
  // QUEUE NUMBER GENERATION
  // =================================================================

  String _generateQueueNumber() {
    final number = _nextQueueNumber;

    _nextQueueNumber++;

    return '#$number';
  }

  CheckInAppointment _withGeneratedQueueNumber(
    CheckInAppointment appointment,
  ) {
    final generatedQueueNumber =
        _generateQueueNumber();

    final updatedAppointment =
        CheckInAppointment(
      appointmentId: appointment.appointmentId,
      nic: appointment.nic,
      hospital: appointment.hospital,
      date: appointment.date,
      session: appointment.session,
      doctor: appointment.doctor,
      speciality: appointment.speciality,
      patient: appointment.patient,
      contact: appointment.contact,
      dateOfBirth: appointment.dateOfBirth,
      estimatedQueueNumber:
          generatedQueueNumber,
    );

    // ---------------------------------------------------------------
    // Keep Home Queue card synchronized with generated queue number.
    // ---------------------------------------------------------------

    HealthQQueueCenter.update(
      queueNumber: generatedQueueNumber,
      hospital: appointment.hospital,
      doctor: appointment.doctor,
      speciality: appointment.speciality,
      date: appointment.date,
      session: appointment.session,
      estimatedWaitMinutes: 25,
      patientsAhead: 5,
      status: 'Waiting',
    );

    return updatedAppointment;
  }

  // =================================================================
  // BOTTOM NAVIGATION INDEX
  //
  // Internal indexes:
  //
  // 0 = Home
  // 1 = Appointments
  // 2 = Check In
  // 3 = Notifications
  // 4 = Profile
  //
  // Bottom bar:
  //
  // 0 = Home
  // 1 = Appointments
  // 2 = Notifications
  // 3 = Profile
  // =================================================================

  int get _bottomNavigationIndex {
    switch (_index) {
      case 1:
        return 1;

      case 3:
        return 2;

      case 4:
        return 3;

      case 2:
      case 0:
      default:
        return 0;
    }
  }

  void _onBottomNavigationTap(
    int selectedIndex,
  ) {
    switch (selectedIndex) {
      case 0:
        _goToHome();
        break;

      case 1:
        _goToAppointments();
        break;

      case 2:
        _goToNotifications();
        break;

      case 3:
        _goToProfile();
        break;
    }
  }

  // =================================================================
  // BUILD
  // =================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,

      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            // =========================================================
            // HOME
            // =========================================================

            _HomeTab(
              userProfile: _userProfile,
              appointment: _currentAppointment,
              onBook: _goToAppointments,
              onCheckIn: _goToCheckIn,
              onProfileTap: _goToProfile,
            ),

            // =========================================================
            // APPOINTMENTS
            // =========================================================

            AppointmentsTab(
              onBackToHome: _goToHome,
              onAppointmentConfirmed: (appointment) {
                final appointmentWithQueue =
                    _withGeneratedQueueNumber(
                  appointment,
                );

                setState(() {
                  _currentAppointment =
                      appointmentWithQueue;

                  _index = 0;
                });
              },
            ),

            // =========================================================
            // CHECK IN
            // =========================================================

            CheckInScreen(
              bookedAppointment:
                  _currentAppointment,

              // -----------------------------------------------------
              // Back button on Check-In screen returns to Home.
              // -----------------------------------------------------
              onBackToHome: _goToHome,

              onCheckIn: (appointment) {
                setState(() {
                  _currentAppointment =
                      appointment;
                });

                // ---------------------------------------------------
                // Synchronize current queue information.
                // ---------------------------------------------------

                final queueNumber =
                    appointment.estimatedQueueNumber.isNotEmpty
                        ? appointment.estimatedQueueNumber
                        : '#${_nextQueueNumber - 1}';

                HealthQQueueCenter.update(
                  queueNumber: queueNumber,
                  hospital: appointment.hospital,
                  doctor: appointment.doctor,
                  speciality: appointment.speciality,
                  date: appointment.date,
                  session: appointment.session,
                  estimatedWaitMinutes: 25,
                  patientsAhead: 5,
                  status: 'Waiting',
                );
              },
            ),

            // =========================================================
            // NOTIFICATIONS
            // =========================================================

            _buildNotificationsTab(),

            // =========================================================
            // PROFILE
            // =========================================================

            _buildProfileTab(),
          ],
        ),
      ),

      // =============================================================
      // SAME BOTTOM NAVIGATION
      // =============================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex:
            _bottomNavigationIndex,
        onTap:
            _onBottomNavigationTap,
        type:
            BottomNavigationBarType.fixed,
        backgroundColor:
            AppColors.white,
        selectedItemColor:
            AppColors.primary300,
        unselectedItemColor:
            AppColors.gray400,
        selectedFontSize:
            11,
        unselectedFontSize:
            11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            activeIcon: Icon(
              Icons.home,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_today_outlined,
            ),
            activeIcon: Icon(
              Icons.calendar_today,
            ),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications_none,
            ),
            activeIcon: Icon(
              Icons.notifications,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            activeIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // =================================================================
  // NOTIFICATIONS TAB
  // =================================================================

  Widget _buildNotificationsTab() {
    return ValueListenableBuilder<
        List<HealthQNotification>>(
      valueListenable:
          HealthQNotificationCenter
              .notifications,
      builder: (
        context,
        notifications,
        child,
      ) {
        return ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            const Text(
              'Notifications & Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.primary500,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            ...notifications.map(
              (notification) {
                return _notificationCard(
                  title:
                      notification.title,
                  body:
                      notification.body,
                  time:
                      notification.time,
                  icon:
                      notification.icon,
                  iconColor:
                      notification.iconColor,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =================================================================
  // NOTIFICATION CARD
  // =================================================================

  Widget _notificationCard({
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color:
            AppColors.white,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(
          color:
              AppColors.gray100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                iconColor,
            size: 22,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.primary500,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  body,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors.textDark,
                    height: 1.35,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  time,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    color:
                        AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // PROFILE TAB
  // =================================================================

  Widget _buildProfileTab() {
    final user =
        FirebaseAuth.instance.currentUser;

    final name =
        _userProfile?['fullName'] ??
            _userProfile?['firstName'] ??
            user?.displayName ??
            'Patient';

    final email =
        _userProfile?['email'] ??
            user?.email ??
            'No email';

    final nic =
        _userProfile?['nic'] ??
            'Not provided';

    final contact =
        _userProfile?['contactNo'] ??
            'Not provided';

    final initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'P';

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),
      child: Column(
        children: [
          // =========================================================
          // PROFILE HEADER
          // =========================================================

          Container(
            padding:
                const EdgeInsets.all(20),
            decoration:
                BoxDecoration(
              color:
                  AppColors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border:
                  Border.all(
                color:
                    AppColors.gray100,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      AppColors.primary300,
                  child: Text(
                    initial,
                    style:
                        const TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.white,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  name,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        AppColors.primary500,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  email,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.gray400,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.primary100,
                    borderRadius:
                        BorderRadius.circular(20),
                    border:
                        Border.all(
                      color:
                          AppColors.primary200,
                    ),
                  ),
                  child:
                      const Text(
                    'Registered Patient',
                    style:
                        TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors.primary400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // =========================================================
          // PROFILE DETAILS
          // =========================================================

          Container(
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              color:
                  AppColors.white,
              borderRadius:
                  BorderRadius.circular(14),
              border:
                  Border.all(
                color:
                    AppColors.gray100,
              ),
            ),
            child: Column(
              children: [
                _profileRow(
                  Icons.badge_outlined,
                  'NIC Number',
                  nic,
                ),

                const Divider(
                  height: 20,
                ),

                _profileRow(
                  Icons.phone_outlined,
                  'Contact Number',
                  contact,
                ),

                const Divider(
                  height: 20,
                ),

                _profileRow(
                  Icons.email_outlined,
                  'Email Address',
                  email,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // =========================================================
          // LOG OUT
          // =========================================================

          SizedBox(
            width:
                double.infinity,
            child:
                OutlinedButton.icon(
              onPressed:
                  _signOut,
              icon:
                  const Icon(
                Icons.logout,
                color:
                    Colors.red,
              ),
              label:
                  const Text(
                'Log Out',
                style:
                    TextStyle(
                  color:
                      Colors.red,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                side:
                    BorderSide(
                  color:
                      Colors.red.shade300,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================================
  // PROFILE ROW
  // =================================================================

  Widget _profileRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
              AppColors.primary300,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 10,
                  color:
                      AppColors.gray400,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      AppColors.primary500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// HOME TAB
// ===================================================================

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  final CheckInAppointment appointment;

  final VoidCallback onBook;

  final VoidCallback onCheckIn;

  final VoidCallback onProfileTap;

  const _HomeTab({
    required this.userProfile,
    required this.appointment,
    required this.onBook,
    required this.onCheckIn,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    final name =
        userProfile?['firstName'] ??
            user?.displayName
                ?.split(' ')
                .first ??
            'Patient';

    final initial =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'P';

    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        // ===========================================================
        // HEADER
        // ===========================================================

        Row(
          children: [
            GestureDetector(
              onTap:
                  onProfileTap,
              child:
                  CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.primary300,
                child: Text(
                  initial,
                  style:
                      const TextStyle(
                    color:
                        AppColors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                      color:
                          AppColors.primary500,
                    ),
                  ),

                  const Text(
                    'HealthQ OPD Portal',
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            const CircleAvatar(
              radius: 18,
              backgroundColor:
                  AppColors.white,
              child:
                  Icon(
                Icons.notifications_none,
                size: 20,
                color:
                    AppColors.primary500,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        // ===========================================================
        // BANNER
        // ===========================================================

        Container(
          height: 130,
          padding:
              const EdgeInsets.all(14),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            gradient:
                const LinearGradient(
              colors: [
                AppColors.primary400,
                AppColors.primary200,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'National Health Drive',
                style:
                    TextStyle(
                  color:
                      AppColors.white,
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Get your health checked, join the queue number and consult today.',
                style:
                    TextStyle(
                  color:
                      AppColors.white.withValues(
                    alpha: 0.85,
                  ),
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary300,
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child:
                    const Text(
                  'Announcements',
                  style:
                      TextStyle(
                    color:
                        AppColors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // ===========================================================
        // UPCOMING APPOINTMENT TITLE
        // ===========================================================

        const Text(
          'UPCOMING APPOINTMENT',
          style:
              TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.bold,
            color:
                AppColors.gray400,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        // ===========================================================
        // UPCOMING APPOINTMENT CARD
        // ===========================================================

        ValueListenableBuilder<HealthQQueueState?>(
          valueListenable:
              HealthQQueueCenter.state,
          builder: (
            context,
            queueState,
            child,
          ) {
            final queueNumber =
                queueState?.queueNumber ??
                    (appointment.estimatedQueueNumber.isNotEmpty
                        ? appointment.estimatedQueueNumber
                        : '#--');

            final hospital =
                queueState?.hospital ??
                    appointment.hospital;

            final doctor =
                queueState?.doctor ??
                    appointment.doctor;

            final speciality =
                queueState?.speciality ??
                    appointment.speciality;

            final date =
                queueState?.date ??
                    appointment.date;

            final session =
                queueState?.session ??
                    appointment.session;

            final waitMinutes =
                queueState?.estimatedWaitMinutes ??
                    25;

            final patientsAhead =
                queueState?.patientsAhead ??
                    5;

            final queueStatus =
                queueState?.status ??
                    'Waiting';

            return Container(
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.white,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            Text(
                          hospital,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                            color:
                                AppColors.primary500,
                          ),
                        ),
                      ),

                      // =============================================
                      // QUEUE BUTTON
                      // =============================================

                      Material(
                        color:
                            Colors.transparent,
                        child:
                            InkWell(
                          onTap:
                              onCheckIn,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          child:
                              Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.primary300,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child:
                                Text(
                              'Queue $queueNumber',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors.white,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    '$doctor — $speciality',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AppColors.gray400,
                    ),
                  ),

                  const Divider(
                    height: 24,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color:
                            AppColors.primary300,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Expanded(
                        child:
                            Text(
                          '$date · $session',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        'Est. Wait: $waitMinutes mins',
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              AppColors.gray400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(4),
                    child:
                        LinearProgressIndicator(
                      value:
                          patientsAhead <= 0
                              ? 1.0
                              : (1 -
                                      (patientsAhead /
                                          (patientsAhead +
                                              10)))
                                  .clamp(
                                  0.0,
                                  1.0,
                                ),
                      minHeight:
                          5,
                      backgroundColor:
                          AppColors.gray100,
                      color:
                          AppColors.primary300,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        queueStatus ==
                                'Waiting'
                            ? 'Consultation in progress'
                            : queueStatus,
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppColors.primary400,
                        ),
                      ),

                      Text(
                        '$patientsAhead ahead',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          color:
                              AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(
          height: 16,
        ),

        // ===========================================================
        // QUICK ACTIONS
        // ===========================================================

        Row(
          children: [
            _action(
              Icons.local_hospital_outlined,
              'Find\nHospital',
              onBook,
            ),

            const SizedBox(
              width: 10,
            ),

            _action(
              Icons.event_available_outlined,
              'Book\nAppointment',
              onBook,
            ),

            const SizedBox(
              width: 10,
            ),

            _action(
              Icons.folder_open_outlined,
              'My\nAppointments',
              onBook,
            ),
          ],
        ),
      ],
    );
  }

  // =================================================================
  // QUICK ACTION
  // =================================================================

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(12),
        child:
            Container(
          height: 90,
          decoration:
              BoxDecoration(
            color:
                AppColors.white,
            borderRadius:
                BorderRadius.circular(12),
            border:
                Border.all(
              color:
                  AppColors.primary300,
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    AppColors.primary300,
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                label,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      AppColors.primary500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}