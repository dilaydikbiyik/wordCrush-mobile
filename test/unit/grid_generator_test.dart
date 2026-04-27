import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/core/constants/letter_frequencies.dart';
import 'package:word_crush_mobile/logic/algorithms/grid_generator.dart';

void main() {
  group('GridGenerator', () {
    // ─── Grid size correctness ────────────────────────────────────────────────

    test('generateGrid(6) produces a 6×6 grid with 36 cells', () {
      final gen = GridGenerator();
      final grid = gen.generateGrid(6);
      expect(grid.size, 6);
      expect(grid.allCells.length, 36);
    });

    test('generateGrid(8) produces an 8×8 grid with 64 cells', () {
      final gen = GridGenerator();
      final grid = gen.generateGrid(8);
      expect(grid.size, 8);
      expect(grid.allCells.length, 64);
    });

    test('generateGrid(10) produces a 10×10 grid with 100 cells', () {
      final gen = GridGenerator();
      final grid = gen.generateGrid(10);
      expect(grid.size, 10);
      expect(grid.allCells.length, 100);
    });

    // ─── No empty cells ───────────────────────────────────────────────────────

    test('generateGrid — all cells have non-empty letters', () {
      final gen = GridGenerator();
      final grid = gen.generateGrid(8);
      for (final cell in grid.allCells) {
        expect(cell.letter, isNotEmpty, reason: 'Cell at (${cell.row},${cell.col}) is empty');
      }
    });

    // ─── Row/col coordinates ──────────────────────────────────────────────────

    test('generateGrid — cell coordinates match their position', () {
      final gen = GridGenerator();
      final grid = gen.generateGrid(6);
      for (int row = 0; row < 6; row++) {
        for (int col = 0; col < 6; col++) {
          final cell = grid.getCell(row, col);
          expect(cell.row, row);
          expect(cell.col, col);
        }
      }
    });

    // ─── Letter validity ─────────────────────────────────────────────────────

    test('generateGrid — all letters are valid Turkish letters', () {
      final validLetters = {
        ...LetterFrequencies.high,
        ...LetterFrequencies.medium,
        ...LetterFrequencies.normal,
        ...LetterFrequencies.low,
      };
      final gen = GridGenerator();
      final grid = gen.generateGrid(10);
      for (final cell in grid.allCells) {
        expect(
          validLetters.contains(cell.letter),
          isTrue,
          reason: '"${cell.letter}" is not a valid Turkish letter',
        );
      }
    });

    // ─── Frequency distribution (statistical) ────────────────────────────────

    test('frequency distribution — high-tier letters appear more often than low-tier', () {
      // Use a fixed seed for reproducibility
      final gen = GridGenerator(random: Random(42));
      final grid = gen.generateGrid(10); // 100 letters

      final counts = <String, int>{};
      for (final cell in grid.allCells) {
        counts[cell.letter] = (counts[cell.letter] ?? 0) + 1;
      }

      // Sum counts by tier
      int highCount = LetterFrequencies.high.fold(0, (s, l) => s + (counts[l] ?? 0));
      int lowCount  = LetterFrequencies.low.fold(0, (s, l) => s + (counts[l] ?? 0));

      // High tier has 6 letters × 6 weight = 36 slots
      // Low tier has 4 letters × 1 weight  = 4 slots  (out of 103 total)
      // Over 100 cells, high >> low is expected
      expect(
        highCount,
        greaterThan(lowCount),
        reason: 'High-frequency letters ($highCount) should appear more than low-frequency ($lowCount)',
      );
    });

    // ─── generateLetter ─────────────────────────────────────────────────────

    test('generateLetter — returns a non-empty valid Turkish letter', () {
      final validLetters = {
        ...LetterFrequencies.high,
        ...LetterFrequencies.medium,
        ...LetterFrequencies.normal,
        ...LetterFrequencies.low,
      };
      final gen = GridGenerator();
      for (int i = 0; i < 50; i++) {
        final letter = gen.generateLetter();
        expect(letter, isNotEmpty);
        expect(validLetters.contains(letter), isTrue);
      }
    });

    // ─── Determinism with fixed seed ─────────────────────────────────────────

    test('generateGrid — same seed produces identical grids', () {
      final gen1 = GridGenerator(random: Random(99));
      final gen2 = GridGenerator(random: Random(99));
      final grid1 = gen1.generateGrid(6);
      final grid2 = gen2.generateGrid(6);

      final letters1 = grid1.allCells.map((c) => c.letter).join();
      final letters2 = grid2.allCells.map((c) => c.letter).join();
      expect(letters1, equals(letters2));
    });
  });
}
