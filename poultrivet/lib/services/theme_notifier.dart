import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _fontSizeKey = 'font_size';

  bool _isDark = false;
  double _fontSize = 16.0;

  bool get isDark => _isDark;
  double get fontSize => _fontSize;

  ThemeMode get themeMode =>
      _isDark ? ThemeMode.dark : ThemeMode.light;

  // ── Load saved preferences on startup ─────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark    = prefs.getBool(_darkModeKey) ?? false;
    _fontSize  = prefs.getDouble(_fontSizeKey) ?? 16.0;
    notifyListeners();
  }

  // ── Toggle dark mode ───────────────────────────────────────────────────────
  Future<void> setDarkMode(bool value) async {
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  // ── Update font size ───────────────────────────────────────────────────────
  Future<void> setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  // ── Light theme ────────────────────────────────────────────────────────────
  static ThemeData lightTheme(double fontSize) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF19e16c),
        scaffoldBackgroundColor: const Color(0xFFf6f8f7),
        textTheme: _textTheme(fontSize, Brightness.light),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFf6f8f7),
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        cardColor: Colors.white,
      );

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static ThemeData darkTheme(double fontSize) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF19e16c),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: _textTheme(fontSize, Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e1e1e),
          elevation: 1,
        ),
        cardColor: const Color(0xFF1e1e1e),
      );

  static TextTheme _textTheme(double base, Brightness brightness) {
    final color = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
    return TextTheme(
      bodyLarge:   TextStyle(fontSize: base,       color: color),
      bodyMedium:  TextStyle(fontSize: base - 1,   color: color),
      bodySmall:   TextStyle(fontSize: base - 3,   color: color),
      titleLarge:  TextStyle(fontSize: base + 6,   color: color, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(fontSize: base + 2,   color: color, fontWeight: FontWeight.w600),
      labelSmall:  TextStyle(fontSize: base - 4,   color: color),
    );
  }
}
