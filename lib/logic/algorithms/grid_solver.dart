import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import '../../data/services/trie_service.dart';
import 'grid_generator.dart';

/// Scans the grid for all formable words using DFS + Trie prefix pruning.
///
/// Also provides solvability checks and the "guaranteed word" fallback
/// mechanism that ensures the grid is never left without any valid word.
class GridSolver {
  final TrieService _trie;
  final GridGenerator _generator;

  GridSolver(this._trie, {GridGenerator? generator})
      : _generator = generator ?? GridGenerator();

  // ---------------------------------------------------------------------------
  // Word finding — DFS with Trie pruning
  // ---------------------------------------------------------------------------

  /// Finds all unique valid words formable on [grid] via 8-directional paths.
  ///
  /// Uses DFS from every cell, pruning branches where the current prefix
  /// has no continuation in the Trie. This brings worst-case complexity
  /// from O(N² · 8^N) down to manageable levels even on 10×10 grids.
  Set<String> findAllWords(GridModel grid) {
    final wordsWithPaths = findAllWordsWithPaths(grid);
    return wordsWithPaths.keys.toSet();
  }

  /// Finds all valid words along with one representative path for each.
  ///
  /// Returns a map of word → list of cells forming that word's path.
  /// If a word can be formed via multiple paths, only one is stored.
  Map<String, List<Cell>> findAllWordsWithPaths(GridModel grid) {
    final results = <String, List<Cell>>{};
    final size = grid.size;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final visited = List.generate(
          size,
          (_) => List.filled(size, false),
        );
        _dfs(grid, row, col, '', visited, <Cell>[], results);
      }
    }

    return results;
  }

  void _dfs(
    GridModel grid,
    int row,
    int col,
    String prefix,
    List<List<bool>> visited,
    List<Cell> path,
    Map<String, List<Cell>> results,
  ) {
    final cell = grid.getCell(row, col);
    if (cell.isEmpty) return;

    final current = prefix + cell.letter;

    // Prune: no word in dictionary starts with this prefix
    if (!_trie.hasPrefix(CharNormalizer.toTurkishUpper(current))) return;

    visited[row][col] = true;
    path.add(cell);

    // Check if current path forms a valid word
    final upper = CharNormalizer.toTurkishUpper(current);
    if (current.length >= AppConstants.minWordLength && _trie.contains(upper)) {
      // Store the first path found for each word
      results.putIfAbsent(upper, () => List<Cell>.from(path));
    }

    // Explore all 8 neighbors
    for (final neighbor in grid.getNeighbors(row, col)) {
      if (!visited[neighbor.row][neighbor.col] && !neighbor.isEmpty) {
        _dfs(grid, neighbor.row, neighbor.col, current, visited, path,
            results);
      }
    }

    visited[row][col] = false;
    path.removeLast();
  }

  // ---------------------------------------------------------------------------
  // Solvability
  // ---------------------------------------------------------------------------

  /// Returns true if at least one valid word can be formed on [grid].
  bool isSolvable(GridModel grid) {
    final size = grid.size;

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final visited = List.generate(
          size,
          (_) => List.filled(size, false),
        );
        if (_dfsEarlyExit(grid, row, col, '', visited)) return true;
      }
    }

    return false;
  }

  /// DFS that returns true as soon as any valid word is found.
  bool _dfsEarlyExit(
    GridModel grid,
    int row,
    int col,
    String prefix,
    List<List<bool>> visited,
  ) {
    final cell = grid.getCell(row, col);
    if (cell.isEmpty) return false;

    final current = prefix + cell.letter;
    final upper = CharNormalizer.toTurkishUpper(current);

    if (!_trie.hasPrefix(upper)) return false;

    visited[row][col] = true;

    if (current.length >= AppConstants.minWordLength && _trie.contains(upper)) {
      visited[row][col] = false;
      return true;
    }

    for (final neighbor in grid.getNeighbors(row, col)) {
      if (!visited[neighbor.row][neighbor.col] && !neighbor.isEmpty) {
        if (_dfsEarlyExit(
            grid, neighbor.row, neighbor.col, current, visited)) {
          visited[row][col] = false;
          return true;
        }
      }
    }

    visited[row][col] = false;
    return false;
  }

  /// Counts the number of **non-overlapping** formable words on [grid].
  ///
  /// Per PDF requirement: "Kelime sayısı, kelimelerin ortak harf
  /// kullanamayacak şekilde oluşturulmasıyla bulunmaktadır."
  ///
  /// Uses a greedy approach: sort words by length (longest first), then
  /// greedily select words whose cells don't overlap with already-selected ones.
  int countFormableWords(GridModel grid) {
    final wordsWithPaths = findAllWordsWithPaths(grid);
    if (wordsWithPaths.isEmpty) return 0;

    // Sort entries by word length descending (prefer longer words)
    final sorted = wordsWithPaths.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final usedCells = <(int, int)>{};
    int count = 0;

    for (final entry in sorted) {
      final path = entry.value;

      // Check if any cell in this word's path is already used
      final overlaps = path.any((c) => usedCells.contains((c.row, c.col)));
      if (overlaps) continue;

      // Select this word — mark its cells as used
      for (final cell in path) {
        usedCells.add((cell.row, cell.col));
      }
      count++;
    }

    return count;
  }

  // ---------------------------------------------------------------------------
  // Guaranteed solvability — fallback mechanisms
  // ---------------------------------------------------------------------------

  /// Ensures [grid] has at least one valid word.
  ///
  /// If the grid is already solvable, returns it unchanged.
  /// Otherwise, applies the "seeded word" strategy: picks a random dictionary
  /// word and plants its letters along an adjacent path on the grid.
  GridModel ensureSolvable(GridModel grid) {
    if (isSolvable(grid)) return grid;

    // Strategy: plant a random word from the dictionary into the grid
    return _plantWord(grid);
  }

  /// Plants a random dictionary word into [grid] along an adjacent path.
  GridModel _plantWord(GridModel grid) {
    final random = Random();
    final size = grid.size;

    // Collect some candidate words from the Trie (3-5 letters, likely to fit)
    final candidates = _collectCandidateWords(size);
    if (candidates.isEmpty) {
      // Last resort: shuffle the entire grid
      return _shuffleGrid(grid);
    }

    // Shuffle and try each candidate
    candidates.shuffle(random);

    for (final word in candidates) {
      final path = _findPathForWord(grid, word, random);
      if (path != null) {
        var newGrid = grid;
        for (int i = 0; i < word.length; i++) {
          newGrid = newGrid.setCell(
            path[i].copyWith(letter: word[i]),
          );
        }
        return newGrid;
      }
    }

    // If no word could be planted, shuffle
    return _shuffleGrid(grid);
  }

  /// Collects candidate words from the Trie that are short enough to fit.
  List<String> _collectCandidateWords(int gridSize) {
    // Walk the Trie to find words of length 3-5
    final results = <String>[];
    _collectWords(_trie.root, '', results, 5);
    // Limit to manageable number
    if (results.length > 100) {
      results.shuffle(Random());
      return results.sublist(0, 100);
    }
    return results;
  }

  void _collectWords(
    TrieNode node,
    String prefix,
    List<String> results,
    int maxLen,
  ) {
    if (prefix.length >= AppConstants.minWordLength && node.isWord) {
      results.add(prefix);
    }
    if (prefix.length >= maxLen || results.length >= 200) return;

    for (final entry in node.children.entries) {
      _collectWords(entry.value, prefix + entry.key, results, maxLen);
    }
  }

  /// Tries to find an adjacent path on the grid where [word] can be placed.
  List<Cell>? _findPathForWord(GridModel grid, String word, Random random) {
    final size = grid.size;
    // Try random starting positions
    final positions = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        positions.add((r, c));
      }
    }
    positions.shuffle(random);

    for (final (startRow, startCol) in positions) {
      final path = <Cell>[];
      final visited = List.generate(size, (_) => List.filled(size, false));

      if (_buildPath(grid, startRow, startCol, word, 0, path, visited)) {
        return path;
      }
    }
    return null;
  }

  bool _buildPath(
    GridModel grid,
    int row,
    int col,
    String word,
    int index,
    List<Cell> path,
    List<List<bool>> visited,
  ) {
    if (index >= word.length) return true;
    if (row < 0 || row >= grid.size || col < 0 || col >= grid.size) {
      return false;
    }
    if (visited[row][col]) return false;

    visited[row][col] = true;
    path.add(grid.getCell(row, col));

    // Try all 8 neighbors for the next character
    for (final dir in GridModel.directions) {
      final nRow = row + dir[0];
      final nCol = col + dir[1];
      if (_buildPath(grid, nRow, nCol, word, index + 1, path, visited)) {
        return true;
      }
    }

    visited[row][col] = false;
    path.removeLast();
    return false;
  }

  /// Shuffles all letters randomly across the grid, using the frequency-
  /// weighted generator for any replacements needed.
  GridModel _shuffleGrid(GridModel grid) {
    final size = grid.size;
    final newCells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => Cell(row: row, col: col, letter: _generator.generateLetter()),
      ),
    );
    return GridModel(size: size, cells: newCells);
  }
}
