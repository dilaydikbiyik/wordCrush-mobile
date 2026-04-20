/// Turkish-aware case conversion.
///
/// Standard Dart [toUpperCase] maps 'i' → 'I', but in Turkish 'i' → 'İ'
/// and 'ı' → 'I'. This class handles those edge cases correctly.
/// Do NOT use this to strip Turkish characters to ASCII — Trie stores them as-is.
class CharNormalizer {
  static const Map<String, String> _toUpperMap = {
    'i': 'İ',
    'ı': 'I',
  };

  static const Map<String, String> _toLowerMap = {
    'İ': 'i',
    'I': 'ı',
  };

  /// Converts a string to Turkish uppercase (preserves Ğ, Ö, Ü, Ş, Ç, İ, I).
  static String toTurkishUpper(String input) {
    return input.split('').map((char) {
      return _toUpperMap[char] ?? char.toUpperCase();
    }).join();
  }

  /// Converts a string to Turkish lowercase (preserves ğ, ö, ü, ş, ç, i, ı).
  static String toTurkishLower(String input) {
    return input.split('').map((char) {
      return _toLowerMap[char] ?? char.toLowerCase();
    }).join();
  }
}
