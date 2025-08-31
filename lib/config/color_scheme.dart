import 'package:flutter/material.dart';

/// Dark theme color system for the parking app
/// Following Material Design 3 guidelines with custom brand colors
class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  
  // Dark Theme Neutrals
  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF141821);
  static const Color surfaceVariant = Color(0xFF1B2230);
  static const Color outline = Color(0xFF2A3446);
  static const Color onBackground = Color(0xFFE6EAF2);
  static const Color onSurface = Color(0xFFC6CEDA);
  static const Color disabledText = Color(0xFF7C8A9E);
  static const Color divider = Color(0xFF223049);
  
  // State Colors
  static const Color error = Color(0xFFEF5350);
  static const Color success = secondaryGreen;
  static const Color warning = accentOrange;
  
  // High Contrast Text
  static const Color onPrimary = Color(0xFF0A0A0A);
  static const Color onSecondary = Color(0xFF0A0A0A);
  static const Color onTertiary = Color(0xFF0A0A0A);
  static const Color onError = Color(0xFFFFFFFF);
}

/// Creates the dark ColorScheme for Material 3
ColorScheme createDarkColorScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    
    // Primary colors
    primary: AppColors.primaryBlue,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFF1565C0), // Darker blue for containers
    onPrimaryContainer: AppColors.onBackground,
    
    // Secondary colors
    secondary: AppColors.secondaryGreen,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: Color(0xFF388E3C), // Darker green for containers
    onSecondaryContainer: AppColors.onBackground,
    
    // Tertiary colors
    tertiary: AppColors.accentOrange,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: Color(0xFFF57C00), // Darker orange for containers
    onTertiaryContainer: AppColors.onBackground,
    
    // Error colors
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFFD32F2F), // Darker red for containers
    onErrorContainer: AppColors.onBackground,
    
    // Surface colors
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceVariant: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurface,
    
    // Outline colors
    outline: AppColors.outline,
    outlineVariant: AppColors.divider,
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.onSurface,
    onInverseSurface: AppColors.surface,
    inversePrimary: Color(0xFF90CAF9), // Light blue for inverse
    surfaceTint: AppColors.primaryBlue,
  );
}

/// Extension for state overlays and hover effects
extension ColorSchemeExtension on ColorScheme {
  /// Primary color with 8% opacity overlay for pressed states
  Color get primaryPressed => primary.withOpacity(0.08);
  
  /// Primary color with 12% opacity overlay for hover states
  Color get primaryHover => primary.withOpacity(0.12);
  
  /// Secondary color with 8% opacity overlay for pressed states
  Color get secondaryPressed => secondary.withOpacity(0.08);
  
  /// Secondary color with 12% opacity overlay for hover states
  Color get secondaryHover => secondary.withOpacity(0.12);
  
  /// Tertiary color with 8% opacity overlay for pressed states
  Color get tertiaryPressed => tertiary.withOpacity(0.08);
  
  /// Tertiary color with 12% opacity overlay for hover states
  Color get tertiaryHover => tertiary.withOpacity(0.12);
  
  /// Surface color with slight elevation tint
  Color get surfaceElevated => Color.alphaBlend(
    surfaceTint.withOpacity(0.05),
    surface,
  );
}
