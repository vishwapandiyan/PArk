import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_scheme.dart';
import 'typography.dart';

/// Complete dark theme implementation for the parking app
/// Following Material Design 3 with custom component themes
class AppThemeDark {
  static ThemeData create() {
    final colorScheme = createDarkColorScheme();
    final textTheme = AppTypography.createTextTheme(colorScheme);
    
    return ThemeData.from(
      colorScheme: colorScheme,
      textTheme: textTheme,
      useMaterial3: true,
    ).copyWith(
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.disabledText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        showUnselectedLabels: false,
        showSelectedLabels: true,
      ),
      
      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: AppColors.disabledText, size: 24);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AppColors.disabledText,
          );
        }),
        height: 80,
        elevation: 8,
      ),
      
      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.onPrimary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: colorScheme.outline, width: 1),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.primary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return colorScheme.primary.withOpacity(0.12);
            }
            if (states.contains(MaterialState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceVariant,
          foregroundColor: colorScheme.onSurface,
          elevation: 2,
          shadowColor: colorScheme.shadow.withOpacity(0.15),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: colorScheme.surfaceVariant,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.disabledText),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.disabledText,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: AppColors.disabledText.withOpacity(0.12),
        deleteIconColor: colorScheme.onSurfaceVariant,
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 1,
        pressElevation: 2,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalBackgroundColor: colorScheme.surface,
        modalElevation: 16,
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceVariant;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.12),
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.disabledText,
        ),
        leadingAndTrailingTextStyle: textTheme.labelMedium,
        dense: false,
        horizontalTitleGap: 16,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 24,
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outline,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outline,
        circularTrackColor: colorScheme.outline,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: AppColors.disabledText,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
        overlayColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) {
            return colorScheme.primary.withOpacity(0.12);
          }
          return null;
        }),
      ),
      
      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
      ),
      
      // Expansion Tile Theme
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: colorScheme.onSurface,
        collapsedIconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
        collapsedTextColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Scaffold Background Color
      scaffoldBackgroundColor: colorScheme.background,
      
      // Canvas Color
      canvasColor: colorScheme.surface,
      
      // Disabled Color
      disabledColor: AppColors.disabledText,
      
      // Highlight Color
      highlightColor: colorScheme.primary.withOpacity(0.12),
      
      // Splash Color
      splashColor: colorScheme.primary.withOpacity(0.12),
      
      // Focus Color
      focusColor: colorScheme.primary.withOpacity(0.12),
      
      // Hover Color
      hoverColor: colorScheme.primary.withOpacity(0.08),
    );
  }
}
