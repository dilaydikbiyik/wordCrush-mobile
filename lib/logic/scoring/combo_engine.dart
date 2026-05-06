import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/services/trie_service.dart';

/// Finds combo sub-words within a main word using substring matching.
///
/// A "combo" is a valid dictionary word of 3+ consecutive letters
/// that appear as a contiguous slice of the main word.
///
/// Example: "MASAL" → {MASAL, MASA, ASAL, SAL, ALA}
class ComboEngine {
  final TrieService _trie;

  ComboEngine(this._trie);

  /// Returns all valid sub-words found inside [mainWord], including [mainWord]
  /// itself. Only contiguous substrings of length >= 3 are considered.
  /// Duplicates are filtered.
  List<String> findComboWords(String mainWord) {
    final normalized = CharNormalizer.toTurkishUpper(mainWord);
    final results = <String>{};

    for (int start = 0; start < normalized.length; start++) {
      for (int end = start + AppConstants.minWordLength; end <= normalized.length; end++) {
        final sub = normalized.substring(start, end);
        if (_trie.contains(sub)) {
          results.add(sub);
        }
      }
    }

    return results.toList();
  }

  /// Returns the combo count (number of valid sub-words including the main word).
  int comboCount(String mainWord) => findComboWords(mainWord).length;
}
