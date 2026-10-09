import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import 'find_hospital_screen.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _sessions = {
  'Morning': '9:00 - 12:00',
  'Afternoon': '1:00 - 4:00',
  'Evening': '4:00 - 7:00',
};

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
  State<AppointmentsTab> createState() => AppointmentsTabState();
}

class AppointmentsTabState extends State<AppointmentsTab> {
  // 0 = find hospital, 1 = book appointment (step 1/3), 2 = patient, 3 = confirm, 4 = history
  int _step = 1;

  final _service = BookingService();
  List<Hospital> _hospitalList = [];
  List<Doctor> _doctorList = [];
  String? _hospitalId;
  bool _saving = false;
  bool _loadingDoctors = false;
  int _confirmedQueue = 0;
  late final Stream<List<AppointmentRecord>> _historyStream =
      _service.myAppointments();

  @override
  void initState() {
    super.initState();
    _loadHospitals();
    _loadDoctors();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      final nic = (data['nic'] ?? data['userId'] ?? '').toString().trim();
      final name =
          (data['fullName'] ?? user.displayName ?? '').toString().trim();
      final contact = (data['contactNo'] ??
              data['contact'] ??
              user.phoneNumber ??
              '')
          .toString()
          .trim();
      final dobStr = (data['dob'] ?? '').toString().trim();

      setState(() {
        if (_nic.text.isEmpty && nic.isNotEmpty) {
          _nic.text = nic;
        }
        if (_name.text.isEmpty && name.isNotEmpty) {
          _name.text = name;
        }
        if (_contact.text.isEmpty && contact.isNotEmpty) {
          _contact.text = contact;
        }
        if (_dob == null && dobStr.isNotEmpty) {
          try {
            if (dobStr.contains('/')) {
              final p = dobStr.split('/');
              if (p.length == 3) {
                _dob = DateTime(
                    int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
              }
            } else if (dobStr.contains('-')) {
              _dob = DateTime.parse(dobStr);
            }
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Error loading patient profile in booking: $e');
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final list = await _service.getHospitals();
      if (!mounted) return;
      setState(() => _hospitalList = list);
    } catch (_) {}
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() => _loadingDoctors = true);
    try {
      final docs =
          await _service.getDoctors(_hospitalId, hospitalName: _hospital);
      await _service.loadWaiting(_hospitalId, docs, _dateIso, _session);
      if (!mounted) return;
      setState(() {
        _doctorList = docs;
        if (_doctorIdx != null && _doctorIdx! >= docs.length) {
          _doctorIdx = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted) _snack('Could not load doctors from database');
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _refreshWaiting() async {
    if (_doctorList.isEmpty) return;
    try {
      await _service.loadWaiting(_hospitalId, _doctorList, _dateIso, _session);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    if (_saving) return;
    final di = _doctorIdx;
    if (di == null || _dob == null) return;
    final doctor = _doctorList[di];

    Hospital? hospital = _hospitalList
        .where((h) => h.id == _hospitalId || h.name == _hospital)
        .firstOrNull;
    if (hospital == null) {
      if (_hospital != null && _hospital!.isNotEmpty) {
        final hospCode = Hospital.resolveHospitalCode(_hospitalId ?? _hospital);
        hospital = Hospital(
          id: _hospitalId ?? _hospital!.toLowerCase().replaceAll(' ', '_'),
          name: _hospital!,
          identificationNo: hospCode,
          province: '',
          district: '',
          city: '',
          status: 'open',
          slotsLeft: 0,
        );
      } else {
        _snack('Please select a hospital');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final cleanNic = _nic.text.trim().toUpperCase();
      final q = await _service.book(
        hospital: hospital,
        doctor: doctor,
        date: _dateIso,
        dateLabel: _dateLabel,
        session: _session,
        patientName: _name.text.trim(),
        nic: cleanNic,
        userId: cleanNic, // User ID strictly defaults to NIC number
        dob: _dob!.toIso8601String().substring(0, 10),
        contact: _contact.text.trim(),
      );
      if (!mounted) return;
      _confirmedQueue = q;
      _showConfirmed();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  // booking selections
  String? _hospital;
  int? _doctorIdx;
  String _doctorQuery = '';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _session = 'Morning';

  // patient details (step 2)
  final _nic = TextEditingController();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  DateTime? _dob;
  bool _showErrors = false;

  String? get _nicError =>
      RegExp(r'^(\d{9}[vVxX]|\d{12})$').hasMatch(_nic.text.trim())
          ? null
          : 'Enter a valid NIC (9 digits + V, or 12 digits)';
  String? get _nameError =>
      _name.text.trim().length < 3 ? 'Enter the full name' : null;
  String? get _dobError => _dob == null ? 'Select the date of birth' : null;
  String? get _contactError =>
      RegExp(r'^(\+94|0)?7\d{8}$').hasMatch(_contact.text.replaceAll(' ', ''))
          ? null
          : 'Enter a valid mobile number (e.g. 0712345678)';

  void _submitPatient() {
    setState(() => _showErrors = true);
    if (_nicError == null &&
        _nameError == null &&
        _dobError == null &&
        _contactError == null) {
      _go(3);
    }
  }

  Future<void> _pickDob() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  @override
  void dispose() {
    _nic.dispose();
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String get _dateLabel => '${_two(_date.day)} ${_months[_date.month - 1]} ${_date.year}';
  String get _dateIso => '${_date.year}-${_two(_date.month)}-${_two(_date.day)}';
  String get _queueNo =>
      '#${_two((_doctorIdx == null ? 0 : _doctorList[_doctorIdx!].waiting) + 1)}';

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  void _resetBooking() {
    setState(() {
      _hospital = null;
      _hospitalId = null;
      _doctorIdx = null;
      _doctorQuery = '';
      _session = 'Morning';
      _nic.clear();
      _name.clear();
      _contact.clear();
      _dob = null;
      _showErrors = false;
    });
    _loadDoctors();
    _loadUserProfile();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (d != null) {
      setState(() => _date = d);
      _refreshWaiting();
    }
  }

  bool _openedFromHome = false;

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

  /// Lets other tabs (e.g. Profile) jump straight to the history list.
  void showHistory() => _go(4);

  /// Steps back inside the booking flow. Returns false when already at the first screen.
  bool goBack() {
    if (_step == 0) {
      if (_openedFromHome) {
        widget.onBackToHome?.call();
        return true;
      }
      _go(1);
      return true;
    }
    if (_step == 1) return false;
    _go(_step == 4 ? 1 : _step - 1);
    return true;
  }

  /// Direct action: Opens the Book Appointment page (step 1/3)
  void openBookAppointment() {
    setState(() {
      _openedFromHome = false;
      _step = 1;
    });
  }

  /// Direct action: Opens the Find Hospital page (step 0)
  void openFindHospital() {
    setState(() {
      _openedFromHome = true;
      _step = 0;
    });
  }

  /// Reset to hospital selection list (step 0), optionally with a pre-selected hospital
  void resetToHospitalList([String? hospitalId]) {
    setState(() {
      _step = 0;
      if (hospitalId != null) {
        _hospitalId = hospitalId;
        final match = _hospitalList.where((h) => h.id == hospitalId).firstOrNull;
        if (match != null) {
          _hospital = match.name;
        }
      }
    });
  }

  /// Select a hospital and proceed directly to doctor/slot selection (step 1)
  void selectHospitalAndProceed(Hospital hospital) {
    setState(() {
      _hospital = hospital.name;
      _hospitalId = hospital.id;
      _doctorList = [];
      _doctorIdx = null;
      _step = 1;
    });
    _loadDoctors();
  }

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
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _go(0);
                            },
                            icon: const Icon(Icons.tune,
                                size: 16, color: AppColors.primary300),
                            label: const Text(
                              'Find Hospital',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary300,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setSheetState(() => filter = v),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search clinic, hospital...',
                          hintStyle: const TextStyle(
                              fontSize: 12, color: AppColors.gray400),
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: AppColors.primary300),
                          filled: true,
                          fillColor: AppColors.primary100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
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
    final q = _doctorQuery.trim().toLowerCase();
    final docs = [
      for (var i = 0; i < _doctorList.length; i++)
        if (q.isEmpty ||
            _doctorList[i].name.toLowerCase().contains(q) ||
            _doctorList[i].speciality.toLowerCase().contains(q) ||
            _doctorList[i].hospital.toLowerCase().contains(q))
          i,
    ];

    return Column(
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
            padding: EdgeInsets.zero,
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
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              _field(_dateLabel,
                  leading: Icons.calendar_today_outlined, onTap: _pickDate),
              const SizedBox(height: 8),
              _drop(
                hint: 'Session',
                value: _session,
                items: _sessions.keys.toList(),
                onChanged: (v) {
                  setState(() => _session = v ?? _session);
                  _refreshWaiting();
                },
                bordered: true,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('DOCTOR AVAILABILITY & QUEUE'),
                  if (_doctorList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${docs.length} Available',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary300,
                        ),
                      ),
                    ),
                ],
              ),
              if (_loadingDoctors)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary300,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Loading registered doctors...',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.gray400)),
                      ],
                    ),
                  ),
                )
              else if (docs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.person_search_outlined,
                            size: 36, color: AppColors.gray400),
                        const SizedBox(height: 8),
                        Text(
                          _doctorQuery.isNotEmpty
                              ? 'No doctors matching "$_doctorQuery"'
                              : 'No registered doctors found in database',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray400),
                        ),
                        if (_hospital != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _hospital = null;
                                _hospitalId = null;
                              });
                              _loadDoctors();
                            },
                            child: const Text('Show all hospital doctors',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary300)),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                for (final i in docs) _buildDoctorCard(i),
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

  Widget _buildDoctorCard(int i) {
    final doc = _doctorList[i];
    final isSelected = _doctorIdx == i;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _card(
        selected: isSelected,
        onTap: () {
          setState(() {
            _doctorIdx = i;
            // Auto-select doctor's hospital if user hasn't chosen a hospital yet
            if (_hospital == null && doc.hospital.isNotEmpty) {
              final match = _hospitalList
                  .where((h) =>
                      h.name.toLowerCase() == doc.hospital.toLowerCase() ||
                      h.id.toLowerCase() == doc.hospital.toLowerCase())
                  .firstOrNull;
              if (match != null) {
                _hospital = match.name;
                _hospitalId = match.id;
              } else {
                _hospital = doc.hospital;
              }
            }
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary300
                    : AppColors.primary100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_services_rounded,
                size: 22,
                color: isSelected ? Colors.white : AppColors.primary300,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary300
                          : AppColors.primary500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doc.speciality,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if ((doc.room != null && doc.room!.isNotEmpty) ||
                      doc.hospital.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (doc.room != null && doc.room!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary100.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room_outlined,
                                    size: 10, color: AppColors.primary300),
                                const SizedBox(width: 3),
                                Text(
                                  doc.room!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_hospital == null && doc.hospital.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_hospital_outlined,
                                    size: 10, color: AppColors.gray400),
                                const SizedBox(width: 3),
                                Text(
                                  doc.hospital,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary300
                        : AppColors.primary100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${doc.waiting} waiting',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? Colors.white : AppColors.primary400,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.check_circle,
                      size: 16, color: AppColors.primary300),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Screen 4: step 2 ----------

  Widget _patient() {
    final dobText = _dob == null
        ? 'Date of birth'
        : '${_two(_dob!.day)} ${_months[_dob!.month - 1]} ${_dob!.year}';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBackToHome();
      },
      child: Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF59E0B),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        size: 34, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Appointment Request Submitted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text('Status: Pending OPD Confirmation',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
              const SizedBox(height: 14),
              const Text('Your requested queue token is',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400)),
              const SizedBox(height: 8),
              Text(queue,
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Text(summary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500)),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Hospital OPD management will review and confirm your slot. You will receive an immediate notification upon confirmation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.gray400, height: 1.4),
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
      ),
    );
  }
}