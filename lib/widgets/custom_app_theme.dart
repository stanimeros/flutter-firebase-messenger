import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppTheme {
  // Logo-inspired colors (based on purple-blue-cyan gradient)
  static const Color primaryCyan = Color(0xFF00D9FF); // Bright cyan glow
  static const Color primaryBlue = Color(0xFF3B82F6); // Vibrant blue
  static const Color primaryPurple = Color(0xFF7C3AED); // Deep purple
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212); // Neutral dark
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Color(0xFFE0E0E0);
  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkError = Color(0xFFEF4444);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryCyan,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
      ),
    );
  }
}
