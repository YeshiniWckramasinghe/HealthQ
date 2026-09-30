import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppointmentsTab extends StatefulWidget {
  /// Called when the user taps "Back to Home" on the confirmation screen.
  final VoidCallback? onBackToHome;
  const AppointmentsTab({super.key, this.onBackToHome});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  // 0 = hospital list, 1..3 = booking steps, 4 = history
  int _step = 0;

  void _go(int s) => setState(() => _step = s);

  @override
  Widget build(BuildContext context) {
    final pages = [_hospitals(), _details(), _patient(), _confirm(), _history()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: pages[_step],
    );
  }

  // ---------- Screen 2: hospital list ----------
  Widget _hospitals() {
    const items = [
      ('City General Hospital', 'OPD Open', Colors.green),
      ('District Hospital', 'Full', Colors.red),
      ('Teaching Hospital', '3 slots left', Colors.orange),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking'),
        const SizedBox(height: 12),
        _search(),
        const SizedBox(height: 14),
        _label('HOSPITAL DETAILS'),
        Row(
          children: [
            Expanded(child: _dropdown('Province')),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('District')),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('City')),
          ],
        ),
        const SizedBox(height: 14),
        _label('HOSPITAL AVAILABILITY'),
        Expanded(
          child: ListView(
            children: [
              for (final h in items)
                _card(
                  onTap: () => _go(1),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.local_hospital_outlined,
                            size: 16, color: AppColors.primary300),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.$1,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500)),
                            Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: h.$3),
                                const SizedBox(width: 4),
                                Text(h.$2,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray400)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.gray400),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _primaryBtn('Book Appointment', () => _go(1)),
      ],
    );
  }

  // ---------- Screen 3: step 1 ----------
  Widget _details() {
    const doctors = [
      ('Dr. S. Perera', 'Internal Medicine', '8 waiting'),
      ('Dr. R. Fernando', 'General Surgery', '14 waiting'),
      ('Dr. M. Silva', 'Paediatrics', '3 waiting'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking', step: '1 / 3'),
        const SizedBox(height: 12),
        _search(),
        const SizedBox(height: 14),
        _label('APPOINTMENT DETAILS'),
        _field('City General Hospital', trailing: Icons.keyboard_arrow_down),
        const SizedBox(height: 8),
        _field('22 Sep 2026', leading: Icons.calendar_today_outlined),
        const SizedBox(height: 8),
        _field('Morning', trailing: Icons.keyboard_arrow_down),
        const SizedBox(height: 14),
        _label('DOCTOR AVAILABILITY & QUEUE'),
        Expanded(
          child: ListView(
            children: [
              for (final d in doctors)
                _card(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.$1,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500)),
                            Text(d.$2,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.gray400)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(d.$3,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary400)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _primaryBtn('Next', () => _go(2)),
      ],
    );
  }

  // ---------- Screen 4: step 2 ----------
  Widget _patient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking', step: '2 / 3'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 130,
            width: double.infinity,
            color: AppColors.primary200.withValues(alpha: 0.3),
            // Replace with Image.asset('assets/images/onboard_1.jpg', fit: BoxFit.cover)
            child: const Icon(Icons.medical_services_outlined,
                size: 48, color: AppColors.primary300),
          ),
        ),
        const SizedBox(height: 14),
        _label('PATIENT DETAILS'),
        _input('NIC number'),
        const SizedBox(height: 8),
        _input('Full name'),
        const SizedBox(height: 8),
        _input('Date of birth'),
        const SizedBox(height: 8),
        _input('Contact number', keyboard: TextInputType.phone),
        const Spacer(),
        _primaryBtn('Next', () => _go(3)),
        const SizedBox(height: 8),
        _outlineBtn('Back', () => _go(1)),
      ],
    );
  }

  // ---------- Screen 5: step 3 ----------
  Widget _confirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking', step: '3 / 3'),
        const SizedBox(height: 12),
        _label('CONFIRM APPOINTMENT'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _row('Hospital', 'City General Hospital'),
              _row('Date', '2026-09-22'),
              _row('Session', 'Morning (9:00 - 12:00)'),
              _row('Doctor', 'Dr. S. Perera'),
              _row('Speciality', 'Internal Medicine'),
              _row('Patient', 'Kasun Perera'),
              _row('NIC', '199012345678'),
              _row('Contact', '+94 71 234 5678'),
              _row('Est. Queue No.', '#09', highlight: true),
            ],
          ),
        ),
        const Spacer(),
        _primaryBtn('Confirm Appointment', _showConfirmed),
        const SizedBox(height: 8),
        _outlineBtn('Back', () => _go(2)),
      ],
    );
  }

  // ---------- Confirmed (full screen, no bottom nav) ----------
  void _showConfirmed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConfirmedScreen(
          queue: '#09',
          summary: 'City General Hospital · 22 Sep 2026',
          onViewAppointments: () {
            Navigator.of(context).pop();
            _go(4);
          },
          onBackToHome: () {
            Navigator.of(context).pop();
            _go(0);
            widget.onBackToHome?.call();
          },
        ),
      ),
    );
  }

  // ---------- Appointments history ----------
  Widget _history() {
    const items = [
      ('City General Hospital', 'Upcoming', 'Dr. S. Perera', '22 Sep 2026', '#09'),
      ('Teaching Hospital', 'Completed', 'Dr. R. Fernando', '15 Sep 2026', '#22'),
      ('District Hospital', 'Completed', 'Dr. M. Silva', '03 Sep 2026', '#04'),
      ('City General Hospital', 'Cancelled', 'Dr. K. Jayasinghe', '18 Aug 2026', '#17'),
      ('Teaching Hospital', 'Completed', 'Dr. S. Perera', '01 Aug 2026', '#31'),
    ];
    Color bg(String s) => switch (s) {
          'Upcoming' => AppColors.primary100,
          'Completed' => Colors.green.shade50,
          _ => Colors.red.shade50,
        };
    Color fg(String s) => switch (s) {
          'Upcoming' => AppColors.primary300,
          'Completed' => Colors.green.shade700,
          _ => Colors.red.shade700,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointments History'),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final a in items)
                _card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(a.$1,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary500)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg(a.$2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(a.$2,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: fg(a.$2))),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.$3,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500)),
                                Text(a.$4,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray400)),
                              ],
                            ),
                          ),
                          Text('Queue ${a.$5}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary500)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Shared widgets ----------
  Widget _header(String title, {String? step}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary400)),
        ),
        if (step != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              border: Border.all(color: AppColors.primary200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Step $step',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary400)),
          ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.gray400)),
      );

  Widget _search() => TextField(
        decoration: InputDecoration(
          hintText: 'Search clinic, hospital...',
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
          prefixIcon: const Icon(Icons.search, size: 18),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary300),
          ),
        ),
      );

  Widget _dropdown(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_downward, size: 12),
          ],
        ),
      );

  Widget _field(String t, {IconData? leading, IconData? trailing}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary300),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, size: 16, color: AppColors.primary300),
              const SizedBox(width: 8),
            ],
            Expanded(
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500))),
            if (trailing != null) Icon(trailing, size: 18),
          ],
        ),
      );

  Widget _input(String hint, {TextInputType? keyboard}) => TextField(
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary300),
          ),
        ),
      );

  Widget _card({required Widget child, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray100),
            ),
            child: child,
          ),
        ),
      );

  Widget _row(String k, String v, {bool highlight = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            Text(v,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: highlight
                        ? AppColors.primary300
                        : AppColors.primary500)),
          ],
        ),
      );

  Widget _primaryBtn(String t, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary300,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(t),
        ),
      );

  Widget _outlineBtn(String t, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary300,
            side: const BorderSide(color: AppColors.primary300),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(t),
        ),
      );
}


class _ConfirmedScreen extends StatelessWidget {
  final String queue;
  final String summary;
  final VoidCallback onViewAppointments;
  final VoidCallback onBackToHome;

  const _ConfirmedScreen({
    required this.queue,
    required this.summary,
    required this.onViewAppointments,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary200.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary200,
                    ),
                    child: const Icon(Icons.done_all,
                        size: 36, color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Appointment Confirmed!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
              const SizedBox(height: 6),
              const Text('Your queue number is',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              const SizedBox(height: 20),
              Text(queue,
                  style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary300)),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Text(summary,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAppointments,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary300,
                    side: const BorderSide(color: AppColors.primary300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('View My Appointments'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBackToHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary300,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}