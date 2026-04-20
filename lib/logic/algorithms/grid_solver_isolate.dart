import 'package:flutter/foundation.dart';

import '../../data/models/grid_model.dart';
import '../../data/services/trie_service.dart';
import 'grid_solver.dart';

/// Input message for the background grid-scan isolate.
///
/// All fields are plain Dart primitives so they can be sent across isolates
/// via [compute] without serialization issues.
class GridSolveMessage {
  final List<String> wordList;
  final List<List<String>> letters;

  GridSolveMessage({required this.wordList, required this.letters});
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

// Top-level function required by compute() — must not be a closure or method.
GridSolveResult _solveGridInBackground(GridSolveMessage message) {
  final trie = TrieService();
  for (final word in message.wordList) {
    trie.insert(word);
  }

  final grid = GridModel.fromLetters(message.letters);
  final solver = GridSolver(trie);
  final count = solver.countFormableWords(grid);

  List<List<String>>? fixedLetters;
  if (count == 0) {
    fixedLetters = solver.ensureSolvable(grid).toLetterGrid();
  }

  return GridSolveResult(wordCount: count, fixedLetters: fixedLetters);
}

/// Runs the grid solvability scan in a background isolate.
///
/// Passes [trie.wordList] and the grid letters to the isolate so the isolate
/// can rebuild all data structures from scratch without sharing memory.
Future<GridSolveResult> scanGridAsync(GridModel grid, TrieService trie) {
  return compute(
    _solveGridInBackground,
    GridSolveMessage(
      wordList: trie.wordList,
      letters: grid.toLetterGrid(),
    ),
  );
}
