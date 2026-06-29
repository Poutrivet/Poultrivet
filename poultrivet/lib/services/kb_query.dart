class KBQuery {
  /// =========================
  /// CORE LOOKUP (SAFE)
  /// =========================
  static Map<String, dynamic>? getDisease(
    Map<String, dynamic> kb,
    String diseaseId,
  ) {
    final List<dynamic>? diseases = kb["diseases"];

    if (diseases == null) return null;

    for (final d in diseases) {
      if (d["id"] == diseaseId) {
        return Map<String, dynamic>.from(d);
      }
    }

    return null;
  }

  /// =========================
  /// GENERIC FIELD ACCESS
  /// =========================
  static dynamic getField(
    Map<String, dynamic> kb,
    String diseaseId,
    String field,
  ) {
    final disease = getDisease(kb, diseaseId);

    if (disease == null) return null;

    return disease[field];
  }

  /// =========================
  /// DOMAIN-SPECIFIC HELPERS
  /// =========================
  static dynamic getTreatment(
    Map<String, dynamic> kb,
    String diseaseId,
  ) {
    return getField(kb, diseaseId, "treatment");
  }

  static dynamic getPrevention(
    Map<String, dynamic> kb,
    String diseaseId,
  ) {
    return getField(kb, diseaseId, "prevention");
  }

  static dynamic getSymptoms(
    Map<String, dynamic> kb,
    String diseaseId,
  ) {
    return getField(kb, diseaseId, "symptoms");
  }

  static dynamic getFaq(
    Map<String, dynamic> kb,
    String diseaseId,
  ) {
    return getField(kb, diseaseId, "faq");
  }
}
