import 'package:flutter/material.dart';

/// Zentrales Theme der App (Material 3).
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF0E7C86);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
