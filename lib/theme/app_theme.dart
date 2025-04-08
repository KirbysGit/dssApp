// lib/theme/app_theme.dart

// Description :
// This file contains the AppTheme class which is responsible for :
// - Providing the theme data for the app.

// Importing Flutter Material Package.
import 'package:flutter/material.dart';

class AppTheme {
  // Colors.
  static const Color deepForestGreen = Color(0xFF2C5530);
  static const Color pineGreen = Color(0xFF3E7B4F);
  static const Color mossGreen = Color(0xFF89B399);
  static const Color mistGray = Color(0xFFF5F7F5);
  static const Color accentGold = Color(0xFFD4AF37);

  // Light Theme.
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

  // Card Decoration.
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

  // AppBar Background Color.
  static const Color appBarBackgroundColor = Color(0xFF1A2F25);

  // AppBar Foreground Color.
  static const Color appBarForegroundColor = Color(0xFFE6EBE4);

  // Card Elevation.
  static const double cardElevation = 2.0;

  // Card Border Radius.
  static final BorderRadius cardBorderRadius = BorderRadius.circular(16.0);

  // Elevated Button Background Color.
  static const Color elevatedButtonBackgroundColor = Color(0xFF2C5530);

  // Elevated Button Foreground Color.


  // Elevated Button Padding.
  static const Color elevatedButtonForegroundColor = Color(0xFFE6EBE4);

  // Elevated Button Border Radius.
  static const EdgeInsets elevatedButtonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static final BorderRadius elevatedButtonBorderRadius = BorderRadius.circular(12);

  // Text Themes.
  static const TextStyle headlineLarge = TextStyle(
    color: deepForestGreen,
    fontWeight: FontWeight.bold,
  );  

  // Headline Medium.
  static const TextStyle headlineMedium = TextStyle(
    color: deepForestGreen,
    fontWeight: FontWeight.w600,
  );

  // Body Large.
  static const TextStyle bodyLarge = TextStyle(
    color: deepForestGreen,
  );

  // Body Medium.
  static const TextStyle bodyMedium = TextStyle(
    color: pineGreen,
  );

  // Icon Size.
  static const double iconSize = 24.0;

  // Icon Color.
  static const Color iconColor = pineGreen;

  // Primary Button Style.
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: pineGreen,
    foregroundColor: mistGray,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  // Gradient Background.
  static BoxDecoration get gradientBackground => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        deepForestGreen.withOpacity(0.9),
        pineGreen.withOpacity(0.7),
        mistGray,
      ],
    ),
  );
} 