import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0B5D8C);
  static const Color secondaryColor = Color(0xFF00897B);
  static const Color correctColor = Colors.green;
  static const Color incorrectColor = Colors.red;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}