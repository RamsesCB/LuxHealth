import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color primaryGreen = Color(0xFF66BB6A);
  static const Color backgroundWhite = Colors.white;
  static const Color softGreen = Color(0xFFE8F5E9);

  // Configuración global del tema
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      primaryColor: primaryGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        surface: backgroundWhite,
      ),
      fontFamily: 'Sans-Serif',
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2.0,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        ),
      ),
    );
  }
}
