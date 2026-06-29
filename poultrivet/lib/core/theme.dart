import 'package:flutter/material.dart';

class PoulvetTheme {
  static const Color primary = Color.fromARGB(255, 19, 97, 39);
  static const Color primaryDark = Color.fromARGB(255, 18, 103, 39);
  static const Color lightBg = Color(0xFFf6f8f7);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1a1a2e);
  static const Color textGrey = Color(0xFF6b7280);
  static const Color border = Color(0xFFe5e7eb);
  static const Color error = Color(0xFFef4444);

  static InputDecoration inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: PoulvetTheme.primary, size: 20) : null,
      labelStyle: const TextStyle(color: PoulvetTheme.textGrey, fontSize: 14),
      hintStyle: TextStyle(color: PoulvetTheme.textGrey.withOpacity(0.6), fontSize: 14),
      filled: true,
      fillColor: PoulvetTheme.lightBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PoulvetTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PoulvetTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PoulvetTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PoulvetTheme.error),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: PoulvetTheme.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 54),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: PoulvetTheme.primary,
    minimumSize: const Size(double.infinity, 54),
    side: const BorderSide(color: PoulvetTheme.primary, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
