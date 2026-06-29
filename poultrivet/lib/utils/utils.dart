class Utils {
  static const Set<String> protectedWords = {
    "cocci",
    "ncd",
    "salmonella",
    "healthy"
  };

  static String getClosestWord(String word, List<String> vocabulary,
      {double cutoff = 0.7}) {
    // 🚨 NEVER modify disease keywords
    if (protectedWords.contains(word.toLowerCase())) {
      return word;
    }

    String bestMatch = word;
    double highestScore = 0.0;

    for (String vocabWord in vocabulary) {
      double score =
          _getSimilarity(word.toLowerCase(), vocabWord.toLowerCase());
      if (score > highestScore && score >= cutoff) {
        highestScore = score;
        bestMatch = vocabWord;
      }
    }

    return bestMatch;
  }

  static String normalizeText(String text, List<String> vocabulary) {
    List<String> words = text.toLowerCase().split(RegExp(r'\s+'));

    List<String> corrected =
        words.map((w) => getClosestWord(w, vocabulary)).toList();

    return corrected.join(" ");
  }

  // Helper: Simple Jaccard Similarity to replace Python's difflib
  static double _getSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;

    var set1 = s1.split('').toSet();
    var set2 = s2.split('').toSet();
    var intersection = set1.intersection(set2);
    var union = set1.union(set2);

    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }
}
