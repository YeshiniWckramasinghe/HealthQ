import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'verification_screen.dart';
import 'staff_login_screen.dart';
import '../Patient Management Screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify account status in Cloud Firestore
      if (credential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          final isEmailVerified = userData?['emailVerified'] == true;
          final isPhoneVerified = userData?['phoneVerified'] == true;
          final isFirebaseVerified = credential.user!.emailVerified;

          if (!isEmailVerified && !isPhoneVerified && !isFirebaseVerified) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              final contactNo = userData?['contactNo']?.toString() ?? '';
              _showNotVerifiedDialog(email, contactNo);
            }
            return;
          }

          // Record login timestamp
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTH ERROR CODE: ${e.code} — ${e.message}');

      // Check if password was reset and saved in Firestore users collection
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        try {
          final userSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (userSnap.docs.isNotEmpty) {
            final data = userSnap.docs.first.data();
            final dbPass = data['password']?.toString();
            if (dbPass != null && dbPass == password) {
              await userSnap.docs.first.reference.set({
                'lastLogin': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
              return;
            }
          }
        } catch (dbErr) {
          debugPrint('Firestore fallback login check: $dbErr');
        }
      }

      String message = 'Login failed. Please try again.';
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'The email address format is invalid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = e.message ?? 'Authentication failed.';
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final auth = account.authentication;

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Google authentication failed: User is null.');
      }

      final googleEmail = account.email.trim();

      // Look up user in Firestore users collection
      Map<String, dynamic>? userData;
      String? matchedDocId;

      // 1. Check by UID first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        userData = userDoc.data();
        matchedDocId = user.uid;
      } else {
        // 2. Query by email (exact match)
        final queryExact = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: googleEmail)
            .limit(1)
            .get();

        if (queryExact.docs.isNotEmpty) {
          userData = queryExact.docs.first.data();
          matchedDocId = queryExact.docs.first.id;
        } else {
          // 3. Query by email (lowercase)
          final queryLower = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: googleEmail.toLowerCase())
              .limit(1)
              .get();

          if (queryLower.docs.isNotEmpty) {
            userData = queryLower.docs.first.data();
            matchedDocId = queryLower.docs.first.id;
          }
        }
      }

      // ---------------------------------------------------------
      // CASE 1: NOT REGISTERED
      // Show clear "Account Not Found" dialog with Register button
      // ---------------------------------------------------------
      if (userData == null) {
        debugPrint('⛔ GOOGLE SIGN-IN BLOCKED: $googleEmail is not registered.');
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          try {
            await user.delete();
          } catch (_) {}
        }
        await FirebaseAuth.instance.signOut();
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        if (mounted) {
          _showNotRegisteredDialog(googleEmail);
        }
        return;
      }

      // ---------------------------------------------------------
      // CASE 2: REGISTERED BUT NOT VERIFIED
      // Show clear "Verification Required" dialog with Verify button
      // ---------------------------------------------------------
      final bool isEmailVerified = userData['emailVerified'] == true;
      final bool isPhoneVerified = userData['phoneVerified'] == true;

      if (!isEmailVerified && !isPhoneVerified) {
        debugPrint('⚠️ GOOGLE SIGN-IN BLOCKED: $googleEmail is not verified.');
        await FirebaseAuth.instance.signOut();
        try {
          await googleSignIn.signOut();
        } catch (_) {}

        if (mounted) {
          final contactNo = userData['contactNo']?.toString() ?? '';
          _showNotVerifiedDialog(googleEmail, contactNo);
        }
        return;
      }

      // ---------------------------------------------------------
      // CASE 3: REGISTERED AND VERIFIED
      // Sync Google profile and navigate to HomeScreen
      // ---------------------------------------------------------
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...userData,
        'googleAuth': true,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (matchedDocId != null && matchedDocId != user.uid) {
        await FirebaseFirestore.instance.collection('users').doc(matchedDocId).set({
          'lastLogin': FieldValue.serverTimestamp(),
          'linkedGoogleUid': user.uid,
        }, SetOptions(merge: true));
      }

      debugPrint('✅ GOOGLE SIGN-IN SUCCESS: $googleEmail authenticated as verified patient.');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('GOOGLE SIGNIN ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign-in cancelled or failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= NOT REGISTERED MODAL DIALOG =================
  void _showNotRegisteredDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.statusAbsentBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.statusAbsentBorder, width: 2),
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: AppColors.statusAbsentText,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Account Not Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.5),
                children: [
                  const TextSpan(text: 'The Google account\n'),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  const TextSpan(text: '\nis not registered in HealthQ.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderTeal.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Please register as a patient first to create your medical profile and access the hospital system.',
                style: TextStyle(fontSize: 12, color: AppColors.primary400, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text(
                  'Register New Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary400,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.gray400, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NOT VERIFIED MODAL DIALOG =================
  void _showNotVerifiedDialog(String email, String contactNo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.statusWaitingBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.statusWaitingBorder, width: 2),
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: AppColors.statusWaitingText,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verification Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.5),
                children: [
                  const TextSpan(text: 'An account exists for\n'),
                  TextSpan(
                    text: email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                  const TextSpan(text: ',\nbut it has not been verified yet.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusWaitingBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.statusWaitingBorder),
              ),
              child: const Text(
                'Please complete 6-digit OTP verification via Gmail or mobile to activate your account.',
                style: TextStyle(fontSize: 12, color: AppColors.statusWaitingText, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VerificationScreen(
                        contactNo: contactNo,
                        email: email,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text(
                  'Verify Account Now',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary400,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.gray400, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onManagementNextTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/onboard_1.jpeg'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'HealthQ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please log in to continue',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Email field
              _InputField(
                controller: _emailController,
                hint: 'Email (Gmail)',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password field
              _InputField(
                controller: _passwordController,
                hint: 'Password',
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
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: _emailController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.primary300),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
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
                      : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary200,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 18),

              const _DividerWithText(text: 'OR'),
              const SizedBox(height: 18),

              // Google sign-in
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    width: 22,
                    height: 22,
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const _DividerWithText(text: 'As a Management'),
              const SizedBox(height: 18),

              // Staff login
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _onManagementNextTapped,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary400,
                    side: const BorderSide(color: AppColors.primary300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.badge_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Staff Portal Sign In →',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary300),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DividerWithText extends StatelessWidget {
  final String text;
  const _DividerWithText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: const TextStyle(color: AppColors.gray400)),
        ),
        const Expanded(child: Divider(color: AppColors.gray300)),
      ],
    );
  }
}