import 'package:flutter/material.dart';
import '../services/booking_service.dart';

/// Comprehensive geographical locations for Sri Lanka (Provinces -> Districts -> Cities)
const Map<String, Map<String, List<String>>> sriLankaLocations = {
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

class FindHospitalScreen extends StatefulWidget {
  /// Optional callback when user taps "Book Appointment" with a hospital selected
  final void Function(Hospital hospital)? onBookAppointment;

  /// Optional callback when user taps back button to return to dashboard or previous screen
  final VoidCallback? onBack;

  /// If opened as a standalone page (e.g. from a push route)
  final bool isStandalone;

  /// Pre-selected hospital ID if any
  final String? initialHospitalId;

  const FindHospitalScreen({
    super.key,
    this.onBookAppointment,
    this.onBack,
    this.isStandalone = false,
    this.initialHospitalId,
  });

  @override
  State<FindHospitalScreen> createState() => _FindHospitalScreenState();
}

class _FindHospitalScreenState extends State<FindHospitalScreen> {
  final _service = BookingService();
  final _searchController = TextEditingController();

  List<Hospital> _allHospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedHospitalId;

  // Dedicated state for full hospital detail view
  Hospital? _selectedHospital;
  List<Doctor> _hospitalDoctors = [];
  bool _loadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _selectedHospitalId = widget.initialHospitalId;
    _loadHospitals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getHospitals();
      if (!mounted) return;
      setState(() {
        _allHospitals = list;
        _isLoading = false;

        if (widget.initialHospitalId != null) {
          final match = list.where((h) => h.id == widget.initialHospitalId).firstOrNull;
          if (match != null) {
            _selectedHospitalId = match.id;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load hospitals: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectHospital(Hospital hospital) async {
    setState(() {
      _selectedHospital = hospital;
      _selectedHospitalId = hospital.id;
      _hospitalDoctors = [];
      _loadingDoctors = true;
    });

    try {
      final docs = await _service.getDoctors(hospital.id, hospitalName: hospital.name);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _service.loadWaiting(hospital.id, docs, today, 'Morning');
      if (!mounted) return;
      setState(() {
        _hospitalDoctors = docs;
        _loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
    }
  }

  bool _matchesFilter(Hospital h) {
    if (_selectedProvince != null && h.province.isNotEmpty) {
      final p1 = h.province.toLowerCase().trim();
      final p2 = _selectedProvince!.toLowerCase().trim();
      if (!p1.contains(p2) && !p2.contains(p1)) {
        return false;
      }
    }
    if (_selectedDistrict != null && h.district.isNotEmpty) {
      final d1 = h.district.toLowerCase().trim();
      final d2 = _selectedDistrict!.toLowerCase().trim();
      if (!d1.contains(d2) && !d2.contains(d1)) {
        return false;
      }
    }
    if (_selectedCity != null && h.city.isNotEmpty) {
      final c1 = h.city.toLowerCase().trim();
      final c2 = _selectedCity!.toLowerCase().trim();
      if (!c1.contains(c2) && !c2.contains(c1)) {
        return false;
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final inName = h.name.toLowerCase().contains(q);
      final inCity = h.city.toLowerCase().contains(q);
      final inDistrict = h.district.toLowerCase().contains(q);
      final inProvince = h.province.toLowerCase().contains(q);
      final inId = h.identificationNo.toLowerCase().contains(q);
      if (!inName && !inCity && !inDistrict && !inProvince && !inId) {
        return false;
      }
    }

    return true;
  }

  void _onBookPressed([Hospital? hospital]) {
    final target = hospital ??
        _selectedHospital ??
        (_selectedHospitalId != null
            ? _allHospitals.where((h) => h.id == _selectedHospitalId).firstOrNull
            : null);

    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hospital to book an appointment.'),
          backgroundColor: Color(0xFF007A78),
        ),
      );
      return;
    }

    if (target.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${target.name} OPD is currently full. Please choose another open hospital.'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (widget.onBookAppointment != null) {
      widget.onBookAppointment!(target);
    } else {
      Navigator.of(context).pop(target);
    }
  }

  void _handleBack() {
    if (_selectedHospital != null) {
      setState(() => _selectedHospital = null);
      return;
    }
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showFilterPicker({
    required String title,
    required List<String> items,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: items.length > 8 ? 0.65 : 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $title',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (currentValue != null)
                        TextButton(
                          onPressed: () {
                            onSelected(null);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Clear',
                              style: TextStyle(
                                  color: Color(0xFF007A78),
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 20, endIndent: 20),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAll = currentValue == null;
                        return ListTile(
                          title: const Text('All / Any',
                              style: TextStyle(fontSize: 14)),
                          trailing: isAll
                              ? const Icon(Icons.check,
                                  color: Color(0xFF007A78))
                              : null,
                          onTap: () {
                            onSelected(null);
                            Navigator.of(ctx).pop();
                          },
                        );
                      }
                      final item = items[index - 1];
                      final isSelected = item == currentValue;
                      return ListTile(
                        title: Text(item,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF007A78)
                                  : const Color(0xFF1E293B),
                            )),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: Color(0xFF007A78))
                            : null,
                        onTap: () {
                          onSelected(item);
                          Navigator.of(ctx).pop();
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
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.isStandalone
          ? Scaffold(
              backgroundColor: const Color(0xFFF3F7F7),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF007A78)),
                  onPressed: _handleBack,
                ),
                title: Text(
                  _selectedHospital != null ? 'Hospital Details' : 'Find Hospital',
                  style: const TextStyle(
                    color: Color(0xFF007A78),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: _selectedHospital != null
                    ? _buildHospitalDetailsView(_selectedHospital!)
                    : _buildHospitalListView(),
              ),
            )
          : (_selectedHospital != null
              ? _buildHospitalDetailsView(_selectedHospital!)
              : _buildHospitalListView()),
    );
  }

  /// -------------------------------------------------------------
  /// View 1: Hospital List & Filters (Find Hospital)
  /// -------------------------------------------------------------
  Widget _buildHospitalListView() {
    final filteredHospitals = _allHospitals.where(_matchesFilter).toList();
    final districts = _selectedProvince != null
        ? (sriLankaLocations[_selectedProvince]?.keys.toList() ?? <String>[])
        : <String>[];
    final cities = (_selectedProvince != null && _selectedDistrict != null)
        ? (sriLankaLocations[_selectedProvince]?[_selectedDistrict] ??
            <String>[])
        : <String>[];

    final hasActiveFilter = _selectedProvince != null ||
        _selectedDistrict != null ||
        _selectedCity != null ||
        _searchQuery.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadHospitals,
            color: const Color(0xFF007A78),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // ================= 1. PAGE TITLE & HEADER =================
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: _handleBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back,
                            color: Color(0xFF007A78), size: 24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Find Hospital',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0C3836),
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Browse hospitals, view live facilities & book appointments',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ================= 2. SEARCH BAR =================
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCFDFE0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search hospital, code (e.g. WC00001)...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF007A78),
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ================= 3. FILTER DROPDOWNS =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FILTER BY REGION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (hasActiveFilter)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProvince = null;
                            _selectedDistrict = null;
                            _selectedCity = null;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          'Reset All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A78),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Three Dropdown Pills side-by-side
                Row(
                  children: [
                    // Province Dropdown
                    Expanded(
                      child: _buildFilterPill(
                        label: _selectedProvince ?? 'Province',
                        isActive: _selectedProvince != null,
                        onTap: () {
                          _showFilterPicker(
                            title: 'Province',
                            items: sriLankaLocations.keys.toList(),
                            currentValue: _selectedProvince,
                            onSelected: (val) {
                              setState(() {
                                _selectedProvince = val;
                                _selectedDistrict = null;
                                _selectedCity = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // District Dropdown
                    Expanded(
                      child: _buildFilterPill(
                        label: _selectedDistrict ?? 'District',
                        isActive: _selectedDistrict != null,
                        onTap: () {
                          if (_selectedProvince == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a Province first.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _showFilterPicker(
                            title: 'District',
                            items: districts,
                            currentValue: _selectedDistrict,
                            onSelected: (val) {
                              setState(() {
                                _selectedDistrict = val;
                                _selectedCity = null;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // City Dropdown
                    Expanded(
                      child: _buildFilterPill(
                        label: _selectedCity ?? 'City',
                        isActive: _selectedCity != null,
                        onTap: () {
                          if (_selectedDistrict == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a District first.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _showFilterPicker(
                            title: 'City',
                            items: cities,
                            currentValue: _selectedCity,
                            onSelected: (val) =>
                                setState(() => _selectedCity = val),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ================= 4. HOSPITAL AVAILABILITY LIST =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HOSPITAL AVAILABILITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${filteredHospitals.length} Found',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A78),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Loading State
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF007A78),
                      ),
                    ),
                  )
                // Error State
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _loadHospitals,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A78),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                // Empty Results State
                else if (filteredHospitals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.local_hospital_outlined,
                              size: 42, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No hospitals found matching your criteria.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedProvince = null;
                                _selectedDistrict = null;
                                _selectedCity = null;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear Filters',
                                style: TextStyle(
                                    color: Color(0xFF007A78),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                // Hospital Cards List
                else
                  for (final hospital in filteredHospitals)
                    _buildHospitalCard(hospital),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Quick Bottom Booking Bar (if hospital selected)
        if (_selectedHospitalId != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F7),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _onBookPressed(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A67),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.calendar_month, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// -------------------------------------------------------------
  /// View 2: Full Hospital Data Display
  /// -------------------------------------------------------------
  Widget _buildHospitalDetailsView(Hospital hospital) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Back Bar
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedHospital = null),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back,
                          color: Color(0xFF007A78), size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Hospital Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C3836),
                      ),
                    ),
                  ),
                  // Availability Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hospital.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hospital.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hospital.color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hospital.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hospital.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ================= HERO HOSPITAL CARD =================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006A67), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006A67).withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hospital.type.isNotEmpty
                                          ? hospital.type
                                          : 'Government Hospital',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (hospital.identificationNo.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.qr_code_2_rounded,
                                              size: 13,
                                              color: Color(0xFF006A67)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Code: ${hospital.identificationNo}',
                                            style: const TextStyle(
                                              color: Color(0xFF006A67),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              '${hospital.city.isNotEmpty ? "${hospital.city}, " : ""}${hospital.province}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          hospital.slotsLeft > 0
                              ? '${hospital.slotsLeft} slots remaining'
                              : 'Live OPD Queue',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ================= LOCATION & CONTACT DETAILS =================
              _buildSectionTitle('HOSPITAL INFORMATION & LOCATION'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (hospital.identificationNo.isNotEmpty) ...[
                      _buildInfoRow(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Hospital Code',
                        value: hospital.identificationNo,
                      ),
                      const Divider(height: 20),
                    ],
                    _buildInfoRow(
                      icon: Icons.place_outlined,
                      label: 'Full Address',
                      value: hospital.address.isNotEmpty
                          ? hospital.address
                          : '${hospital.city}, ${hospital.district}, ${hospital.province}',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.phone_in_talk_outlined,
                      label: 'Hospital Hotline',
                      value: hospital.contactNo.isNotEmpty
                          ? hospital.contactNo
                          : '011-2691111 (Ext. OPD Desk)',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.access_time_outlined,
                      label: 'OPD Hours',
                      value: hospital.openingHours.isNotEmpty
                          ? hospital.openingHours
                          : 'OPD: 8:00 AM - 4:00 PM (Emergency 24/7)',
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(
                      icon: Icons.emergency_outlined,
                      label: 'Emergency Ambulance',
                      value: '1990 Suwa Seriya (24 Hours Direct Support)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= DEPARTMENTS & UNITS =================
              _buildSectionTitle('MEDICAL DEPARTMENTS & SPECIALTIES'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hospital.departments.map((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF007A78),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // ================= REGISTERED DOCTORS SECTION =================
              _buildSectionTitle('REGISTERED DOCTORS & SPECIALISTS'),
              const SizedBox(height: 8),
              if (_loadingDoctors)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF007A78)),
                  ),
                )
              else if (_hospitalDoctors.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.medical_services_outlined,
                          color: Color(0xFF007A78), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'General OPD Consultation Doctors on duty today.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final doc in _hospitalDoctors)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: const Icon(Icons.person,
                              color: Color(0xFF007A78), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    doc.speciality,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  if (doc.room != null &&
                                      doc.room!.isNotEmpty) ...[
                                    const Text(' · ',
                                        style:
                                            TextStyle(color: Color(0xFF94A3B8))),
                                    Text(
                                      doc.room!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF007A78),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doc.waiting > 0
                                ? '${doc.waiting} Waiting'
                                : 'Available',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: doc.waiting > 0
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              const SizedBox(height: 20),
            ],
          ),
        ),

        // Sticky Bottom Book Appointment Action
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _onBookPressed(hospital),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A67),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Book Appointment at ${hospital.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF007A78)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Custom Pill Filter Widget (Province, District, City)
  Widget _buildFilterPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF007A78) : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF007A78)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive
                  ? const Color(0xFF007A78)
                  : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  /// Hospital Availability Card
  Widget _buildHospitalCard(Hospital hospital) {
    final isSelected = _selectedHospitalId == hospital.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8F8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF007A78)
              : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF007A78).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectHospital(hospital),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Left Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF007A78),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center Column: Hospital Name, Hospital Code & Location, Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hospital Name (Full width unconstrained)
                      Text(
                        hospital.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Hospital Code Tag & Location in clean row
                      Row(
                        children: [
                          if (hospital.identificationNo.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFF007A78)
                                      .withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'Code: ${hospital.identificationNo}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF007A78),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              '${hospital.city.isNotEmpty ? "${hospital.city}, " : ""}${hospital.province}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Status indicator dot & label
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hospital.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hospital.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hospital.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right arrow Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
