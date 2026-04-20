import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import '../algorithms/gravity_engine.dart';
import '../algorithms/grid_generator.dart';

/// Immutable state for the game grid and cell selection.
class GridState {
  /// The current grid model.
  final GridModel grid;

  /// Cells currently selected by the player (in order of selection).
  final List<Cell> selectedCells;

  /// The word formed by the current selection.
  final String currentWord;

  /// Number of valid words that can be formed on the current grid.
  final int formableWordCount;

  const GridState({
    required this.grid,
    this.selectedCells = const [],
    this.currentWord = '',
    this.formableWordCount = 0,
  });

  GridState copyWith({
    GridModel? grid,
    List<Cell>? selectedCells,
    String? currentWord,
    int? formableWordCount,
  }) {
    return GridState(
      grid: grid ?? this.grid,
      selectedCells: selectedCells ?? this.selectedCells,
      currentWord: currentWord ?? this.currentWord,
      formableWordCount: formableWordCount ?? this.formableWordCount,
    );
  }
}

/// Manages the grid matrix, cell selection, and gravity-based refill.
///
/// Selection rules:
/// - Each new cell must be 8-directionally adjacent to the last selected cell
/// - A cell cannot be selected twice in the same word
/// - Selection can be undone by swiping back to the previous cell
class GridNotifier extends StateNotifier<GridState> {
  final GridGenerator _generator;
  final GravityEngine _gravityEngine;

  GridNotifier({
    GridGenerator? generator,
    GravityEngine? gravityEngine,
  })  : _generator = generator ?? GridGenerator(),
        _gravityEngine = gravityEngine ?? GravityEngine(),
        super(GridState(grid: GridModel.empty(10)));

  /// Creates a new grid of [size]×[size] with random frequency-weighted letters.
  void initializeGrid(int size) {
    final grid = _generator.generateGrid(size);
    state = GridState(grid: grid);
  }

  /// Attempts to select the cell at [row], [col].
  ///
  /// Returns true if the cell was successfully selected, false otherwise.
  bool selectCell(int row, int col) {
    final cell = state.grid.getCell(row, col);

    // Don't select empty cells
    if (cell.isEmpty) return false;

    // Check if this is the "undo" gesture — tapping the second-to-last cell
    if (state.selectedCells.length >= 2 &&
        state.selectedCells[state.selectedCells.length - 2] == cell) {
      _undoLastSelection();
      return true;
    }

    // Don't select already-selected cells
    if (state.selectedCells.contains(cell)) return false;

    // First cell — always allowed
    if (state.selectedCells.isEmpty) {
      _addToSelection(cell);
      return true;
    }

    // Subsequent cells — must be adjacent to the last selected cell
    final lastSelected = state.selectedCells.last;
    if (!lastSelected.isAdjacentTo(cell)) return false;

    _addToSelection(cell);
    return true;
  }

  void _addToSelection(Cell cell) {
    final updatedCell = cell.copyWith(isSelected: true);
    final newSelected = [...state.selectedCells, updatedCell];
    final word = newSelected.map((c) => c.letter).join();

    state = state.copyWith(
      grid: state.grid.setCell(updatedCell),
      selectedCells: newSelected,
      currentWord: word,
    );
  }

  void _undoLastSelection() {
    if (state.selectedCells.isEmpty) return;

    final lastCell = state.selectedCells.last;
    final restoredCell = lastCell.copyWith(isSelected: false);
    final newSelected = state.selectedCells.sublist(
      0,
      state.selectedCells.length - 1,
    );
    final word = newSelected.map((c) => c.letter).join();

    state = state.copyWith(
      grid: state.grid.setCell(restoredCell),
      selectedCells: newSelected,
      currentWord: word,
    );
  }

  /// Clears all cell selections without removing letters.
  void clearSelection() {
    if (state.selectedCells.isEmpty) return;

    var grid = state.grid;
    for (final cell in state.selectedCells) {
      grid = grid.setCell(cell.copyWith(isSelected: false));
    }

    state = state.copyWith(
      grid: grid,
      selectedCells: [],
      currentWord: '',
    );
  }

  /// Removes the given [cells] from the grid, applies gravity, fills blanks.
  void removeAndRefill(List<Cell> cells) {
    final newGrid = _gravityEngine.removeAndRefill(state.grid, cells);
    state = state.copyWith(
      grid: newGrid,
      selectedCells: [],
      currentWord: '',
    );
  }

  /// Shuffles all letters on the grid randomly.
  void shuffleGrid() {
    final allLetters = state.grid.allCells.map((c) => c.letter).toList()
      ..shuffle();
    int idx = 0;
    final newCells = List.generate(
      state.grid.size,
      (row) => List.generate(
        state.grid.size,
        (col) => Cell(row: row, col: col, letter: allLetters[idx++]),
      ),
    );
    final newGrid = GridModel(size: state.grid.size, cells: newCells);
    state = state.copyWith(
      grid: newGrid,
      selectedCells: [],
      currentWord: '',
    );
  }

  /// Updates the count of formable words (set after background grid scan).
  void updateFormableWordCount(int count) {
    state = state.copyWith(formableWordCount: count);
  }

  /// Replaces the entire grid (used by [GridSolver.ensureSolvable]).
  void setGrid(GridModel grid) {
    state = state.copyWith(
      grid: grid,
      selectedCells: [],
      currentWord: '',
    );
  }
}

/// Provider for the grid state.
final gridProvider = StateNotifierProvider<GridNotifier, GridState>((ref) {
  return GridNotifier();
});
