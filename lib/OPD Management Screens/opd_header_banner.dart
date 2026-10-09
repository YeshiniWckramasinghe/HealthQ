import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OpdHeaderBanner extends StatelessWidget {
  final String title;
  final String nurseId;
  final String department;
  final String hospital;
  final String? photoBase64;
  final String? photoUrl;
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
                  // Avatar badge with photo or 'N'
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: _buildAvatar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        final raw = photoBase64!.contains(',') ? photoBase64!.split(',')[1] : photoBase64!;
        final bytes = base64Decode(raw);
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('preset:')) {
        final name = photoUrl!.replaceFirst('preset:', '');
        final Map<String, dynamic> presetMap = {
          'nurse_teal': {'color': const Color(0xFF007A78), 'icon': Icons.medical_services_rounded},
          'nurse_blue': {'color': const Color(0xFF2563EB), 'icon': Icons.local_hospital_rounded},
          'nurse_emerald': {'color': const Color(0xFF059669), 'icon': Icons.health_and_safety_rounded},
          'nurse_purple': {'color': const Color(0xFF7C3AED), 'icon': Icons.favorite_rounded},
          'nurse_rose': {'color': const Color(0xFFE11D48), 'icon': Icons.healing_rounded},
          'nurse_amber': {'color': const Color(0xFFD97706), 'icon': Icons.shield_rounded},
        };
        final av = presetMap[name] ?? presetMap['nurse_teal']!;
        return CircleAvatar(
          radius: 20,
          backgroundColor: av['color'] as Color,
          child: Icon(av['icon'] as IconData, color: Colors.white, size: 20),
        );
      }

      if (photoUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(photoUrl!),
        );
      }
    }

    String initial = 'N';
    if (title.isNotEmpty) {
      final clean = title.replaceFirst(RegExp(r'Good Morning,?\s*', caseSensitive: false), '').trim();
      if (clean.isNotEmpty && clean.toLowerCase() != 'nurse') {
        initial = clean[0].toUpperCase();
      }
    }

    return Container(
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
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: OpdColors.primary500,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
