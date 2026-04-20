import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import 'grid_generator.dart';

/// Handles the "gravity" effect after letters are removed from the grid.
///
/// Three-step process:
/// 1. Mark removed cells as empty
/// 2. Drop remaining cells downward within each column
/// 3. Fill remaining empty cells with new frequency-weighted letters
class GravityEngine {
  final GridGenerator _generator;

  GravityEngine({GridGenerator? generator})
      : _generator = generator ?? GridGenerator();

  /// Removes [cellsToRemove] from [grid], applies gravity, fills blanks.
  ///
  /// Returns a fully populated [GridModel] with no empty cells.
  GridModel removeAndRefill(GridModel grid, List<Cell> cellsToRemove) {
    final size = grid.size;

    // Step 1: Build a mutable 2D array, marking removed cells as null.
    final List<List<Cell?>> columns = List.generate(
      size,
      (col) => List.generate(size, (row) => grid.getCell(row, col)),
    );

    // Mark removed cells
    final removedPositions = <(int, int)>{};
    for (final cell in cellsToRemove) {
      removedPositions.add((cell.row, cell.col));
    }

    for (int col = 0; col < size; col++) {
      for (int row = 0; row < size; row++) {
        if (removedPositions.contains((row, col))) {
          columns[col][row] = null;
        }
      }
    }

    // Step 2: Gravity — push non-null cells to the bottom of each column.
    final newCells = List.generate(
      size,
      (row) => List<Cell>.generate(size, (col) => Cell.empty(row: row, col: col)),
    );

    for (int col = 0; col < size; col++) {
      // Collect non-null cells in this column (top-to-bottom order).
      final remaining = <Cell>[];
      for (int row = 0; row < size; row++) {
        if (columns[col][row] != null) {
          remaining.add(columns[col][row]!);
        }
      }

      // Place them at the bottom of the column.
      final emptyCount = size - remaining.length;
      for (int i = 0; i < remaining.length; i++) {
        final newRow = emptyCount + i;
        newCells[newRow][col] = remaining[i].copyWith(row: newRow, col: col);
      }

      // Step 3: Fill the empty top slots with new letters.
      for (int row = 0; row < emptyCount; row++) {
        newCells[row][col] = Cell(
          row: row,
          col: col,
          letter: _generator.generateLetter(),
        );
      }
    }

    return GridModel(size: size, cells: newCells);
  }
}
