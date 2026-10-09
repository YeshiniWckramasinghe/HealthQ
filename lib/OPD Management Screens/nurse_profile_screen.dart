import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/staff_auth_service.dart';
import '../common Screens/login_screen.dart';
import 'home_dashboard_screen.dart';
import 'appointments_list_screen.dart';

class NurseProfileScreen extends StatefulWidget {
  final String? nurseName;
  final String? nurseId;
  final String? role;
  final String? department;
  final String? hospital;
  final String? phone;
  final String? email;
  final String? shift;
  final StaffModel? staffModel;

  const NurseProfileScreen({
    super.key,
    this.nurseName,
    this.nurseId,
    this.role,
    this.department,
    this.hospital,
    this.phone,
    this.email,
    this.shift,
    this.staffModel,
  });

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String _photoBase64 = '';
  String _photoUrl = '';
  StaffModel? _currentStaff;

  // Preset medical avatars for quick selection
  final List<Map<String, dynamic>> _presetAvatars = [
    {
      'name': 'nurse_teal',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFF007A78),
    },
    {
      'name': 'nurse_blue',
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFF2563EB),
    },
    {
      'name': 'nurse_emerald',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'name': 'nurse_purple',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFF7C3AED),
    },
    {
      'name': 'nurse_rose',
      'icon': Icons.healing_rounded,
      'color': const Color(0xFFE11D48),
    },
    {
      'name': 'nurse_amber',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFFD97706),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.staffModel != null) {
      _currentStaff = widget.staffModel;
      _photoBase64 = _currentStaff?.photoBase64 ?? '';
      _photoUrl = _currentStaff?.photoUrl ?? '';
    }

    final id = widget.nurseId ?? widget.staffModel?.staffId ?? 'NUR1002-0011';
    if (id.isNotEmpty) {
      try {
        final staff = await StaffAuthService.instance.findStaff(id);
        if (staff != null && mounted) {
          setState(() {
            _currentStaff = staff;
            if (staff.photoBase64 != null && staff.photoBase64!.isNotEmpty) {
              _photoBase64 = staff.photoBase64!;
            } else if (staff.photoUrl != null && staff.photoUrl!.isNotEmpty) {
              _photoUrl = staff.photoUrl!;
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading nurse data: $e');
      }
    }
  }

  // Fallback defaults matching the wireframe exactly
  String get _displayName {
    final v = _currentStaff?.name ?? widget.nurseName;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'Nurse Perera K.';
  }

  String get _displayId {
    final v = _currentStaff?.staffId ?? widget.nurseId;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'NUR1002-0011';
  }

  String get _displayRole {
    final v = _currentStaff?.role ?? widget.role;
    if (v != null && v.trim().isNotEmpty) {
      final r = v.trim().toLowerCase();
      if (r == 'nurse') return 'Staff Nurse';
      return v[0].toUpperCase() + v.substring(1);
    }
    return 'Staff Nurse';
  }

  String get _displayDepartment {
    final v = _currentStaff?.department ?? widget.department;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'General Medicine OPD';
  }

  String get _displayHospital {
    final v = _currentStaff?.hospital ?? widget.hospital;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'Gov. Hospital Colombo';
  }

  String get _displayPhone {
    final v = _currentStaff?.contactNo ?? widget.phone;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : '077-123-4567';
  }

  String get _displayEmail {
    final v = _currentStaff?.email ?? widget.email;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'n.perera@govhosp.lk';
  }

  String get _displayShift {
    final v = _currentStaff?.shift ?? widget.shift;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'Morning (06:00-14:00)';
  }

  String get _initials {
    final name = _displayName;
    if (name.isEmpty) return 'N';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Profile Picture Upload Actions
  // ---------------------------------------------------------------------------
  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a photo to update your official OPD nurse badge',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // Option 1: Camera
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A78).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF007A78)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),

                // Option 2: Gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A78).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF007A78)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                // Option 3: Preset Avatars
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_circle_outlined, color: Colors.blueAccent),
                  ),
                  title: const Text('Choose an Avatar', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetAvatarDialog();
                  },
                ),

                // Option 4: Remove photo
                if (_photoBase64.isNotEmpty || _photoUrl.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    ),
                    title: const Text('Remove Photo',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _savePhotoData('');
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await _savePhotoData(b64);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e')),
      );
    }
  }

  void _showPresetAvatarDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choose an Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _presetAvatars.map((av) {
              final color = av['color'] as Color;
              final icon = av['icon'] as IconData;
              return InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _savePhotoData('preset:${av['name']}');
                },
                borderRadius: BorderRadius.circular(30),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePhotoData(String data) async {
    setState(() => _isLoading = true);
    try {
      await StaffAuthService.instance.updateStaffProfilePhoto(
        staffId: _displayId,
        photoData: data,
      );
      if (!mounted) return;
      setState(() {
        if (data.startsWith('preset:')) {
          _photoUrl = data;
          _photoBase64 = '';
        } else {
          _photoBase64 = data;
          _photoUrl = data.startsWith('http') ? data : '';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image updated successfully!'),
          backgroundColor: Color(0xFF007A78),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatarWidget({double radius = 46}) {
    if (_photoBase64.isNotEmpty) {
      try {
        final raw = _photoBase64.contains(',') ? _photoBase64.split(',')[1] : _photoBase64;
        final bytes = base64Decode(raw);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    if (_photoUrl.startsWith('preset:')) {
      final name = _photoUrl.replaceFirst('preset:', '');
      final av = _presetAvatars.firstWhere(
        (a) => a['name'] == name,
        orElse: () => _presetAvatars[0],
      );
      return CircleAvatar(
        radius: radius,
        backgroundColor: av['color'] as Color,
        child: Icon(av['icon'] as IconData, color: Colors.white, size: radius * 1.1),
      );
    }

    if (_photoUrl.isNotEmpty && _photoUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(_photoUrl),
      );
    }

    // Default wireframe look: deep teal circle with white initial "N"
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF16837D),
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout Confirmation Flow
  // ---------------------------------------------------------------------------
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of the Nurse Portal?',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      StaffAuthService.instance.setCurrentStaff(null);
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _backToDashboard() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop({
        'photoBase64': _photoBase64,
        'photoUrl': _photoUrl,
        'name': _displayName,
        'department': _displayDepartment,
        'hospital': _displayHospital,
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeDashboardScreen(
            nurseName: _displayName,
            nurseId: _displayId,
            department: _displayDepartment,
            hospital: _displayHospital,
            phone: _displayPhone,
            email: _displayEmail,
            shift: _displayShift,
            role: _displayRole,
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build Screen UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const headerTeal = Color(0xFF006760);
    const bgMint = Color(0xFFEAF4F3);

    return Scaffold(
      backgroundColor: bgMint,
      body: Column(
        children: [
          // ================= 1. TOP HEADER BANNER =================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: headerTeal,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        // Quick back or close icon if popped
                        IconButton(
                          onPressed: _backToDashboard,
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                          splashRadius: 20,
                          tooltip: 'Back to Dashboard',
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GovHealth System Access',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= 2. MAIN SCROLLABLE CONTENT =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                children: [
                  // CARD 1: PROFILE SUMMARY & AVATAR
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar with Camera Edit Badge
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            _buildAvatarWidget(radius: 46),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _showImagePickerModal,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF007A78),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF007A78),
                                    size: 17,
                                  ),
                                ),
                              ),
                            ),
                            if (_isLoading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Nurse Name
                        Text(
                          _displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E2C),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Staff ID
                        Text(
                          'ID: $_displayId',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 2: EMPLOYMENT PROFILE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EMPLOYMENT PROFILE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A78),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 1),
                        const SizedBox(height: 8),

                        _buildInfoRow('Name', _displayName),
                        _buildInfoRow('Staff ID', _displayId),
                        _buildInfoRow('Role', _displayRole),
                        _buildInfoRow('Department', _displayDepartment),
                        _buildInfoRow('Hospital', _displayHospital),
                        _buildInfoRow('Phone', _displayPhone),
                        _buildInfoRow('Email', _displayEmail),
                        _buildInfoRow('Shift', _displayShift, isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ACTION BUTTON 1: Log Out
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _confirmLogout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB91C1C), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ACTION BUTTON 2: Back to Dashboard
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _backToDashboard,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF64748B), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ================= 3. BOTTOM NAVIGATION BAR =================
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: isLast ? 2 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E2C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(0, Icons.home_rounded, 'Home', isActive: true),
              _buildBottomNavItem(1, Icons.calendar_today_outlined, 'Appointments'),
              _buildBottomNavItem(2, Icons.format_list_bulleted, 'Queue'),
              _buildBottomNavItem(3, Icons.notifications_none_outlined, 'Alerts'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label, {bool isActive = false}) {
    final color = isActive ? const Color(0xFF007A78) : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        if (index == 0) {
          _backToDashboard();
        } else if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentsListScreen(
                hospital: _displayHospital,
              ),
            ),
          );
        } else if (index == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppointmentsListScreen(
                initialQueueTab: true,
                hospital: _displayHospital,
              ),
            ),
          );
        } else if (index == 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OPD Alerts & Notifications'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
