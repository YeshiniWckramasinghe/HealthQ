import 'package:flutter/material.dart';

import '../services/doctor_profile_service.dart';
import 'doctor_ui.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() =>
      _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  bool _initialised = false;
  String _specialty = '';
  String _department = '';
  int? _avatarColor;
  int? _originalAvatarColor;
  bool _saving = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final p = DoctorSessionScope.of(context).profile;
    _name.text = p.name;
    _email.text = p.email;
    _phone.text = DoctorProfileService.formatPhone(p.phone);
    _specialty = p.specialty;
    _department = p.department;
    _avatarColor = p.avatarColor;
    _originalAvatarColor = p.avatarColor;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// A DropdownButton asserts if its value is not among its items, so the
  /// current value is always included even if it is not in the preset list.
  List<String> _withCurrent(List<String> base, String current) =>
      current.isEmpty || base.contains(current)
          ? base
          : <String>[current, ...base];

  bool _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final phone = DoctorProfileService.normalizePhone(_phone.text);

    setState(() {
      _nameError = name.length < 3 ? 'Please enter your full name' : null;
      _emailError = DoctorProfileService.isValidEmail(email)
          ? null
          : 'Enter a valid email address';
      _phoneError =
          phone == null ? 'Enter a valid phone number, e.g. 071 234 5678' : null;
    });
    return _nameError == null && _emailError == null && _phoneError == null;
  }

  Future<void> _save() async {
    if (_saving || !_validate()) return;
    final profile = DoctorSessionScope.of(context).profile;
    final phone = DoctorProfileService.normalizePhone(_phone.text);
    if (phone == null) return;

    setState(() => _saving = true);
    try {
      await DoctorProfileService.instance.updateProfile(
        staffId: profile.staffId,
        name: _name.text,
        specialty: _specialty,
        department: _department,
        email: _email.text,
        phone: phone,
      );
      if (_avatarColor != null && _avatarColor != _originalAvatarColor) {
        await DoctorProfileService.instance
            .setAvatarColor(profile.staffId, _avatarColor!);
      }
      if (!mounted) return;
      showDoctorSnack(context, 'Profile updated successfully.');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showDoctorSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickAvatarColor() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose profile avatar',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: DoctorColors.ink),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final c in DoctorProfileService.avatarColors)
                    GestureDetector(
                      onTap: () {
                        setState(() => _avatarColor = c);
                        Navigator.of(ctx).pop();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InitialsAvatar(
                            name: _name.text,
                            size: 56,
                            color: Color(c),
                          ),
                          if (_avatarColor == c)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: DoctorColors.ink, width: 2.5),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DoctorColors.muted)),
      );

  Widget _box({required IconData icon, required Widget child, String? error}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: error == null ? DoctorColors.line : DoctorColors.red),
          ),
          child: Row(
            children: [
              Icon(icon, color: DoctorColors.teal, size: 20),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(error,
                style: const TextStyle(fontSize: 12, color: DoctorColors.red)),
          ),
      ],
    );
  }

  InputDecoration _plain(String hint) => InputDecoration(
        border: InputBorder.none,
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: DoctorColors.hint, fontSize: 14.5),
      );

  Widget _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(hint,
            style: const TextStyle(color: DoctorColors.hint, fontSize: 14.5)),
        icon: const Icon(Icons.keyboard_arrow_down, color: DoctorColors.muted),
        dropdownColor: Colors.white,
        style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: DoctorColors.ink),
        items: [
          for (final i in items)
            DropdownMenuItem<String>(
              value: i,
              child: Text(i, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = DoctorSessionScope.of(context).profile;
    final avatarColor =
        _avatarColor != null ? Color(_avatarColor!) : DoctorColors.teal;

    return DoctorScaffold(
      child: Column(
        children: [
          const DoctorPageHeader(title: 'Edit Doctor Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatarColor,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InitialsAvatar(
                          name: _name.text,
                          size: 96,
                          color: avatarColor,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: DoctorColors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatarColor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: DoctorColors.teal, width: 1.4),
                      ),
                      child: const Text(
                        'Change Photo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: DoctorColors.teal,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _label('Doctor Name'),
                _box(
                  icon: Icons.person_outline_rounded,
                  error: _nameError,
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _nameError = null),
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: DoctorColors.ink),
                    decoration: _plain('Dr. Full Name'),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Specialty'),
                _box(
                  icon: Icons.medical_services_outlined,
                  child: _dropdown(
                    value: _specialty.isEmpty ? null : _specialty,
                    items: _withCurrent(
                        DoctorProfileService.specialties, _specialty),
                    hint: 'Select specialty',
                    onChanged: (v) => setState(() => _specialty = v),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Hospital / Department'),
                _box(
                  icon: Icons.local_hospital_outlined,
                  child: _dropdown(
                    value: _department.isEmpty ? null : _department,
                    items: _withCurrent(
                        DoctorProfileService.departments, _department),
                    hint: 'Select department',
                    onChanged: (v) => setState(() => _department = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'Hospital: ${profile.hospital} (managed by hospital admin)',
                    style: const TextStyle(
                        fontSize: 11.5, color: DoctorColors.muted),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Email'),
                _box(
                  icon: Icons.mail_outline_rounded,
                  error: _emailError,
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    onChanged: (_) => setState(() => _emailError = null),
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: DoctorColors.ink),
                    decoration: _plain('name@hospital.lk'),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Phone'),
                _box(
                  icon: Icons.phone_outlined,
                  error: _phoneError,
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() => _phoneError = null),
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: DoctorColors.ink),
                    decoration: _plain('071 234 5678'),
                  ),
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  label: 'Save Changes',
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                OutlineActionButton(
                  label: 'Cancel',
                  color: DoctorColors.muted,
                  onPressed:
                      _saving ? null : () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
