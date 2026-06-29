import '../utils/utils.dart';

class IntentMapper {
  static const Map<String, List<String>> _keywords = {
    "cocci": [
      "cocci",
      "coccidiosis",
      "bloody",
      "poop",
      "diarrhea",
      "eimeria",
      "bloody stool",
      "blood in stool",
      "intestinal",
      "parasite"
    ],
    "ncd": [
      "ncd",
      "newcastle",
      "twisted",
      "neck",
      "paralysis",
      "green",
      "lasota",
      "hb1",
      "ndv",
      "torticollis",
      "sudden death"
    ],
    "salmonella": [
      "salmonella",
      "samonella",
      "bacteria",
      "bacterial",
      "white diarrhea",
      "oxytetracycline",
      "food poisoning",
      "contaminated egg"
    ],
    "healthy": [
      "healthy",
      "normal",
      "active",
      "good",
      "fine",
      "no disease",
      "not sick"
    ]
  };

  // Flatten the keywords into a single vocabulary list for the spell checker
  static List<String> get _vocabulary {
    return _keywords.values.expand((list) => list).toList();
  }

  static String? mapToDisease(String input) {
    // 1. Use Utils to fix spelling mistakes first
    String normalizedInput = Utils.normalizeText(input, _vocabulary);

    // 2. Check the corrected text against our keywords
    for (var entry in _keywords.entries) {
      for (var kw in entry.value) {
        if (normalizedInput.contains(kw)) {
          return entry.key;
        }
      }
    }
    return null;
  }
}
