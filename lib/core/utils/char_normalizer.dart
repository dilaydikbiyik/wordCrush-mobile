class CharNormalizer {
  static final Map<String, String> _normalizeMap = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
  };

  static String normalize(String input) {
    return input
        .split('')
        .map((char) => _normalizeMap[char] ?? char)
        .join()
        .toLowerCase();
  }
}
