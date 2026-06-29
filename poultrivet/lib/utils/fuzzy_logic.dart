class FuzzyMatcher {
  // Simple Jaccard Similarity for offline intent matching
  static double getSimilarity(String s1, String s2) {
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();
    if (s1 == s2) return 1.0;

    var set1 = s1.split('').toSet();
    var set2 = s2.split('').toSet();
    var intersection = set1.intersection(set2);
    var union = set1.union(set2);

    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }
}
