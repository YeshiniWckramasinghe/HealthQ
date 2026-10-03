import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../Queue Management Screens/check_in_screen.dart';

class AppointmentsTab extends StatefulWidget {
  /// Called when the user taps "Back to Home" on the confirmation screen.
  final VoidCallback? onBackToHome;
  final ValueChanged<CheckInAppointment>? onAppointmentConfirmed;

  const AppointmentsTab({
    super.key,
    this.onBackToHome,
    this.onAppointmentConfirmed,
  });

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  // 0 = hospital list, 1..3 = booking steps, 4 = history
  int _step = 0;

  final _nicController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactController = TextEditingController();

  static const _hospital = 'City General Hospital';
  static const _date = '22 Sep 2026';
  static const _session = 'Morning (9:00 - 12:00)';
  static const _doctor = 'Dr. S. Perera';
  static const _speciality = 'Internal Medicine';
  static const _queue = '#12';

  void _go(int s) => setState(() => _step = s);

  @override
  void dispose() {
    _nicController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  CheckInAppointment _buildAppointment() {
    return CheckInAppointment(
      appointmentId: '',
      nic: _nicController.text.trim().toUpperCase(),
      hospital: _hospital,
      date: _date,
      session: _session,
      doctor: _doctor,
      speciality: _speciality,
      patient: _nameController.text.trim(),
      contact: _contactController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      estimatedQueueNumber: _queue,
    );
  }

  void _confirmAppointment() {
    FocusScope.of(context).unfocus();

    final appointment = _buildAppointment();

    if (appointment.nic.isEmpty ||
        appointment.patient.isEmpty ||
        appointment.contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter NIC, full name and contact number.'),
        ),
      );
      return;
    }

