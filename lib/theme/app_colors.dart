import 'package:flutter/material.dart';

class AppColors {
  // Primary (teal/green) — from style guide
  static const Color primary100 = Color(0xFFF0F7F6);
  static const Color primary200 = Color(0xFF2E968E);
  static const Color primary300 = Color(0xFF007471);
  static const Color primary400 = Color(0xFF00615D);
  static const Color primary500 = Color(0xFF063A37);
  static const Color primary900 = primary500;
  
  // Status Badge Colors
  // Waiting (Amber / Orange)
  static const Color statusWaitingBg = Color(0xFFFEF3C7);
  static const Color statusWaitingText = Color(0xFFD97706);
  static const Color statusWaitingBorder = Color(0xFFFDE68A);

  // In Consult (Emerald / Mint)
  static const Color statusInConsultBg = Color(0xFFD1FAE5);
  static const Color statusInConsultText = Color(0xFF047857);
  static const Color statusInConsultBorder = Color(0xFFA7F3D0);

  // Absent (Light Red / Coral)
  static const Color statusAbsentBg = Color(0xFFFEE2E2);
  static const Color statusAbsentText = Color(0xFFDC2626);
  static const Color statusAbsentBorder = Color(0xFFFECACA);

  // Gray & Neutrals
  static const Color gray100 = Color(0xFFEBEBEB);
  static const Color gray300 = Color(0xFFA6A6A6);
  static const Color gray400 = Color(0xFF868686);
  static const Color gray500 = Color(0xFF323232);
  static const Color gray600 = Color(0xFF282828);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF868686);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderTeal = Color(0xFF2E968E);
}

/// Backwards compatibility alias for OPD screens
typedef OpdColors = AppColors;