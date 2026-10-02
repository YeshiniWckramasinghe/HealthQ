import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OpdHeaderBanner extends StatelessWidget {
  final String title;
  final String nurseId;
  final String department;
  final String hospital;
  final VoidCallback? onAvatarTap;

  const OpdHeaderBanner({
    super.key,
    required this.title,
    this.nurseId = 'ID: NUR1002-021',
    this.department = 'General Medicine OPD',
    this.hospital = 'Government Hospital — Colombo',
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: const BoxDecoration(
        color: OpdColors.primary500,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background hospital corridor photo
          Image.asset(
            'assets/images/hospital_hallway.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: OpdColors.primary500,
            ),
          ),
          // Dark teal gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  OpdColors.primary500.withValues(alpha: 0.85),
                  OpdColors.primary400.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: OpdColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nurseId,
                          style: TextStyle(
                            color: OpdColors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          department,
                          style: const TextStyle(
                            color: OpdColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          hospital,
                          style: TextStyle(
                            color: OpdColors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar badge 'N'
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OpdColors.primary100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OpdColors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: OpdColors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: OpdColors.primary500,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
