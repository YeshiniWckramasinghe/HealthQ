import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';

const Map<String, Map<String, List<String>>> _locations = {
  'Western Province': {
    'Colombo': ['Colombo', 'Dehiwala-Mount Lavinia', 'Sri Jayawardenepura Kotte', 'Moratuwa'],
    'Gampaha': ['Gampaha', 'Negombo', 'Wattala', 'Ja-Ela', 'Katunayake', 'Minuwangoda'],
    'Kalutara': ['Kalutara', 'Panadura', 'Beruwala', 'Horana'],
  },
  'Central Province': {
    'Kandy': ['Kandy', 'Peradeniya', 'Katugastota'],
    'Matale': ['Matale', 'Dambulla', 'Galewela'],
    'Nuwara Eliya': ['Nuwara Eliya', 'Hatton', 'Talawakele'],
  },
  'Southern Province': {
    'Galle': ['Galle', 'Hikkaduwa', 'Ambalangoda'],
    'Matara': ['Matara', 'Weligama', 'Akuressa'],
    'Hambantota': ['Hambantota', 'Tangalle', 'Tissamaharama'],
  },
  'Northern Province': {
    'Jaffna': ['Jaffna', 'Chavakachcheri'],
    'Kilinochchi': ['Kilinochchi'],
    'Mannar': ['Mannar'],
    'Mullaitivu': ['Mullaitivu'],
    'Vavuniya': ['Vavuniya'],
  },
  'Eastern Province': {
    'Batticaloa': ['Batticaloa', 'Eravur'],
    'Ampara': ['Ampara', 'Kalmunai', 'Akkaraipattu'],
    'Trincomalee': ['Trincomalee', 'Kinniya'],
  },
  'North Western Province': {
    'Kurunegala': ['Kurunegala', 'Kuliyapitiya', 'Narammala'],
    'Puttalam': ['Puttalam', 'Chilaw', 'Wennappuwa'],
  },
  'North Central Province': {
    'Anuradhapura': ['Anuradhapura'],
    'Polonnaruwa': ['Polonnaruwa', 'Hingurakgoda'],
  },
  'Uva Province': {
    'Badulla': ['Badulla', 'Bandarawela', 'Haputale'],
    'Monaragala': ['Monaragala', 'Wellawaya'],
  },
  'Sabaragamuwa Province': {
    'Ratnapura': ['Ratnapura', 'Balangoda', 'Embilipitiya'],
    'Kegalle': ['Kegalle', 'Mawanella', 'Warakapola'],
  },
};

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _sessions = {
  'Morning': '9:00 - 12:00',
  'Afternoon': '1:00 - 4:00',
  'Evening': '4:00 - 7:00',
};

class AppointmentsTab extends StatefulWidget {
  /// Called when the user taps "Back to Home" on the confirmation screen.
  final VoidCallback? onBackToHome;
  const AppointmentsTab({super.key, this.onBackToHome});

  @override
  State<AppointmentsTab> createState() => AppointmentsTabState();
}

class AppointmentsTabState extends State<AppointmentsTab> {
  // 0 = hospital list, 1..3 = booking steps, 4 = history
  int _step = 0;

