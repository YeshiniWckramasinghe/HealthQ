import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialNic;

  const RegisterScreen({
    super.key,
    this.initialEmail,
    this.initialNic,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nicController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // OPD Duplicate Detection & Existing Record State
  Map<String, dynamic>? _existingOpdRecord;
  bool _isCheckingOpd = false;
  bool _alreadyHasAccount = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialNic != null && widget.initialNic!.isNotEmpty) {
      _nicController.text = widget.initialNic!;
      _checkExistingOpdRecord(widget.initialNic!);
    } else if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _checkExistingOpdByEmail(widget.initialEmail!);
    }

    _nicController.addListener(_onNicChanged);
  }

  @override
  void dispose() {
    _nicController.removeListener(_onNicChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nicController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNicChanged() {
    final text = _nicController.text.trim().toUpperCase();
    if (text.length == 10 || text.length == 12) {
      _checkExistingOpdRecord(text);
    } else if (text.length < 9 && _existingOpdRecord != null) {
      setState(() {
        _existingOpdRecord = null;
        _alreadyHasAccount = false;
      });
    }
  }

  Future<void> _checkExistingOpdRecord(String nic) async {
    final cleanNic = nic.trim().toUpperCase();
    if (cleanNic.length < 9) return;
    setState(() => _isCheckingOpd = true);
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc =
          await FirebaseFirestore.instance.collection('users').doc(cleanNic).get();

      Map<String, dynamic>? data = doc.exists ? doc.data() : null;

      if (data == null) {
        final q = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: cleanNic)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          data = q.docs.first.data();
        }
      }

      if (data != null && mounted) {
        final bool isAuthLinked = data['authLinked'] == true ||
            (data['authUid'] != null &&
                data['authUid'].toString().isNotEmpty &&
                data['isRegisteredByStaff'] != true);

        if (isAuthLinked) {
          setState(() {
            _existingOpdRecord = null;
            _alreadyHasAccount = true;
          });
        } else {
          // Found hospital OPD record! Pre-fill details so user does not need to retype
          setState(() {
            _existingOpdRecord = data;
            _alreadyHasAccount = false;

            if (_firstNameController.text.isEmpty && data?['firstName'] != null) {
              _firstNameController.text = data!['firstName'].toString();
            }
            if (_lastNameController.text.isEmpty && data?['lastName'] != null) {
              _lastNameController.text = data!['lastName'].toString();
            }
            if (_dobController.text.isEmpty && data?['dob'] != null) {
              _dobController.text = data!['dob'].toString();
            }
            if (_contactController.text.isEmpty &&
                (data?['contactNo'] != null || data?['contact'] != null)) {
              _contactController.text =
                  (data!['contactNo'] ?? data['contact']).toString();
            }
            if (_emailController.text.isEmpty && data?['email'] != null) {
              _emailController.text = data!['email'].toString();
            }
          });
        }
      } else if (mounted) {
        setState(() {
          _existingOpdRecord = null;
          _alreadyHasAccount = false;
        });
      }
    } catch (e) {
      debugPrint('Check existing OPD error: $e');
    } finally {
      if (mounted) setState(() => _isCheckingOpd = false);
    }
  }

  Future<void> _checkExistingOpdByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) return;
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty && mounted) {
        final data = q.docs.first.data();
        final bool isAuthLinked = data['authLinked'] == true ||
            (data['authUid'] != null &&
                data['authUid'].toString().isNotEmpty &&
                data['isRegisteredByStaff'] != true);

        if (isAuthLinked) {
          setState(() {
            _existingOpdRecord = null;
            _alreadyHasAccount = true;
          });
        } else {
          setState(() {
            _existingOpdRecord = data;
            _alreadyHasAccount = false;

            final nicVal = (data['nic'] ?? data['userId'] ?? '').toString();
            if (_nicController.text.isEmpty && nicVal.isNotEmpty) {
              _nicController.text = nicVal;
            }
            if (_firstNameController.text.isEmpty && data['firstName'] != null) {
              _firstNameController.text = data['firstName'].toString();
            }
            if (_lastNameController.text.isEmpty && data['lastName'] != null) {
              _lastNameController.text = data['lastName'].toString();
            }
            if (_dobController.text.isEmpty && data['dob'] != null) {
              _dobController.text = data['dob'].toString();
            }
            if (_contactController.text.isEmpty &&
                (data['contactNo'] != null || data['contact'] != null)) {
              _contactController.text =
                  (data['contactNo'] ?? data['contact']).toString();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Check existing OPD by email error: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary400,
              onPrimary: AppColors.white,
              onSurface: AppColors.primary500,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      // Trigger validation on date field once selected
      _formKey.currentState?.validate();
    }
  }

  Future<void> _signUp() async {
    // 1. Validate all required fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please correct the highlighted fields before proceeding.'),
        ),
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final dob = _dobController.text.trim();
    final nic = _nicController.text.trim().toUpperCase();
    final email = _emailController.text.trim().toLowerCase();
    final contact = _contactController.text.trim();
    final password = _passwordController.text;

    // 2. Prevent duplicate account creation if an active online account already exists
    if (_alreadyHasAccount) {
      _showAlreadyRegisteredDialog(email, nic);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 3. Double-check Firestore for an existing record to authenticate using registered data
      DocumentSnapshot<Map<String, dynamic>>? existingDoc;
      final docByNic =
          await FirebaseFirestore.instance.collection('users').doc(nic).get();
      if (docByNic.exists && docByNic.data() != null) {
        existingDoc = docByNic;
      } else {
        final qNic = await FirebaseFirestore.instance
            .collection('users')
            .where('nic', isEqualTo: nic)
            .limit(1)
            .get();
        if (qNic.docs.isNotEmpty) {
          existingDoc = qNic.docs.first;
        } else {
          final qEmail = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (qEmail.docs.isNotEmpty) {
            existingDoc = qEmail.docs.first;
          }
        }
      }

      if (existingDoc != null && existingDoc.data() != null) {
        final d = existingDoc.data()!;
        final bool isAlreadyLinked = d['authLinked'] == true ||
            (d['authUid'] != null &&
                d['authUid'].toString().isNotEmpty &&
                d['isRegisteredByStaff'] != true);

        if (isAlreadyLinked) {
          setState(() => _isLoading = false);
          if (mounted) {
            _showAlreadyRegisteredDialog(email, nic);
          }
          return;
        }
      }

      // 4. Create Firebase Auth user
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName('$firstName $lastName');
        final userId = nic;

        // Retrieve existing OPD data if registered in-person so we do NOT duplicate records
        final Map<String, dynamic> existingData = existingDoc?.data() ?? {};

        final userData = {
          ...existingData,
          'userId': userId,
          'nic': nic,
          'patientId': userId,
          'authUid': user.uid,
          'uid': user.uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': '$firstName $lastName',
          'dob': dob,
          'email': email,
          'contactNo': contact,
          'role': 'patient',
          // Mark as claimed and online-activated by patient
          'isRegisteredByStaff': false,
          'authLinked': true,
          'linkedAt': FieldValue.serverTimestamp(),
          'createdAt': existingData['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Persist into users/{user.uid}
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));

        // Also persist/merge under users/{userId} so lookup by User ID / NIC remains identical
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(userData, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              contactNo: contact,
              email: email,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FIREBASE REGISTER ERROR: ${e.code} — ${e.message}');
      String message = 'Registration failed. Please try again.';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use. Please sign in or reset password.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'invalid-email':
          message = 'The email address format is invalid.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Registration failed.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlreadyRegisteredDialog(String email, String nic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.primary400, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Account Already Exists',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'An online account is already registered with this NIC ($nic) or Email ($email).\n\n'
          'Please sign in with your password, or reset your password if you forgot it.',
          style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.gray400)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Sign In Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Patient Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All fields marked with * are required to register your patient account.',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
                const SizedBox(height: 16),

                // 1. Existing OPD Record Alert Banner
                if (_existingOpdRecord != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF81C784), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Color(0xFF2E7D32), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hospital OPD Record Found',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'We found your record registered at ${_existingOpdRecord!['registeredHospital'] ?? 'Hospital OPD'}. Your details have been pre-filled. Set your password to activate online account access.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Already Has Online Account Banner
                if (_alreadyHasAccount)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFE65100), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Online Account Already Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFFBF360C),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'An online patient account is already registered for this NIC. Please sign in with your password.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFBF360C),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () =>
                                    Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                ),
                                child: const Text(
                                  'Click here to Sign In →',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFFE65100),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // NIC Number Field
                _formField(
                  controller: _nicController,
                  hint: 'NIC Number * (e.g. 199012345678 or 901234567V)',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.text,
                  suffixIcon: _isCheckingOpd
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary400,
                            ),
                          ),
                        )
                      : null,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'NIC number is required';
                    if (!RegExp(r'^([0-9]{9}[vVxX]|[0-9]{12})$').hasMatch(v)) {
                      return 'Invalid NIC. Use 9 digits+V/X (old) or 12 digits (new)';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 2),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 13, color: AppColors.primary300),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Your User ID defaults to your NIC Number. If registered at OPD, your data will link automatically.',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary400,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // First Name Field
                _formField(
                  controller: _firstNameController,
                  hint: 'First Name *',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'First name is required';
                    if (v.length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(v)) {
                      return 'Enter a valid name (letters only)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Last Name Field
                _formField(
                  controller: _lastNameController,
                  hint: 'Last Name *',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Last name is required';
                    if (v.length < 2) {
                      return 'Last name must be at least 2 characters';
                    }
                    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(v)) {
                      return 'Enter a valid name (letters only)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Date of Birth Field
                _formField(
                  controller: _dobController,
                  hint: 'Date of Birth (DD/MM/YYYY) *',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Date of birth is required';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Email Field
                _formField(
                  controller: _emailController,
                  hint: 'Email (Gmail) *',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return 'Enter a valid email address (e.g. name@gmail.com)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Contact No Field
                _formField(
                  controller: _contactController,
                  hint: 'Contact No * (e.g. 0712345678)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Contact number is required';
                    if (!RegExp(r'^(?:0|\+?94)?7[0-9]{8}$').hasMatch(v)) {
                      return 'Enter a valid Sri Lankan mobile number (e.g. 07XXXXXXXX)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Password Field
                _formField(
                  controller: _passwordController,
                  hint: 'Password (min 6 characters) *',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.gray400,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) return 'Password is required';
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Confirm Password Field
                _formField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm Password *',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.gray400,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary400,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _existingOpdRecord != null
                                ? 'Activate Online Account'
                                : 'Sign Up',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary400,
                      side: const BorderSide(color: AppColors.primary300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Already have an account? Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
        prefixIcon:
            icon != null ? Icon(icon, color: AppColors.primary300, size: 20) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary400, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, height: 1.2),
      ),
    );
  }
}