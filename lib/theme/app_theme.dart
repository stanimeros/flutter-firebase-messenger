import 'package:flutter/material.dart';

class AppTheme {
  // Firebase-inspired colors
  static const Color firebaseOrange = Color(0xFFFF6F00); // Firebase orange
  static const Color firebaseBlue = Color(0xFF4285F4); // Google blue
  static const Color firebaseYellow = Color(0xFFFFCA28); // Firebase yellow
  static const Color firebaseGreen = Color(0xFF34A853); // Google green
  static const Color firebaseRed = Color(0xFFEA4335); // Google red
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2C2C2C);
  static const Color darkSurfaceVariant = Color(0xFF3A3A3A);
  static const Color darkOnBackground = Color(0xFFE0E0E0);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkOnError = Color(0xFF000000);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: firebaseOrange,
        onPrimary: darkOnPrimary,
        secondary: firebaseBlue,
        onSecondary: darkOnSecondary,
        tertiary: firebaseYellow,
        error: darkError,
        onError: darkOnError,
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurface.withValues(alpha: 0.7),
        outline: darkOnSurface.withValues(alpha: 0.3),
        outlineVariant: darkOnSurface.withValues(alpha: 0.1),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: darkOnSurface,
        onInverseSurface: darkBackground,
        inversePrimary: firebaseBlue,
        surfaceTint: firebaseOrange,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkOnSurface),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkOnSurface.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkOnSurface.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: firebaseOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkError, width: 2),
        ),
        labelStyle: TextStyle(color: darkOnSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: darkOnSurface.withValues(alpha: 0.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: firebaseOrange,
          foregroundColor: darkOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurface,
          side: BorderSide(color: darkOnSurface.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: firebaseOrange,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: firebaseOrange,
        foregroundColor: darkOnPrimary,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: firebaseOrange,
        unselectedItemColor: darkOnSurface.withValues(alpha: 0.6),
        selectedIconTheme: const IconThemeData(color: firebaseOrange),
        unselectedIconTheme: IconThemeData(color: darkOnSurface.withValues(alpha: 0.6)),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: darkOnSurface.withValues(alpha: 0.9),
          fontSize: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: darkOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: darkOnSurface.withValues(alpha: 0.2),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        textColor: darkOnSurface,
        iconColor: darkOnSurface.withValues(alpha: 0.7),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        labelStyle: TextStyle(color: darkOnSurface),
        selectedColor: firebaseOrange.withValues(alpha: 0.2),
        checkmarkColor: firebaseOrange,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return firebaseOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(darkOnPrimary),
        side: BorderSide(color: darkOnSurface.withValues(alpha: 0.5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return firebaseOrange;
          }
          return darkOnSurface.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return firebaseOrange.withValues(alpha: 0.5);
          }
          return darkSurfaceVariant;
        }),
      ),
    );
  }
}
