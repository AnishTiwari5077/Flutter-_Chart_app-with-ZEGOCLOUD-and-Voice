import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary brand colors
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4285F4);

  // Accent colors
  static const Color accentColor = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF64FFDA);

  // Success, Warning, Error colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color infoColor = Color(0xFF2196F3);

  // Neutral colors - Light
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Neutral colors - Dark
  static const Color surfaceDark = Color(0xFF121212);
  static const Color backgroundDark = Color(0xFF0A0A0A);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text colors - Light
  static const Color textPrimaryLight = Color(0xFF202124);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textTertiaryLight = Color(0xFF80868B);

  // Text colors - Dark
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);
  static const Color textTertiaryDark = Color(0xFF5F6368);

  // Border colors
  static const Color borderLight = Color(0xFFDADCE0);
  static const Color borderDark = Color(0xFF3C4043);

  // Shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.3);

  // Online status colors
  static const Color onlineGreen = Color(0xFF4CAF50);
  static const Color awayYellow = Color(0xFFFFB300);
  static const Color offlineGray = Color(0xFF9E9E9E);

  // -----------------------------------------
  // LIGHT THEME
  // -----------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color scheme
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryLight.withOpacity(0.2),
      onPrimaryContainer: primaryDark,

      secondary: accentColor,
      onSecondary: Colors.white,
      secondaryContainer: accentLight.withOpacity(0.2),
      onSecondaryContainer: accentColor,

      surface: surfaceLight,
      onSurface: textPrimaryLight,

      background: backgroundLight,
      onBackground: textPrimaryLight,

      error: errorColor,
      onError: Colors.white,

      outline: borderLight,
      outlineVariant: borderLight.withOpacity(0.5),

      shadow: shadowLight,

      surfaceVariant: cardLight,
      onSurfaceVariant: textSecondaryLight,
    ),

    scaffoldBackgroundColor: backgroundLight,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        fontFamily: 'SF Pro Display',
      ),
      iconTheme: const IconThemeData(color: textPrimaryLight, size: 24),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderLight, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        disabledForegroundColor: Colors.white.withOpacity(0.38),
        disabledBackgroundColor: primaryColor.withOpacity(0.12),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    // Icon button theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSecondaryLight,
        highlightColor: primaryColor.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),

      labelStyle: const TextStyle(
        color: textSecondaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'SF Pro Text',
      ),
      hintStyle: TextStyle(
        color: textSecondaryLight.withOpacity(0.6),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: 'SF Pro Text',
      ),
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),

      prefixIconColor: textSecondaryLight,
      suffixIconColor: textSecondaryLight,
    ),

    // Text theme
    textTheme: const TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textPrimaryLight,
        letterSpacing: -0.5,
        height: 1.2,
        fontFamily: 'SF Pro Display',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimaryLight,
        letterSpacing: -0.3,
        height: 1.2,
        fontFamily: 'SF Pro Display',
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0,
        height: 1.3,
        fontFamily: 'SF Pro Display',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.15,
        height: 1.3,
        fontFamily: 'SF Pro Display',
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.15,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.15,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.1,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
        letterSpacing: 0.5,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryLight,
        letterSpacing: 0.25,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        letterSpacing: 0.4,
        height: 1.4,
        fontFamily: 'SF Pro Text',
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.1,
        height: 1.4,
        fontFamily: 'SF Pro Text',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        letterSpacing: 0.5,
        height: 1.3,
        fontFamily: 'SF Pro Text',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryLight,
        letterSpacing: 0.5,
        height: 1.3,
        fontFamily: 'SF Pro Text',
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(color: borderLight, thickness: 1, space: 1),

    // Icon theme
    iconTheme: const IconThemeData(color: textSecondaryLight, size: 24),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      deleteIconColor: textSecondaryLight,
      disabledColor: Colors.grey.shade200,
      selectedColor: primaryColor.withOpacity(0.2),
      secondarySelectedColor: accentColor.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: textPrimaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: textPrimaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: cardLight,
      elevation: 8,
      shadowColor: shadowLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryLight,
        fontFamily: 'SF Pro Display',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondaryLight,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardLight,
      elevation: 8,
      shadowColor: shadowLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimaryLight,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'SF Pro Text',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Colors.transparent,
      circularTrackColor: Colors.transparent,
    ),
  );

  // -----------------------------------------
  // DARK THEME
  // -----------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryDark.withOpacity(0.3),
      onPrimaryContainer: primaryLight,

      secondary: accentLight,
      onSecondary: Colors.black,
      secondaryContainer: accentColor.withOpacity(0.3),
      onSecondaryContainer: accentLight,

      surface: surfaceDark,
      onSurface: textPrimaryDark,

      background: backgroundDark,
      onBackground: textPrimaryDark,

      error: const Color(0xFFEF5350),
      onError: Colors.white,

      outline: borderDark,
      outlineVariant: borderDark.withOpacity(0.5),

      shadow: shadowDark,

      surfaceVariant: cardDark,
      onSurfaceVariant: textSecondaryDark,
    ),

    scaffoldBackgroundColor: backgroundDark,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: cardDark,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        fontFamily: 'SF Pro Display',
      ),
      iconTheme: const IconThemeData(color: textPrimaryDark, size: 24),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderDark, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryLight,
        disabledForegroundColor: Colors.white.withOpacity(0.38),
        disabledBackgroundColor: primaryLight.withOpacity(0.12),
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'SF Pro Display',
        ),
      ),
    ),

    // Icon button theme
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSecondaryDark,
        highlightColor: primaryLight.withOpacity(0.1),
        padding: const EdgeInsets.all(8),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
      ),

      labelStyle: const TextStyle(
        color: textSecondaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'SF Pro Text',
      ),
      hintStyle: TextStyle(
        color: textSecondaryDark.withOpacity(0.6),
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: 'SF Pro Text',
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFEF5350),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),

      prefixIconColor: textSecondaryDark,
      suffixIconColor: textSecondaryDark,
    ),

    // Text theme
    textTheme: const TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textPrimaryDark,
        letterSpacing: -0.5,
        height: 1.2,
        fontFamily: 'SF Pro Display',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimaryDark,
        letterSpacing: -0.3,
        height: 1.2,
        fontFamily: 'SF Pro Display',
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0,
        height: 1.3,
        fontFamily: 'SF Pro Display',
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.15,
        height: 1.3,
        fontFamily: 'SF Pro Display',
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.15,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.15,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.1,
        height: 1.4,
        fontFamily: 'SF Pro Display',
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
        letterSpacing: 0.5,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
        letterSpacing: 0.25,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondaryDark,
        letterSpacing: 0.4,
        height: 1.4,
        fontFamily: 'SF Pro Text',
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.1,
        height: 1.4,
        fontFamily: 'SF Pro Text',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        letterSpacing: 0.5,
        height: 1.3,
        fontFamily: 'SF Pro Text',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryDark,
        letterSpacing: 0.5,
        height: 1.3,
        fontFamily: 'SF Pro Text',
      ),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: borderDark,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: const IconThemeData(color: textSecondaryDark, size: 24),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade900,
      deleteIconColor: textSecondaryDark,
      disabledColor: Colors.grey.shade800,
      selectedColor: primaryLight.withOpacity(0.2),
      secondarySelectedColor: accentLight.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: cardDark,
      elevation: 8,
      shadowColor: shadowDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryDark,
        fontFamily: 'SF Pro Display',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textSecondaryDark,
        height: 1.5,
        fontFamily: 'SF Pro Text',
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardDark,
      elevation: 8,
      shadowColor: shadowDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF323232),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'SF Pro Text',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),

    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: Colors.transparent,
      circularTrackColor: Colors.transparent,
    ),
  );
}
