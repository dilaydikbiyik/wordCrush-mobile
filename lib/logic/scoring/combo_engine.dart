import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/services/trie_service.dart';

/// Finds combo sub-words within a main word using subsequence matching.
///
/// A "combo" is a valid dictionary word of 3+ letters whose characters
/// appear in the same order within the main word (subsequence, not substring).
///
/// Example: "ADANA" → {ADANA, DANA, ANA, ADA}
class ComboEngine {
  final TrieService _trie;

  ComboEngine(this._trie);

  /// Returns all valid sub-words found inside [mainWord], including [mainWord]
  /// itself if it is valid.
  ///
  /// [mainWord] must be in Turkish uppercase.
  /// Duplicates are filtered. Minimum sub-word length is 3.
  List<String> findComboWords(String mainWord) {
    final normalized = CharNormalizer.toTurkishUpper(mainWord);
    final results = <String>{};

    // Always include the main word if valid
    if (normalized.length >= AppConstants.minWordLength &&
        _trie.contains(normalized)) {
      results.add(normalized);
    }

    // Find all valid subsequences of length >= 3
    _findSubsequences(normalized, 0, '', results);

    return results.toList();
  }

  /// Recursive subsequence generator with Trie pruning.
  ///
  /// For each position in [word], we either include or skip the character.
  /// We prune branches where the current prefix has no continuation in the Trie.
  void _findSubsequences(
    String word,
    int index,
    String current,
    Set<String> results,
  ) {
    // If current is long enough, check dictionary
    if (current.length >= AppConstants.minWordLength) {
      if (_trie.contains(current)) {
        results.add(current);
      }
    }

    // Prune: stop if no word starts with current prefix
    if (current.isNotEmpty && !_trie.hasPrefix(current)) {
      return;
    }

    // Base case
    if (index >= word.length) return;

    // Branch 1: Include character at index
    _findSubsequences(word, index + 1, current + word[index], results);

    // Branch 2: Skip character at index
    _findSubsequences(word, index + 1, current, results);
  }

  /// Returns the combo count (number of valid sub-words including the main word).
  int comboCount(String mainWord) => findComboWords(mainWord).length;
}
