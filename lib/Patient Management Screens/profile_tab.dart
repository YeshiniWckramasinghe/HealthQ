import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/booking_service.dart';
import '../common Screens/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onHistory;

  const ProfileTab({super.key, required this.onBack, required this.onHistory});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _service = BookingService();
  late final Stream<UserProfile> _stream = _service.myProfile();
  bool _isDeleting = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  String _dob(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso.isEmpty ? '-' : iso;
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _v(String s) => s.isEmpty ? '-' : s;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your HealthQ account?',
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
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  void _openEditProfile(UserProfile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: profile),
      ),
    );
  }

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
                    'To protect your security, please enter your password to authorize permanent deletion:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                  const SizedBox(height: 16),
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

    setState(() => _isDeleting = true);
    try {
      await _service.deleteAccount(confirmedPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been permanently deleted.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildAvatar(UserProfile u) {
    if (u.photoBase64.isNotEmpty) {
      try {
        final raw = u.photoBase64.contains(',') ? u.photoBase64.split(',')[1] : u.photoBase64;
        return CircleAvatar(
          radius: 36,
          backgroundImage: MemoryImage(base64Decode(raw)),
        );
      } catch (_) {}
    }

    if (u.photoUrl.startsWith('preset:')) {
      final name = u.photoUrl.replaceFirst('preset:', '');
      final colorMap = {
        'Teal': const Color(0xFF007A78),
        'Blue': const Color(0xFF2563EB),
        'Purple': const Color(0xFF7C3AED),
        'Emerald': const Color(0xFF059669),
        'Amber': const Color(0xFFD97706),
        'Rose': const Color(0xFFE11D48),
      };
      return CircleAvatar(
        radius: 36,
        backgroundColor: colorMap[name] ?? AppColors.primary300,
        child: const Icon(Icons.person, color: Colors.white, size: 36),
      );
    }

    if (u.photoUrl.isNotEmpty && u.photoUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(u.photoUrl),
      );
    }

    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.primary300,
      child: Text(u.initials,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
              StreamBuilder<UserProfile>(
                stream: _stream,
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _openEditProfile(snap.data!),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary300),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary300,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<UserProfile>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Could not load profile',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.gray400)));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final u = snap.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with Avatar & Info
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _openEditProfile(u),
                            child: Stack(
                              children: [
                                _buildAvatar(u),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary300,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName.isEmpty ? 'Your name' : u.fullName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary500)),
                                const SizedBox(height: 2),
                                Text('User ID: ${_v(u.effectiveUserId)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary300)),
                                const SizedBox(height: 2),
                                Text('NIC: ${_v(u.nic)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.gray400)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('DETAILS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray400)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.primary200.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            _row('User ID', _v(u.effectiveUserId)),
                            _row('Full Name', _v(u.fullName)),
                            _row('NIC', _v(u.nic)),
                            _row('DOB', _dob(u.dob)),
                            _row('Gmail', _v(u.email)),
                            _row('Contact', _v(u.contact)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Update Profile primary action button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _openEditProfile(u),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Update Profile',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007A78),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _btn('Appointments History', widget.onHistory),
                      const SizedBox(height: 10),
                      _btn('Log out', _confirmLogout),
                      const SizedBox(height: 14),

                      // Delete Account danger button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _confirmDeleteAccount,
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          label: const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          _btn('Back to Home', widget.onBack),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
            Flexible(
              child: Text(v,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500)),
            ),
          ],
        ),
      );

  Widget _btn(String t, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary300,
            side: const BorderSide(color: AppColors.primary300, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}