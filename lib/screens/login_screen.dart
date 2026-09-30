import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'register_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        color: AppColors.black.withOpacity(0.06),
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
              Text(
                'Please log in to continue',
                style: TextStyle(color: AppColors.gray400, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Email field
              _InputField(
                controller: _emailController,
                hint: 'Gmail',
                icon: Icons.mail_outline,
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
                    // TODO: navigate to Forgot Password screen
                  },
                  child: Text(
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
                  onPressed: () {
                    // TODO: call FirebaseAuth signInWithEmailAndPassword
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary400,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Sign In'),
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
                  child: const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 18),

              _DividerWithText(text: 'OR'),
              const SizedBox(height: 18),

              // Google sign-in
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: implement Google sign-in
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray600,
                    side: BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _DividerWithText(text: 'As a Management'),
              const SizedBox(height: 18),

              // Staff login
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: navigate to Staff Login screen
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary400,
                    side: BorderSide(color: AppColors.primary300),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Next →'),
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

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
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
        Expanded(child: Divider(color: AppColors.gray300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: TextStyle(color: AppColors.gray400)),
        ),
        Expanded(child: Divider(color: AppColors.gray300)),
      ],
    );
  }
}