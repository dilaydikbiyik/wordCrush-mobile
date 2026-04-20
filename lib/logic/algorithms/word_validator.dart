import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import '../../data/services/trie_service.dart';

/// Validates words formed by the player on the grid.
///
/// Checks three conditions:
/// 1. Minimum word length ([AppConstants.minWordLength], currently 3)
/// 2. All consecutive cells in the path are 8-directionally adjacent
/// 3. The word exists in the Turkish dictionary ([TrieService])
class WordValidator {
  final TrieService _trie;

  WordValidator(this._trie);

  /// Full validation: length + adjacency + dictionary lookup.
  ///
  /// [path] is the ordered list of cells the player swiped through.
  /// [grid] is used for adjacency verification.
  bool isValidWord(List<Cell> path, GridModel grid) {
    // 1. Minimum length check
    if (path.length < AppConstants.minWordLength) return false;

    // 2. Adjacency check — every consecutive pair must be neighbors
    if (!grid.isValidPath(path)) return false;

    // 3. Dictionary check — Trie stores words in Turkish uppercase
    final word = grid.getWord(path);
    final normalized = CharNormalizer.toTurkishUpper(word);
    return _trie.contains(normalized);
  }

  /// Quick dictionary-only lookup (no path/adjacency check).
  ///
  /// Useful for combo sub-word verification where adjacency is irrelevant.
  bool isInDictionary(String word) {
    if (word.length < AppConstants.minWordLength) return false;
    final normalized = CharNormalizer.toTurkishUpper(word);
    return _trie.contains(normalized);
  }
}
