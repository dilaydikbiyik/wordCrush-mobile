import 'dart:math';

import '../../core/constants/letter_frequencies.dart';
import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';

/// Generates game grids using the weighted Turkish letter frequency pool.
///
/// Letters are NOT uniformly distributed — [LetterFrequencies.weightedPool]
/// ensures common Turkish letters (A, E, İ, L, R, N) appear far more often
/// than rare ones (J, Ğ, F, V).
class GridGenerator {
  final Random _random;

  /// Injectable [Random] for deterministic testing.
  GridGenerator({Random? random}) : _random = random ?? Random();

  /// Builds a [size]×[size] [GridModel] with frequency-weighted random letters.
  GridModel generateGrid(int size) {
    final pool = LetterFrequencies.weightedPool;
    final cells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => Cell(
          row: row,
          col: col,
          letter: _pickLetter(pool),
        ),
      ),
    );
    return GridModel(size: size, cells: cells);
  }

  /// Generates a single frequency-weighted letter for gravity refill.
  String generateLetter() {
    final pool = LetterFrequencies.weightedPool;
    return _pickLetter(pool);
  }

  String _pickLetter(List<String> pool) {
    return pool[_random.nextInt(pool.length)];
  }
}
