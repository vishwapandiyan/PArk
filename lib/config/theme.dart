import 'package:flutter/material.dart';
import 'app_theme_dark.dart';
import 'color_scheme.dart';

/// Main theme class for the parking app
/// Provides both light and dark themes with consistent branding
class AppTheme {
  // Brand colors for reference (actual colors defined in color_scheme.dart)
  static const Color primaryBlue = AppColors.primaryBlue;
  static const Color secondaryGreen = AppColors.secondaryGreen;
  static const Color accentOrange = AppColors.accentOrange;

  /// Returns the dark theme (primary theme for the app)
  static ThemeData darkTheme() {
    return AppThemeDark.create();
  }

  /// Returns a light theme (fallback/alternative)
  /// Note: The app is designed primarily for dark theme
  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primaryBlue,
        secondary: secondaryGreen,
        tertiary: accentOrange,
        surface: Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );
  }
}


