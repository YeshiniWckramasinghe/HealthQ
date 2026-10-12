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
    this.photoBase64,
    this.photoUrl,
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
    // 1. Preset Avatar check (in photoUrl or photoBase64)
    final presetCandidate = (photoUrl != null && photoUrl!.startsWith('preset:'))
        ? photoUrl!
        : ((photoBase64 != null && photoBase64!.startsWith('preset:')) ? photoBase64! : null);

    if (presetCandidate != null) {
      final name = presetCandidate.replaceFirst('preset:', '');
      final Map<String, dynamic> presetMap = {
        'nurse_teal': {'color': const Color(0xFF007A78), 'icon': Icons.medical_services_rounded},
        'nurse_blue': {'color': const Color(0xFF2563EB), 'icon': Icons.local_hospital_rounded},
        'nurse_emerald': {'color': const Color(0xFF059669), 'icon': Icons.health_and_safety_rounded},
        'nurse_purple': {'color': const Color(0xFF7C3AED), 'icon': Icons.favorite_rounded},
        'nurse_rose': {'color': const Color(0xFFE11D48), 'icon': Icons.healing_rounded},
        'nurse_amber': {'color': const Color(0xFFD97706), 'icon': Icons.shield_rounded},
      };
      final av = presetMap[name] ?? presetMap['nurse_teal']!;
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: av['color'] as Color,
          child: Icon(av['icon'] as IconData, color: Colors.white, size: 20),
        ),
      );
    }

    // 2. Network URL check (in photoUrl or photoBase64)
    final urlCandidate = (photoUrl != null && (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://')))
        ? photoUrl!
        : ((photoBase64 != null && (photoBase64!.startsWith('http://') || photoBase64!.startsWith('https://')))
            ? photoBase64!
            : null);

    if (urlCandidate != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: OpdColors.primary100,
          backgroundImage: NetworkImage(urlCandidate),
          onBackgroundImageError: (error, stackTrace) {},
        ),
      );
    }

    // 3. Base64 Image check
    final base64Candidate = (photoBase64 != null &&
            photoBase64!.isNotEmpty &&
            !photoBase64!.startsWith('preset:') &&
            !photoBase64!.startsWith('http'))
        ? photoBase64!
        : ((photoUrl != null &&
                photoUrl!.isNotEmpty &&
                !photoUrl!.startsWith('preset:') &&
                !photoUrl!.startsWith('http'))
            ? photoUrl!
            : null);

    if (base64Candidate != null) {
      try {
        final raw = base64Candidate.contains(',')
            ? base64Candidate.split(',')[1].trim()
            : base64Candidate.trim();
        if (raw.isNotEmpty) {
          final bytes = base64Decode(raw);
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: OpdColors.primary100,
              backgroundImage: MemoryImage(bytes),
            ),
          );
        }
      } catch (e) {
        debugPrint('OpdHeaderBanner base64 decode note: $e');
      }
    }

    // 4. Fallback Initial Letter badge
    String initial = 'N';
    if (title.isNotEmpty) {
      final clean = title.replaceFirst(RegExp(r'Good Morning,?\s*', caseSensitive: false), '').trim();
      if (clean.isNotEmpty && clean.toLowerCase() != 'nurse') {
        initial = clean[0].toUpperCase();
      }
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: OpdColors.primary100,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
