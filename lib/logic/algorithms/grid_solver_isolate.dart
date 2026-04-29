import 'package:flutter/foundation.dart';

import '../../data/models/grid_model.dart';
import '../../data/services/trie_service.dart';
import 'grid_solver.dart';

/// Input message for the background grid-scan isolate.
///
/// [wordListHash] is a stable proxy (word list length) so the isolate-side
/// Trie cache can skip a rebuild when the dictionary hasn't changed.
class GridSolveMessage {
  final List<String> wordList;
  final List<List<String>> letters;
  final int wordListHash;

  GridSolveMessage({
    required this.wordList,
    required this.letters,
    required this.wordListHash,
  });
}

/// Result returned from the background grid-scan isolate.
class GridSolveResult {
  /// Number of non-overlapping words formable on the grid.
  final int wordCount;

  /// Replacement grid letters if the original grid had no valid words.
  /// Null when the grid was already solvable.
  final List<List<String>>? fixedLetters;

  GridSolveResult({required this.wordCount, this.fixedLetters});
}

// ─── Isolate-side Trie cache ───────────────────────────────────────────────
// Avoids ~60 k Trie inserts on every move. The Trie is rebuilt only when
// the word list hash changes (i.e. never during a single game session).
int? _cachedWordListHash;
TrieService? _cachedTrie;

// Top-level function required by compute() — must not be a closure or method.
GridSolveResult _solveGridInBackground(GridSolveMessage message) {
  // Rebuild only when word list changed (first call or dictionary hot-reload).
  if (_cachedTrie == null || _cachedWordListHash != message.wordListHash) {
    final trie = TrieService();
    for (final word in message.wordList) {
      trie.insert(word);
    }
    _cachedTrie = trie;
    _cachedWordListHash = message.wordListHash;
  }

  final trie = _cachedTrie!;
  final grid = GridModel.fromLetters(message.letters);
  final solver = GridSolver(trie);
  final count = solver.countFormableWords(grid);

  List<List<String>>? fixedLetters;
  int finalCount = count;
  if (count == 0) {
    final fixedGrid = solver.ensureSolvable(grid);
    fixedLetters = fixedGrid.toLetterGrid();
    finalCount = solver.countFormableWords(fixedGrid);
  }

  return GridSolveResult(wordCount: finalCount, fixedLetters: fixedLetters);
}

/// Runs the grid solvability scan in a background isolate.
///
/// Only [grid.toLetterGrid()] is serialized on every call. The word list is
/// sent with a hash so the isolate-side cache can skip the expensive Trie
/// build when the dictionary hasn't changed between moves.
Future<GridSolveResult> scanGridAsync(GridModel grid, TrieService trie) {
  return compute(
    _solveGridInBackground,
    GridSolveMessage(
      wordList: trie.wordList,
      letters: grid.toLetterGrid(),
      wordListHash: trie.wordList.length,
    ),
  );
}

