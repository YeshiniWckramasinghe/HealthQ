import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/booking_service.dart';
import '../common Screens/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = BookingService();
  final _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _nicController;
  late final TextEditingController _dobController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;

  String _photoBase64 = '';
  String _photoUrl = '';
  bool _isSaving = false;

  // Preset avatar choices
  static const List<Map<String, dynamic>> _presetAvatars = [
    {'name': 'Teal', 'color': Color(0xFF007A78), 'icon': Icons.person_rounded},
    {'name': 'Blue', 'color': Color(0xFF2563EB), 'icon': Icons.face_rounded},
    {'name': 'Purple', 'color': Color(0xFF7C3AED), 'icon': Icons.face_3_rounded},
    {'name': 'Emerald', 'color': Color(0xFF059669), 'icon': Icons.face_6_rounded},
    {'name': 'Amber', 'color': Color(0xFFD97706), 'icon': Icons.health_and_safety_rounded},
    {'name': 'Rose', 'color': Color(0xFFE11D48), 'icon': Icons.volunteer_activism_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.fullName);
    _nicController = TextEditingController(text: widget.currentProfile.nic);
    _dobController = TextEditingController(text: widget.currentProfile.dob);
    _emailController = TextEditingController(text: widget.currentProfile.email);
    _contactController = TextEditingController(text: widget.currentProfile.contact);
    _photoBase64 = widget.currentProfile.photoBase64;
    _photoUrl = widget.currentProfile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // Profile Picture Helpers
  // -------------------------------------------------------------
  void _openPhotoBottomSheet() {
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C3836),
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Camera
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF007A78)),
                  ),
                  title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Use your device camera', style: TextStyle(fontSize: 12)),
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
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF007A78)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Select a photo from files', style: TextStyle(fontSize: 12)),
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
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_circle_outlined, color: Color(0xFF007A78)),
                  ),
                  title: const Text('Select an Avatar', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Choose a medical or cartoon avatar', style: TextStyle(fontSize: 12)),
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
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _photoBase64 = '';
                        _photoUrl = '';
                      });
                    },
                  ),
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
        setState(() {
          _photoBase64 = b64;
          _photoUrl = '';
        });
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
          title: const Text('Choose an Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: _presetAvatars.map((av) {
              final color = av['color'] as Color;
              final icon = av['icon'] as IconData;
              return InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoUrl = 'preset:${av['name']}';
                    _photoBase64 = '';
                  });
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
      final av = _presetAvatars.firstWhere((a) => a['name'] == name, orElse: () => _presetAvatars[0]);
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

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF007A78),
      child: Text(
        widget.currentProfile.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Date Picker
  // -------------------------------------------------------------
  Future<void> _pickDob() async {
    DateTime initial = DateTime(1995, 1, 1);
    try {
      if (_dobController.text.contains('-')) {
        initial = DateTime.parse(_dobController.text);
      } else if (_dobController.text.contains('/')) {
        final parts = _dobController.text.split('/');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007A78),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() => _dobController.text = formatted);
    }
  }

  // -------------------------------------------------------------
  // Save Flow & Re-authentication Check
  // -------------------------------------------------------------
  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final nic = _nicController.text.trim().toUpperCase();
    final dob = _dobController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty) {
      _snack('Full name is required.');
      return;
    }
    if (nic.isEmpty) {
      _snack('NIC / User ID is required.');
      return;
    }
    if (dob.isEmpty) {
      _snack('Date of birth is required.');
      return;
    }

    final initialEmail = widget.currentProfile.email.trim();
    final initialContact = widget.currentProfile.contact.trim();

    final bool emailChanged = email.isNotEmpty && email.toLowerCase() != initialEmail.toLowerCase();
    final bool contactChanged = contact.isNotEmpty && contact != initialContact;

    // Requirement: if update gmail or phone no, authentication is required
    if (emailChanged || contactChanged) {
      final pwd = await _promptPasswordForAuth(
        emailChanged: emailChanged,
        contactChanged: contactChanged,
      );
      if (pwd == null) {
        // User cancelled re-authentication modal
        return;
      }
      _executeSave(password: pwd);
    } else {
      _executeSave();
    }
  }

  Future<String?> _promptPasswordForAuth({
    required bool emailChanged,
    required bool contactChanged,
  }) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final what = emailChanged && contactChanged
                ? 'email address and phone number'
                : emailChanged
                    ? 'email address'
                    : 'phone number';

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: Color(0xFF007A78), size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Authentication Required',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You are updating your $what. For your security, please verify your identity by entering your current password.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                      errorText: errorText,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007A78), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, null),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p = passwordCtrl.text.trim();
                    if (p.isEmpty) {
                      setDialogState(() => errorText = 'Password cannot be empty');
                      return;
                    }
                    Navigator.pop(dialogCtx, p);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A67),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Verify & Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeSave({String? password}) async {
    setState(() => _isSaving = true);
    try {
      await _service.updateProfile(
        fullName: _nameController.text.trim(),
        nic: _nicController.text.trim().toUpperCase(),
        dob: _dobController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        photoBase64: _photoBase64,
        photoUrl: _photoUrl,
        currentPassword: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF007A78),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // -------------------------------------------------------------
  // Delete Account Flow
  // -------------------------------------------------------------
  Future<void> _confirmDeleteAccount() async {
    // Step 1: Confirmation Modal
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Account?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your HealthQ account?\n\n'
          'This action is irreversible. All your profile information, patient records, and appointment bookings will be permanently removed.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue to Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;
    if (!mounted) return;

    // Step 2: Password Authentication Modal
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorText;

    final confirmedPassword = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Authenticate Deletion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action will permanently delete your account, patient profile, and all related booking appointments. This cannot be undone.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please enter your password to confirm deletion:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                      errorText: errorText,
                      filled: true,
                      fillColor: Colors.red.shade50.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, null),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    final p = passwordCtrl.text.trim();
                    if (p.isEmpty) {
                      setDialogState(() => errorText = 'Password is required to delete account');
                      return;
                    }
                    Navigator.pop(dialogCtx, p);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Permanently Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmedPassword == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.deleteAccount(confirmedPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007A78)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0C3836),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= Profile Picture Section =================
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF007A78), width: 2),
                      ),
                      child: _buildAvatarWidget(radius: 46),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _openPhotoBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A78),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _openPhotoBottomSheet,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF007A78)),
                  label: const Text(
                    'Change Profile Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007A78),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ================= Form Fields =================
              const Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),

              _buildInput(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person_outline,
                hint: 'Your full name',
              ),
              const SizedBox(height: 12),

              _buildInput(
                label: 'NIC / User ID',
                controller: _nicController,
                icon: Icons.badge_outlined,
                hint: 'e.g. 199512345678 or 951234567V',
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: _buildInput(
                    label: 'Date of Birth',
                    controller: _dobController,
                    icon: Icons.calendar_today_outlined,
                    hint: 'DD/MM/YYYY',
                    trailing: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ================= Account & Contact Section =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CONTACT & ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline, size: 11, color: Color(0xFFD97706)),
                        SizedBox(width: 4),
                        Text(
                          'Requires password on change',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildInput(
                label: 'Gmail / Email Address',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                hint: 'name@gmail.com',
                suffixChip: 'Protected',
              ),
              const SizedBox(height: 12),

              _buildInput(
                label: 'Contact Number',
                controller: _contactController,
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone,
                hint: '07X-XXXXXXX',
                suffixChip: 'Protected',
              ),
              const SizedBox(height: 28),

              // ================= Save Button =================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A67),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 26),

              // ================= Danger Zone =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Permanently delete your HealthQ profile and all records.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _confirmDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    Widget? trailing,
    String? suffixChip,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: const Color(0xFF007A78), size: 20),
            suffixIcon: trailing ??
                (suffixChip != null
                    ? Container(
                        margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          suffixChip,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      )
                    : null),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007A78), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
