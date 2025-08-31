import 'package:flutter/material.dart';
import 'color_scheme.dart';

/// Typography system for the parking app
/// Using clean sans-serif fonts with proper hierarchy and spacing
class AppTypography {
  /// Base font family - using system default (Roboto on Android, SF Pro on iOS)
  static const String fontFamily = 'Roboto';
  
  /// Creates the text theme for the dark theme
  static TextTheme createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles - for large page titles
      displayLarge: TextStyle(
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
        fontFamily: fontFamily,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
        fontFamily: fontFamily,
        letterSpacing: -0.25,
      ),
      
      // Headline styles - for section headers
      headlineLarge: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
        fontFamily: fontFamily,
      ),
      
      // Title styles - for card headers and important labels
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      
      // Body styles - for main content
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.disabledText,
        fontFamily: fontFamily,
      ),
      
      // Label styles - for buttons and form labels
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: AppColors.disabledText,
        fontFamily: fontFamily,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Extension for additional text styles
extension TextThemeExtension on TextTheme {
  /// Button text style - no all caps, proper weight
  TextStyle get button => labelLarge!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  
  /// Caption style for subtle information
  TextStyle get caption => bodySmall!.copyWith(
    color: AppColors.disabledText,
    fontSize: 12,
  );
  
  /// Overline style for category labels
  TextStyle get overline => labelSmall!.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.disabledText,
  );
  
  /// Error text style
  TextStyle get error => bodyMedium!.copyWith(
    color: AppColors.error,
    fontWeight: FontWeight.w500,
  );
  
  /// Success text style
  TextStyle get success => bodyMedium!.copyWith(
    color: AppColors.success,
    fontWeight: FontWeight.w500,
  );
  
  /// Warning text style
  TextStyle get warning => bodyMedium!.copyWith(
    color: AppColors.warning,
    fontWeight: FontWeight.w500,
  );
}
