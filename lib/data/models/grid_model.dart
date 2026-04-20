import 'cell.dart';

/// Immutable 2D grid model of [Cell] objects.
///
/// Provides positional access, neighbor lookups, and path-to-word conversion.
/// All mutation returns a new [GridModel] instance (immutable pattern).
class GridModel {
  /// Grid dimension (6, 8, or 10).
  final int size;

  /// Row-major 2D grid: `_cells[row][col]`.
  final List<List<Cell>> _cells;

  GridModel({
    required this.size,
    required List<List<Cell>> cells,
  }) : _cells = cells;

  /// Creates an empty grid shell (all cells have empty letters).
  factory GridModel.empty(int size) {
    final cells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => Cell.empty(row: row, col: col),
      ),
    );
    return GridModel(size: size, cells: cells);
  }

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// Returns the cell at [row], [col].
  Cell getCell(int row, int col) => _cells[row][col];

  /// Returns a flat list of all cells (row-major order).
  List<Cell> get allCells =>
      _cells.expand((row) => row).toList(growable: false);

  /// Returns an unmodifiable view of the 2D cells.
  List<List<Cell>> get cells =>
      List.unmodifiable(_cells.map((row) => List.unmodifiable(row)));

  // ---------------------------------------------------------------------------
  // Mutation helpers (return new GridModel)
  // ---------------------------------------------------------------------------

  /// Returns a new [GridModel] with [cell] placed at its own (row, col).
  GridModel setCell(Cell cell) {
    final newCells = _deepCopy();
    newCells[cell.row][cell.col] = cell;
    return GridModel(size: size, cells: newCells);
  }

  /// Returns a new [GridModel] with multiple cells updated.
  GridModel setCells(List<Cell> updates) {
    final newCells = _deepCopy();
    for (final cell in updates) {
      newCells[cell.row][cell.col] = cell;
    }
    return GridModel(size: size, cells: newCells);
  }

  // ---------------------------------------------------------------------------
  // Neighbor / adjacency
  // ---------------------------------------------------------------------------

  /// The 8 directional offsets: ↑ ↓ ← → ↗ ↘ ↙ ↖
  static const List<List<int>> directions = [
    [-1, 0], [1, 0], [0, -1], [0, 1], // cardinal
    [-1, 1], [1, 1], [1, -1], [-1, -1], // diagonal
  ];

  /// Returns the (up to 8) neighboring cells of the cell at [row], [col].
  List<Cell> getNeighbors(int row, int col) {
    final neighbors = <Cell>[];
    for (final dir in directions) {
      final nRow = row + dir[0];
      final nCol = col + dir[1];
      if (_inBounds(nRow, nCol)) {
        neighbors.add(_cells[nRow][nCol]);
      }
    }
    return neighbors;
  }

  /// Returns true if two cells are 8-directionally adjacent.
  bool areAdjacent(Cell a, Cell b) => a.isAdjacentTo(b);

  // ---------------------------------------------------------------------------
  // Word helpers
  // ---------------------------------------------------------------------------

  /// Concatenates the letters of [path] into a single uppercase string.
  String getWord(List<Cell> path) =>
      path.map((c) => c.letter).join();

  /// Returns true if every consecutive pair in [path] is adjacent.
  bool isValidPath(List<Cell> path) {
    for (int i = 0; i < path.length - 1; i++) {
      if (!areAdjacent(path[i], path[i + 1])) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  bool _inBounds(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  List<List<Cell>> _deepCopy() =>
      List.generate(size, (r) => List<Cell>.from(_cells[r]));

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final row in _cells) {
      buffer.writeln(row.map((c) => c.letter.padRight(2)).join(' '));
    }
    return buffer.toString();
  }
}