    widget.onAppointmentConfirmed?.call(appointment);
    _showConfirmed(appointment);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _hospitals(),
      _details(),
      _patient(),
      _confirm(),
      _history(),
    ];

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
                        child: const Icon(
                          Icons.local_hospital_outlined,
                          size: 16,
                          color: AppColors.primary300,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.$1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: h.$3,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  h.$2,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _primaryBtn(
          'Book Appointment',
          () => _go(1),
        ),
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
        _header(
          'Appointment Booking',
          step: '1 / 3',
        ),
        const SizedBox(height: 12),
        _search(),
        const SizedBox(height: 14),
        _label('APPOINTMENT DETAILS'),
        _field(
          'City General Hospital',
          trailing: Icons.keyboard_arrow_down,
        ),
        const SizedBox(height: 8),
        _field(
          '22 Sep 2026',
          leading: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 8),
        _field(
          'Morning',
          trailing: Icons.keyboard_arrow_down,
        ),
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
                            Text(
                              d.$1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500,
                              ),
                            ),
                            Text(
                              d.$2,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          d.$3,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _primaryBtn(
          'Next',
          () => _go(2),
        ),
      ],
    );
  }

  // ---------- Screen 4: step 2 ----------

  Widget _patient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          'Appointment Booking',
          step: '2 / 3',
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 130,
            width: double.infinity,
            color: AppColors.primary200.withValues(alpha: 0.3),
            // Replace with Image.asset(
            //   'assets/images/onboard_1.jpg',
            //   fit: BoxFit.cover,
            // )
            child: const Icon(
              Icons.medical_services_outlined,
              size: 48,
              color: AppColors.primary300,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label('PATIENT DETAILS'),
        _input(
          'NIC number',
          controller: _nicController,
        ),
        const SizedBox(height: 8),
        _input(
          'Full name',
          controller: _nameController,
        ),
        const SizedBox(height: 8),
        _input(
          'Date of birth',
          controller: _dobController,
        ),
        const SizedBox(height: 8),
        _input(
          'Contact number',
          controller: _contactController,
          keyboard: TextInputType.phone,
        ),
        const Spacer(),
        _primaryBtn(
          'Next',
          () => _go(3),
        ),
        const SizedBox(height: 8),
        _outlineBtn(
          'Back',
          () => _go(1),
        ),
      ],
    );
  }

  // ---------- Screen 5: step 3 ----------

  Widget _confirm() {
    final appointment = _buildAppointment();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(
          'Appointment Booking',
          step: '3 / 3',
        ),
        const SizedBox(height: 12),
        _label('CONFIRM APPOINTMENT'),
        _card(
          child: Column(
            children: [
              _row(
                'Hospital',
                appointment.hospital,
              ),
              _row(
                'Date',
                appointment.date,
              ),
              _row(
                'Session',
                appointment.session,
              ),
              _row(
                'Doctor',
                appointment.doctor,
              ),
              _row(
                'Speciality',
                appointment.speciality,
              ),
              _row(
                'Patient',
                appointment.patient.isEmpty
                    ? 'Not entered'
                    : appointment.patient,
              ),
              _row(
                'NIC',
                appointment.nic.isEmpty
                    ? 'Not entered'
                    : appointment.nic,
              ),
              _row(
                'Contact',
                appointment.contact.isEmpty
                    ? 'Not entered'
                    : appointment.contact,
              ),
              _row(
                'Date of Birth',
                appointment.dateOfBirth.isEmpty
                    ? 'Not entered'
                    : appointment.dateOfBirth,
              ),
              _row(
                'Estimated Queue',
                appointment.estimatedQueueNumber,
                highlight: true,
              ),
            ],
          ),
        ),
        const Spacer(),
        _primaryBtn(
          'Confirm Appointment',
          _confirmAppointment,
        ),
        const SizedBox(height: 8),
        _outlineBtn(
          'Back',
          () => _go(2),
        ),
      ],
    );
  }

  // ---------- Screen 6: history ----------

  Widget _history() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('My Appointments'),
        const SizedBox(height: 12),
        _label('UPCOMING APPOINTMENT'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_hospital_outlined,
                      size: 18,
                      color: AppColors.primary300,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      _hospital,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusWaitingBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.statusWaitingBorder,
                      ),
                    ),
                    child: const Text(
                      'Waiting',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusWaitingText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _row(
                'Date',
                _date,
              ),
              _row(
                'Session',
                _session,
              ),
              _row(
                'Doctor',
                _doctor,
              ),
              _row(
                'Speciality',
                _speciality,
              ),
              _row(
                'Queue',
                _queue,
                highlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _label('APPOINTMENT HISTORY'),
        Expanded(
          child: ListView(
            children: [
              _card(
                child: Column(
                  children: [
                    _row(
                      'Hospital',
                      'District Hospital',
                    ),
                    _row(
                      'Date',
                      '10 Aug 2026',
                    ),
                    _row(
                      'Doctor',
                      'Dr. R. Fernando',
                    ),
                    _row(
                      'Status',
                      'Completed',
                    ),
                  ],
                ),
              ),
              _card(
                child: Column(
                  children: [
                    _row(
                      'Hospital',
                      'Teaching Hospital',
                    ),
                    _row(
                      'Date',
                      '18 Jul 2026',
                    ),
                    _row(
                      'Doctor',
                      'Dr. M. Silva',
                    ),
                    _row(
                      'Status',
                      'Completed',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _outlineBtn(
          'Book New Appointment',
          () => _go(0),
        ),
      ],
    );
  }

  // ---------- Confirmation ----------

  void _showConfirmed(CheckInAppointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConfirmedScreen(
          queue: appointment.estimatedQueueNumber,
          summary:
              '${appointment.hospital} • ${appointment.date} • ${appointment.doctor}',
          onViewAppointments: () {
            Navigator.of(context).pop();
            setState(() => _step = 4);
          },
          onBackToHome: () {
            Navigator.of(context).pop();
            widget.onBackToHome?.call();
          },
        ),
      ),
    );
  }

  // ---------- Reusable widgets ----------

  Widget _header(
    String title, {
    String? step,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary500,
            ),
          ),
        ),
        if (step != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary300,
              ),
            ),
          ),
      ],
    );
  }

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.gray400,
        ),
      ),
    );
  }

  Widget _search() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search clinic, hospital...',
        hintStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.gray400,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary300,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gray100,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_downward,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String t, {
    IconData? leading,
    IconData? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary300,
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(
              leading,
              size: 16,
              color: AppColors.primary300,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              t,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
          ),
          if (trailing != null)
            Icon(
              trailing,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _input(
    String hint, {
    TextEditingController? controller,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(
        fontSize: 12,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.gray400,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primary300,
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.gray100,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _row(
    String k,
    String v, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray400,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? AppColors.primary300
                  : AppColors.primary500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryBtn(
    String t,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary300,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(t),
      ),
    );
  }

  Widget _outlineBtn(
    String t,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary300,
          side: const BorderSide(
            color: AppColors.primary300,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(t),
      ),
    );
  }
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
                  color: AppColors.primary200.withValues(
                    alpha: 0.2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary200,
                    ),
                    child: const Icon(
                      Icons.done_all,
                      size: 36,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Appointment Confirmed!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your queue number is',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                queue,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary300,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gray100,
                  ),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAppointments,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary300,
                    side: const BorderSide(
                      color: AppColors.primary300,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'View My Appointments',
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}