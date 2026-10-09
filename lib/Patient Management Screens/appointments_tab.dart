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
  const AppointmentsTab({super.key, this.onBackToHome});

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
  Widget build(BuildContext context) {
    if (_step == 0) {
      return _hospitals();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: switch (_step) {
        1 => _details(),
        2 => _patient(),
        3 => _confirm(),
        _ => _history(),
      },
    );
  }

  // ---------- Screen 2: hospital list (Find Hospital wireframe) ----------
  Widget _hospitals() {
    return FindHospitalScreen(
      isStandalone: false,
      initialHospitalId: _hospitalId,
      onBack: () {
        if (_openedFromHome) {
          widget.onBackToHome?.call();
        } else {
          _go(1);
        }
      },
      onBookAppointment: (hospital) {
        selectHospitalAndProceed(hospital);
      },
    );
  }

  void _showHospitalPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _hospitalList.where((h) {
              if (filter.trim().isEmpty) return true;
              final q = filter.trim().toLowerCase();
              return h.name.toLowerCase().contains(q) ||
                  h.city.toLowerCase().contains(q) ||
                  h.district.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.65,
              minChildSize: 0.35,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Hospital',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary500,
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
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No hospitals found',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray400)),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(
                                  height: 1, indent: 16, endIndent: 16),
                              itemBuilder: (context, index) {
                                final h = filtered[index];
                                final isSelected = h.id == _hospitalId;
                                return ListTile(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
                                      size: 20,
                                      color: AppColors.primary300,
                                    ),
                                  ),
                                  title: Text(
                                    h.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: AppColors.primary500,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (h.identificationNo.isNotEmpty) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Code: ${h.identificationNo}',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary400,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      if (h.city.isNotEmpty) ...[
                                        Text(h.city,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.gray400)),
                                        const Text(' · ',
                                            style: TextStyle(
                                                color: AppColors.gray400)),
                                      ],
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: h.color,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        h.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: h.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: AppColors.primary300)
                                      : const Icon(Icons.chevron_right,
                                          size: 18,
                                          color: AppColors.gray400),
                                  onTap: () {
                                    if (h.isFull) {
                                      _snack('${h.name} OPD is currently full.');
                                      return;
                                    }
                                    Navigator.pop(ctx);
                                    selectHospitalAndProceed(h);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------- Screen 3: step 1 ----------
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
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header('Appointment Booking', step: '1 / 3'),
              const SizedBox(height: 12),
              _search((v) => setState(() => _doctorQuery = v),
                  hint: 'Search doctor, speciality...'),
              const SizedBox(height: 14),
              _label('APPOINTMENT DETAILS'),
              _field(_hospital ?? 'Select hospital',
                  trailing: Icons.keyboard_arrow_down,
                  onTap: _showHospitalPicker),
              if (_hospital != null && _hospital!.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final hMatch = _hospitalList
                        .where((h) => h.id == _hospitalId || h.name == _hospital)
                        .firstOrNull;
                    return Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary300.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_hospital_rounded,
                                size: 16, color: Color(0xFF007A78)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _hospital!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                    if (hMatch != null &&
                                        hMatch.identificationNo.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          hMatch.identificationNo,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (hMatch != null &&
                                    (hMatch.city.isNotEmpty ||
                                        hMatch.province.isNotEmpty))
                                  Text(
                                    '${hMatch.city.isNotEmpty ? "${hMatch.city}, " : ""}${hMatch.province}',
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.gray400),
                                  ),
                              ],
                            ),
                          ),
                          if (hMatch != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hMatch.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hMatch.color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hMatch.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hMatch.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
        const SizedBox(height: 8),
        _primaryBtn('Next', () {
          if (_doctorIdx == null) {
            _snack('Please select a doctor');
            return;
          }
          if (_hospital == null || _hospital!.isEmpty) {
            _snack('Please select a hospital');
            return;
          }
          _go(2);
        }),
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
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary300.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined,
                          size: 22, color: AppColors.primary300),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PATIENT USER ID (DEFAULTED TO NIC)',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.gray400,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              _nic.text.trim().isNotEmpty
                                  ? _nic.text.trim().toUpperCase()
                                  : 'Auto-assigned from NIC number below',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _nic.text.trim().isNotEmpty
                                    ? AppColors.primary500
                                    : AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _input(
                  'NIC Number (User ID) *',
                  _nic,
                  _nicError,
                  onChanged: (_) => setState(() {}),
                ),
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
    final hMatch = _hospitalList
        .where((h) => h.id == _hospitalId || h.name == _hospital)
        .firstOrNull;
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
              if (hMatch != null && hMatch.identificationNo.isNotEmpty)
                _row('Hospital ID', hMatch.identificationNo),
              _row('Date', _dateIso),
              _row('Session', '$_session (${_sessions[_session]})'),
              _row('Doctor', _doctorList[_doctorIdx ?? 0].name),
              _row('Speciality', _doctorList[_doctorIdx ?? 0].speciality),
              if (_doctorIdx != null &&
                  _doctorList[_doctorIdx!].room != null &&
                  _doctorList[_doctorIdx!].room!.isNotEmpty)
                _row('Room', _doctorList[_doctorIdx!].room!),
              _row('Patient User ID', _nic.text.trim().toUpperCase(),
                  highlight: true),
              _row('Patient Name', _name.text.trim()),
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
    final hMatch = _hospitalList
        .where((h) => h.id == _hospitalId || h.name == _hospital)
        .firstOrNull;
    final hidText = (hMatch != null && hMatch.identificationNo.isNotEmpty)
        ? ' [${hMatch.identificationNo}]'
        : '';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConfirmedScreen(
          queue: '#${_two(_confirmedQueue)}',
          summary:
              '${_hospital ?? ''}$hidText · $_dateLabel\nPatient User ID: ${_nic.text.trim().toUpperCase()}',
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
    Color bg(String s) => switch (s.toLowerCase()) {
          'pending' => const Color(0xFFFEF3C7),
          'confirmed' || 'waiting' => const Color(0xFFD1FAE5),
          'upcoming' => AppColors.primary100,
          'completed' => Colors.green.shade50,
          _ => Colors.red.shade50,
        };
    Color fg(String s) => switch (s.toLowerCase()) {
          'pending' => const Color(0xFFB45309),
          'confirmed' || 'waiting' => const Color(0xFF047857),
          'upcoming' => AppColors.primary300,
          'completed' => Colors.green.shade700,
          _ => Colors.red.shade700,
        };
    String cap(String s) {
      final lower = s.toLowerCase();
      if (lower == 'pending') return 'Pending Confirmation';
      if (lower == 'confirmed') return 'Confirmed';
      return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    }
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
                              if (a.hospitalIdentificationNo.isNotEmpty) ...[
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    a.hospitalIdentificationNo,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary400,
                                    ),
                                  ),
                                ),
                              ],
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
                          if (a.userId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Patient User ID: ${a.userId}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary400,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 16),
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
          {TextInputType? keyboard, ValueChanged<String>? onChanged}) =>
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 12),
        onChanged: (v) {
          onChanged?.call(v);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      ),
    );
  }
}