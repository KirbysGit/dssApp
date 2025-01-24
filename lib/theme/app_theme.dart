import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color deepForestGreen = Color(0xFF2C5530);
  static const Color pineGreen = Color(0xFF3E7B4F);
  static const Color mossGreen = Color(0xFF89B399);
  static const Color mistGray = Color(0xFFF5F7F5);
  static const Color accentGold = Color(0xFFD4AF37);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: pineGreen,
      scaffoldBackgroundColor: mistGray,
      colorScheme: ColorScheme.light(
        primary: pineGreen,
        secondary: mossGreen,
        surface: Colors.white,
        background: mistGray,
        onPrimary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: deepForestGreen,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pineGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: deepForestGreen.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // AppBar theme
  static const Color appBarBackgroundColor = Color(0xFF1A2F25);
  static const Color appBarForegroundColor = Color(0xFFE6EBE4);

  // Card theme
  static const double cardElevation = 2.0;
  static final BorderRadius cardBorderRadius = BorderRadius.circular(16.0);

  // Button themes
  static const Color elevatedButtonBackgroundColor = Color(0xFF2C5530);
  static const Color elevatedButtonForegroundColor = Color(0xFFE6EBE4);
  static const EdgeInsets elevatedButtonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static final BorderRadius elevatedButtonBorderRadius = BorderRadius.circular(12);

  // Text themes
  static const TextStyle headlineLarge = TextStyle(
    color: deepForestGreen,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headlineMedium = TextStyle(
    color: deepForestGreen,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: deepForestGreen,
  );
  static const TextStyle bodyMedium = TextStyle(
    color: pineGreen,
  );

  // Icon theme
  static const double iconSize = 24.0;
  static const Color iconColor = pineGreen;

  // Custom button style
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: pineGreen,
    foregroundColor: mistGray,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );
} 