  final _service = BookingService();
  List<Hospital> _hospitalList = [];
  List<Doctor> _doctorList = [];
  bool _loadingHospitals = true;
  String? _loadError;
  String? _hospitalId;
  bool _saving = false;
  int _confirmedQueue = 0;
  late final Stream<List<AppointmentRecord>> _historyStream =
      _service.myAppointments();

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _loadingHospitals = true;
      _loadError = null;
    });
    try {
      final list = await _service.getHospitals();
      if (!mounted) return;
      setState(() {
        _hospitalList = list;
        _loadingHospitals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load hospitals';
        _loadingHospitals = false;
      });
    }
  }

  Future<void> _loadDoctors() async {
    final id = _hospitalId;
    if (id == null) return;
    try {
      final docs = await _service.getDoctors(id);
      await _service.loadWaiting(id, docs, _dateIso, _session);
      if (!mounted || id != _hospitalId) return;
      setState(() => _doctorList = docs);
    } catch (_) {
      if (mounted) _snack('Could not load doctors');
    }
  }

  Future<void> _refreshWaiting() async {
    final id = _hospitalId;
    if (id == null || _doctorList.isEmpty) return;
    try {
      await _service.loadWaiting(id, _doctorList, _dateIso, _session);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _confirmBooking() async {
    if (_saving) return;
    final hid = _hospitalId;
    final di = _doctorIdx;
    if (hid == null || di == null || _dob == null) return;
    final hospital = _hospitalList.firstWhere((h) => h.id == hid);
    setState(() => _saving = true);
    try {
      final q = await _service.book(
        hospital: hospital,
        doctor: _doctorList[di],
        date: _dateIso,
        dateLabel: _dateLabel,
        session: _session,
        patientName: _name.text.trim(),
        nic: _nic.text.trim().toUpperCase(),
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

  // hospital filters
  String? _province, _district, _city;
  String _query = '';

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

  void _resetBooking() => setState(() {
        _hospital = null;
        _hospitalId = null;
        _doctorList = [];
        _doctorIdx = null;
        _doctorQuery = '';
        _session = 'Morning';
        _nic.clear();
        _name.clear();
        _contact.clear();
        _dob = null;
        _showErrors = false;
      });

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

  void _go(int s) => setState(() => _step = s);

  /// Lets other tabs (e.g. Profile) jump straight to the history list.
  void showHistory() => _go(4);

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
    final q = _query.trim().toLowerCase();
    final list = _hospitalList
        .where((h) =>
            (_province == null || h.province == _province) &&
            (_district == null || h.district == _district) &&
            (_city == null || h.city == _city) &&
            h.name.toLowerCase().contains(q))
        .toList();
    final districts = _locations[_province]?.keys.toList() ?? <String>[];
    final cities = _locations[_province]?[_district] ?? <String>[];
    final hasFilter = _province != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking'),
        const SizedBox(height: 12),
        _search((v) => setState(() => _query = v)),
        const SizedBox(height: 14),
        Row(
          children: [
            _label('HOSPITAL DETAILS'),
            const Spacer(),
            if (hasFilter)
              GestureDetector(
                onTap: () => setState(() {
                  _province = null;
                  _district = null;
                  _city = null;
                }),
                child: const Text('Clear',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary300)),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _drop(
                hint: 'Province',
                value: _province,
                items: _locations.keys.toList(),
                onChanged: (v) => setState(() {
                  _province = v;
                  _district = null;
                  _city = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _drop(
                hint: 'District',
                value: _district,
                items: districts,
                onChanged: (v) => setState(() {
                  _district = v;
                  _city = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _drop(
                hint: 'City',
                value: _city,
                items: cities,
                onChanged: (v) => setState(() => _city = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('HOSPITAL AVAILABILITY'),
        Expanded(
          child: _loadingHospitals
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: TextButton(
                          onPressed: _loadHospitals,
                          child: Text('$_loadError. Tap to retry')))
                  : list.isEmpty
              ? const Center(
                  child: Text('No hospitals found',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400)))
              : ListView(
                  children: [
                    for (final h in list)
                      _card(
                        selected: _hospital == h.name,
                        onTap: () {
                          if (h.isFull) {
                            _snack('This hospital OPD is full');
                            return;
                          }
                          setState(() {
                            _hospital = h.name;
                            _hospitalId = h.id;
                            _doctorList = [];
                            _doctorIdx = null;
                          });
                          _loadDoctors();
                        },
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
                                  Text(h.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary500)),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: h.color),
                                      const SizedBox(width: 4),
                                      Text(h.label,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.gray400)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _hospital == h.name
                                  ? Icons.check_circle
                                  : Icons.chevron_right,
                              color: _hospital == h.name
                                  ? AppColors.primary300
                                  : AppColors.gray400,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        _primaryBtn('Book Appointment', () {
          if (_hospital == null) {
            _snack('Please select a hospital');
            return;
          }
          _go(1);
        }),
      ],
    );
  }

  // ---------- Screen 3: step 1 ----------
  Widget _details() {
    final q = _doctorQuery.trim().toLowerCase();
    final docs = [
      for (var i = 0; i < _doctorList.length; i++)
        if (_doctorList[i].name.toLowerCase().contains(q) ||
            _doctorList[i].speciality.toLowerCase().contains(q))
          i,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointment Booking', step: '1 / 3'),
        const SizedBox(height: 12),
        _search((v) => setState(() => _doctorQuery = v),
            hint: 'Search doctor, speciality...'),
        const SizedBox(height: 14),
        _label('APPOINTMENT DETAILS'),
        _field(_hospital ?? 'Select hospital',
            trailing: Icons.keyboard_arrow_down, onTap: () => _go(0)),
        const SizedBox(height: 8),
        _field(_dateLabel, leading: Icons.calendar_today_outlined, onTap: _pickDate),
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
        _label('DOCTOR AVAILABILITY & QUEUE'),
        Expanded(
          child: docs.isEmpty
              ? const Center(
                  child: Text('No doctors found',
                      style: TextStyle(fontSize: 12, color: AppColors.gray400)))
              : ListView(
                  children: [
                    for (final i in docs)
                      _card(
                        selected: _doctorIdx == i,
                        onTap: () => setState(() => _doctorIdx = i),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_doctorList[i].name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary500)),
                                  Text(_doctorList[i].speciality,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray400)),
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
                              child: Text('${_doctorList[i].waiting} waiting',
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
        _primaryBtn('Next', () {
          if (_hospital == null) {
            _snack('Please select a hospital');
            return;
          }
          if (_doctorIdx == null) {
            _snack('Please select a doctor');
            return;
          }
          _go(2);
        }),
      ],
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
        _header('Appointment Booking', step: '2 / 3'),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _input('NIC number', _nic, _nicError),
                const SizedBox(height: 8),
                _input('Full name', _name, _nameError),
                const SizedBox(height: 8),
                _field(dobText,
                    leading: Icons.calendar_today_outlined, onTap: _pickDob),
                if (_showErrors && _dobError != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(_dobError!,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.redAccent)),
                  ),
                const SizedBox(height: 8),
                _input('Contact number', _contact, _contactError,
                    keyboard: TextInputType.phone),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _primaryBtn('Next', _submitPatient),
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
              _row('Hospital', _hospital ?? '-'),
              _row('Date', _dateIso),
              _row('Session', '$_session (${_sessions[_session]})'),
              _row('Doctor', _doctorList[_doctorIdx ?? 0].name),
              _row('Speciality', _doctorList[_doctorIdx ?? 0].speciality),
              _row('Patient', _name.text.trim()),
              _row('NIC', _nic.text.trim().toUpperCase()),
              _row('Contact', _contact.text.trim()),
              _row('Est. Queue No.', _queueNo, highlight: true),
            ],
          ),
        ),
        const Spacer(),
        _primaryBtn(_saving ? 'Saving...' : 'Confirm Appointment', _confirmBooking),
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
          queue: '#${_two(_confirmedQueue)}',
          summary: '${_hospital ?? ''} · $_dateLabel',
          onViewAppointments: () {
            Navigator.of(context).pop();
            _resetBooking();
            _go(4);
          },
          onBackToHome: () {
            Navigator.of(context).pop();
            _resetBooking();
            _go(0);
            widget.onBackToHome?.call();
          },
        ),
      ),
    );
  }

  // ---------- Appointments history ----------
  Widget _history() {
    Color bg(String s) => switch (s) {
          'upcoming' => AppColors.primary100,
          'completed' => Colors.green.shade50,
          _ => Colors.red.shade50,
        };
    Color fg(String s) => switch (s) {
          'upcoming' => AppColors.primary300,
          'completed' => Colors.green.shade700,
          _ => Colors.red.shade700,
        };
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    Widget msg(String t) => Center(
        child: Text(t,
            style: const TextStyle(fontSize: 12, color: AppColors.gray400)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('Appointments History'),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<AppointmentRecord>>(
            stream: _historyStream,
            builder: (context, snap) {
              if (snap.hasError) return msg('Could not load appointments');
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snap.data!;
              if (items.isEmpty) return msg('No appointments yet');
              return ListView(
                children: [
                  for (final a in items)
                    _card(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(a.hospitalName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: bg(a.status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(cap(a.status),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: fg(a.status))),
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
                                    Text(a.doctorName,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary500)),
                                    Text(a.dateLabel,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray400)),
                                  ],
                                ),
                              ),
                              Text('Queue #${_two(a.queueNo)}',
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
              );
            },
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

  Widget _search(ValueChanged<String> onChanged,
          {String hint = 'Search clinic, hospital...'}) =>
      TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
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

  Widget _drop({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool bordered = false,
  }) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: bordered ? 12 : 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(bordered ? 10 : 8),
          border: Border.all(
              color: bordered ? AppColors.primary300 : AppColors.gray100),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            itemHeight: 48,
            hint: Text(hint,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray400)),
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: TextStyle(
                fontSize: bordered ? 12 : 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500),
            items: [
              for (final i in items)
                DropdownMenuItem(
                    value: i, child: Text(i, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: items.isEmpty ? null : onChanged,
          ),
        ),
      );

  Widget _field(String t,
          {IconData? leading, IconData? trailing, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
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
        ),
      );

  Widget _input(String hint, TextEditingController controller, String? error,
          {TextInputType? keyboard}) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 12),
        onChanged: (_) {
          if (_showErrors) setState(() {});
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
          errorText: _showErrors ? error : null,
          errorStyle: const TextStyle(fontSize: 10),
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

  Widget _card(
          {required Widget child, VoidCallback? onTap, bool selected = false}) => Padding(
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
                  color: selected ? AppColors.primary300 : AppColors.gray100,
                  width: selected ? 1.5 : 1),
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