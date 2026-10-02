import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../Patient Management Screens/home_screen.dart';
import 'login_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  void _decline(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _accept(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _section(
                          '1. Acceptance of Terms',
                          'By logging into GovHealth OPD, you agree to be bound by the terms and policies governed by the Ministry of Health Sri Lanka.',
                        ),
                        _section(
                          '2. Authorized Use',
                          'This system is strictly restricted to authorized healthcare personnel of Government Hospital OPD only. Unauthorized access is strictly prohibited and punishable by law.',
                        ),
                        _section(
                          '3. Patient Confidentiality',
                          "All patient data accessed through this system is strictly confidential and governed by national health data protection regulations and Sri Lanka's medical statutes.",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By clicking "Accept", you confirm you have read, understood, and agreed to abide by medical protocols.',
                style: TextStyle(color: AppColors.gray400, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decline(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary400,
                        side: const BorderSide(color: AppColors.primary300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _accept(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary400,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Accept'),
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

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(color: AppColors.gray500, fontSize: 13)),
        ],
      ),
    );
  }
}