import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Premium Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5), // Deep Blue start
      primary: const Color(0xFF1565C0), // Rich Blue
      secondary: const Color(0xFF00BFA5), // Teal Accent
      surface: const Color(0xFFF8F9FA), // Very light grey surface
      background: Colors.white,
      error: const Color(0xFFD32F2F),
    ),
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: const Color(0xFF2D3436),
      displayColor: const Color(0xFF2D3436),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      prefixIconColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Flat modern look with border or soft shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF2D3436), // Dark text
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Color(0xFF2D3436),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );

  // Custom Colors - Modern Palette
  static const Color expenseColor = Color(0xFFE53935); // Soft Red
  static const Color cashColor = Color(0xFF43A047); // Soft Green
  static const Color remainingColor = Color(0xFFFFB300); // Amber
}
