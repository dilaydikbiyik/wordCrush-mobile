/// 3-tier Turkish letter frequency system for grid generation.
/// Letters are NOT generated with equal probability — this table is mandatory.
class LetterFrequencies {
  /// Tier 1 — high frequency (appears 6× in pool)
  static const List<String> high = ['A', 'E', 'İ', 'L', 'R', 'N'];

  /// Tier 2 — medium frequency (appears 3× in pool)
  static const List<String> medium = ['K', 'D', 'M', 'U', 'T', 'S', 'Y', 'B', 'O'];

  /// Tier 3 — normal frequency (appears 2× in pool)
  static const List<String> normal = ['C', 'Ç', 'G', 'H', 'I', 'Ö', 'P', 'Ş', 'Ü', 'Z'];

  /// Tier 4 — low frequency (appears 1× in pool)
  static const List<String> low = ['J', 'Ğ', 'F', 'V'];

  /// Weighted pool used by GridGenerator for random letter selection.
  static List<String> get weightedPool => [
        for (int i = 0; i < 6; i++) ...high,
        for (int i = 0; i < 3; i++) ...medium,
        for (int i = 0; i < 2; i++) ...normal,
        ...low,
      ];
}
