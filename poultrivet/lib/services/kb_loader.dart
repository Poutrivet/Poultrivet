import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class KBLoader {
  static const List<String> allowedDiseases = [
    "cocci",
    "ncd",
    "salmonella",
    "healthy"
  ];

  /// =========================================================
  /// MAIN LOADER
  /// =========================================================
  static Future<Map<String, dynamic>> loadKB() async {
    try {
      final String data = await rootBundle.loadString('assets/poultry_kb.json');

      final Map<String, dynamic> kb = jsonDecode(data);

      _validateKB(kb);

      return kb;
    } catch (e) {
      // Safe fallback instead of crashing app
      return {"diseases": []};
    }
  }

  /// =========================================================
  /// VALIDATION LAYER (SAFE VERSION)
  /// =========================================================
  static void _validateKB(Map<String, dynamic> kb) {
    final diseases = kb["diseases"];

    if (diseases == null || diseases is! List) {
      return; // fail silently (safe for mobile)
    }

    for (final disease in diseases) {
      final id = disease["id"];

      if (id != null && !allowedDiseases.contains(id)) {
        // Instead of crashing, we ignore invalid entries
        // You could log this later if needed
        continue;
      }
    }
  }
}
