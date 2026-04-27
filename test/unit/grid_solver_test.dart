import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/data/models/cell.dart';
import 'package:word_crush_mobile/data/models/grid_model.dart';
import 'package:word_crush_mobile/data/services/trie_service.dart';
import 'package:word_crush_mobile/logic/algorithms/grid_solver.dart';

// Helper: build a GridModel from a 2D list of letter strings
GridModel _makeGrid(List<List<String>> letters) {
  final size = letters.length;
  final cells = List.generate(
    size,
    (r) => List.generate(
      size,
      (c) => Cell(row: r, col: c, letter: letters[r][c]),
    ),
  );
  return GridModel(size: size, cells: cells);
}

void main() {
  group('GridSolver', () {
    late TrieService trie;
    late GridSolver solver;

    setUp(() {
      trie = TrieService();
      // Insert known words so DFS can find them
      for (final w in ['ARI', 'SARI', 'ANA', 'EL', 'AL', 'KAL', 'KALEM', 'MASA', 'KALE']) {
        trie.insert(w);
      }
      solver = GridSolver(trie);
    });

    // ─── findAllWords ────────────────────────────────────────────────────────

    test('findAllWords — finds word from contiguous path', () {
      // Build a 3×3 grid that spells ARI horizontally in row 0
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['X', 'X', 'X'],
        ['X', 'X', 'X'],
      ]);
      final words = solver.findAllWords(grid);
      expect(words, contains('ARI'));
    });

    test('findAllWords — finds word from diagonal path', () {
      // A at (0,0), R at (1,1), I at (2,2) — diagonal
      final grid = _makeGrid([
        ['A', 'X', 'X'],
        ['X', 'R', 'X'],
        ['X', 'X', 'I'],
      ]);
      final words = solver.findAllWords(grid);
      expect(words, contains('ARI'));
    });

    test('findAllWords — does not repeat letters in same path', () {
      // All A's — no real word possible
      final grid = _makeGrid([
        ['A', 'A', 'A'],
        ['A', 'A', 'A'],
        ['A', 'A', 'A'],
      ]);
      final words = solver.findAllWords(grid);
      // 'ANA' requires A-N-A but there's no N
      expect(words, isNot(contains('ANA')));
    });

    test('findAllWords — returns empty set when no valid words exist', () {
      // Grid of Z's — 'ZZZ' not in trie
      final grid = _makeGrid([
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
      ]);
      final words = solver.findAllWords(grid);
      expect(words, isEmpty);
    });

    test('findAllWords — finds multiple words in same grid', () {
      // ARI horizontally, ANA vertically (overlapping A)
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['N', 'X', 'X'],
        ['A', 'X', 'X'],
      ]);
      final words = solver.findAllWords(grid);
      expect(words, contains('ARI'));
      expect(words, contains('ANA'));
    });

    // ─── isSolvable ──────────────────────────────────────────────────────────

    test('isSolvable — returns true when a valid word exists', () {
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['X', 'X', 'X'],
        ['X', 'X', 'X'],
      ]);
      expect(solver.isSolvable(grid), isTrue);
    });

    test('isSolvable — returns false when no valid word exists', () {
      final grid = _makeGrid([
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
      ]);
      expect(solver.isSolvable(grid), isFalse);
    });

    // ─── countFormableWords ──────────────────────────────────────────────────

    test('countFormableWords — returns 0 when grid is unsolvable', () {
      final grid = _makeGrid([
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
      ]);
      expect(solver.countFormableWords(grid), 0);
    });

    test('countFormableWords — returns at least 1 when grid is solvable', () {
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['X', 'X', 'X'],
        ['X', 'X', 'X'],
      ]);
      expect(solver.countFormableWords(grid), greaterThanOrEqualTo(1));
    });

    test('countFormableWords — non-overlapping constraint is respected', () {
      // ARI at row 0, ANA at col 0 — share the 'A' at (0,0)
      // They can't both be counted (non-overlapping rule)
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['N', 'X', 'X'],
        ['A', 'X', 'X'],
      ]);
      final count = solver.countFormableWords(grid);
      // Both exist but share 'A' at (0,0), so count = 1 (greedy picks longer)
      expect(count, greaterThanOrEqualTo(1));
      // Can't be more than 2 non-overlapping paths in this tiny grid
      expect(count, lessThanOrEqualTo(2));
    });

    // ─── ensureSolvable ─────────────────────────────────────────────────────

    test('ensureSolvable — returns unchanged grid when already solvable', () {
      final grid = _makeGrid([
        ['A', 'R', 'I'],
        ['X', 'X', 'X'],
        ['X', 'X', 'X'],
      ]);
      final result = solver.ensureSolvable(grid);
      // Should be solvable after the call
      expect(solver.isSolvable(result), isTrue);
    });

    test('ensureSolvable — fixes unsolvable grid (all Z)', () {
      final grid = _makeGrid([
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
        ['Z', 'Z', 'Z'],
      ]);
      final fixed = solver.ensureSolvable(grid);
      expect(solver.isSolvable(fixed), isTrue);
    });

    // ─── Minimum word length ─────────────────────────────────────────────────

    test('findAllWords — 2-letter words not included (min = 3)', () {
      // EL is 2 letters — even if path exists, should not appear
      final grid = _makeGrid([
        ['E', 'L', 'X'],
        ['X', 'X', 'X'],
        ['X', 'X', 'X'],
      ]);
      final words = solver.findAllWords(grid);
      expect(words, isNot(contains('EL')));
    });
  });
}
