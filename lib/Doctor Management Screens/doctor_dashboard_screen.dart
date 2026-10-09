import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common Screens/login_screen.dart';
import '../common Screens/staff_login_screen.dart';
import '../services/doctor_profile_service.dart';
import '../services/doctor_service.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_home_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_queue_screen.dart';
import 'doctor_ui.dart';

/// Entry point of the doctor module (called from terms_screen.dart - the
/// constructor is unchanged).
///
/// Structure: each bottom tab owns its own Navigator, so detail screens
/// (patient details, consultation, availability ...) open INSIDE the tab and
/// the bottom bar stays visible, exactly like the designs. Every screen reads
/// the logged-in doctor from [DoctorSessionScope].
class DoctorDashboardScreen extends StatefulWidget {
  final String doctorName;
  final String? staffId;
  final String? hospital;
  final String? specialty;
  final String? room;

  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'Dr. S. Perera',
    this.staffId = 'DOC1001-0001',
    this.hospital = 'Government Hospital — Colombo',
    this.specialty = 'General Medicine',
    this.room = 'Room 01',
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  static final List<WidgetBuilder> _roots = <WidgetBuilder>[
    (_) => const DoctorHomeScreen(),
    (_) => const DoctorAppointmentsScreen(),
    (_) => const DoctorQueueScreen(),
    (_) => const DoctorProfileScreen(),
  ];

  int _index = 0;

  /// Tabs are built lazily on first visit, then kept alive.
  final List<bool> _visited = <bool>[true, false, false, false];
  final List<GlobalKey<NavigatorState>> _navKeys =
      List<GlobalKey<NavigatorState>>.generate(
          4, (_) => GlobalKey<NavigatorState>());

  late final DoctorProfile _fallback;
  late final Stream<DoctorProfile> _profileStream;
  late final String _today;
  DoctorProfile? _latest;
  StreamSubscription<dynamic>? _bookingSync;

  @override
  void initState() {
    super.initState();
    _today = DoctorService.todayKey();
    // terms_screen only passes name / id / hospital, so everything else
    // (specialty, room, email, phone ...) is loaded live from Firestore by
    // the profile stream. These values are just the instant first paint.
    _fallback = DoctorProfile(
      staffId: widget.staffId ?? 'DOC1001-0001',
      name: widget.doctorName,
      specialty: widget.specialty ?? 'General Medicine',
      hospital: widget.hospital ?? 'Government Hospital — Colombo',
      room: widget.room ?? 'Room 01',
    );
    _profileStream = DoctorProfileService.instance.profileStream(_fallback);
    _start();
  }

  Future<void> _start() async {
    try {
      await DoctorService.instance.bootstrap(_fallback);
      if (!mounted) return;
      _bookingSync = DoctorService.instance.startBookingSync(
        date: _today,
        profile: () => _latest ?? _fallback,
        onLinked: (bookingDoctorId) => DoctorProfileService.instance
            .linkBookingDoctor((_latest ?? _fallback).staffId, bookingDoctorId),
      );
    } catch (e) {
      debugPrint('DoctorDashboard start: $e');
    }
  }

  @override
  void dispose() {
    _bookingSync?.cancel();
    super.dispose();
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _switchTab(int i) {
    if (i < 0 || i > 3) return;
    setState(() {
      _visited[i] = true;
      _index = i;
    });
  }

  void _onTabTap(int i) {
    if (i == _index) {
      // Tapping the active tab returns to its root screen.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      _switchTab(i);
    }
  }

  /// Android back button: close a detail screen first, then go to Home, and
  /// only then leave the app.
  void _handleBack() {
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    SystemNavigator.pop();
  }

  Future<void> _confirmLogout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      danger: true,
    );
    if (!ok || !mounted) return;

    // Rebuild the same stack the staff flow normally has
    // (LoginScreen -> StaffLoginScreen) so the "Back to Patient Login"
    // button on the staff screen still works.
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    nav.push(MaterialPageRoute<void>(builder: (_) => const StaffLoginScreen()));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DoctorProfile>(
      stream: _profileStream,
      initialData: _fallback,
      builder: (context, snap) {
        final profile = snap.data ?? _fallback;
        _latest = profile;

        return DoctorSessionScope(
          profile: profile,
          today: _today,
          switchTab: _switchTab,
          logout: _confirmLogout,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _handleBack();
            },
            child: Scaffold(
              backgroundColor: DoctorColors.bg,
              body: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < 4; i++)
                    _visited[i]
                        ? _TabNavigator(navKey: _navKeys[i], rootBuilder: _roots[i])
                        : const SizedBox.shrink(),
                ],
              ),
              bottomNavigationBar: _BottomBar(
                index: _index,
                onTap: _onTabTap,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One Navigator per tab. HeroControllerScope.none avoids Flutter's
/// "A HeroController can not be shared by multiple Navigators" assertion that
/// otherwise fires when several nested Navigators live under one MaterialApp.
class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navKey;
  final WidgetBuilder rootBuilder;

  const _TabNavigator({required this.navKey, required this.rootBuilder});

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope.none(
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: rootBuilder,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: DoctorColors.teal,
        unselectedItemColor: DoctorColors.muted,
        selectedLabelStyle:
            const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today_rounded),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
