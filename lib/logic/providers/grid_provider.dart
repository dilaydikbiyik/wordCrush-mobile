import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import '../../data/services/trie_service.dart';
import '../algorithms/gravity_engine.dart';
import '../algorithms/grid_generator.dart';
import '../algorithms/grid_solver_isolate.dart';
import '../powers/power_executor.dart';
import '../powers/power_type.dart';

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

  /// True for one frame after the grid is auto-shuffled due to no valid words.
  final bool wasAutoShuffled;

  const GridState({
    required this.grid,
    this.selectedCells = const [],
    this.currentWord = '',
    this.formableWordCount = 0,
    this.wasAutoShuffled = false,
  });

  GridState copyWith({
    GridModel? grid,
    List<Cell>? selectedCells,
    String? currentWord,
    int? formableWordCount,
    bool? wasAutoShuffled,
  }) {
    return GridState(
      grid: grid ?? this.grid,
      selectedCells: selectedCells ?? this.selectedCells,
      currentWord: currentWord ?? this.currentWord,
      formableWordCount: formableWordCount ?? this.formableWordCount,
      wasAutoShuffled: wasAutoShuffled ?? false, // her copyWith'te resetlenir
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
  /// Also handles special power generation and chain-reaction blasts.
  /// Returns the full list of actually destroyed cells.
  List<Cell> removeAndRefill(List<Cell> cells) {
    if (cells.isEmpty) return [];

    final powerExecutor = PowerExecutor();
    final Set<Cell> toDestroy = {};
    final List<Cell> queue = List.from(cells);

    // 1. Check if the newly formed word generates a power tile
    final newPowerType = PowerExecutor.determinePowerForWordLength(cells.length);
    Cell? powerCell;
    
    if (newPowerType != PowerType.none) {
      final lastCell = cells.last;
      powerCell = lastCell.copyWith(powerType: newPowerType, isSelected: false);

      // Do not destroy the cell that transforms into a power tile
      queue.removeWhere((c) => c.row == lastCell.row && c.col == lastCell.col);

      // If the last cell already had a power effect, inject its targets into the queue
      // so the old power still fires even though the cell is being upgraded.
      if (lastCell.powerType != PowerType.none) {
        final blastTargets = powerExecutor.calculateBlastRadius(state.grid, {lastCell});
        for (final target in blastTargets) {
          if (target.row == lastCell.row && target.col == lastCell.col) continue;
          if (!queue.any((c) => c.row == target.row && c.col == target.col)) {
            queue.add(target);
          }
        }
      }
    }

    // 2. Add existing powers in the selection to the blast radius
    toDestroy.addAll(powerExecutor.calculateBlastRadius(state.grid, queue.toSet()));

    // Ensure empty cells are not sent to gravity engine
    toDestroy.removeWhere((c) => c.isEmpty);

    // 3. Remove all cells in the blast radius
    var currentGrid = state.grid;
    if (powerCell != null) {
      currentGrid = currentGrid.setCell(powerCell);
    }
    
    final newGrid = _gravityEngine.removeAndRefill(currentGrid, toDestroy.toList());
    state = state.copyWith(
      grid: newGrid,
      selectedCells: [],
      currentWord: '',
    );
    
    return toDestroy.toList();
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

  /// Scans the grid in a background isolate via [compute].
  ///
  /// Updates [formableWordCount] and, if no valid word exists, replaces the
  /// grid with a solvable version — all without blocking the UI thread.
  Future<void> scanAsync(TrieService trie, {bool isRetry = false}) async {
    final result = await scanGridAsync(state.grid, trie);

    if (result.fixedLetters != null) {
      state = state.copyWith(
        grid: GridModel.fromLetters(result.fixedLetters!),
        selectedCells: [],
        currentWord: '',
        formableWordCount: result.wordCount,
        wasAutoShuffled: true, // animasyonu tetikle
      );
      if (!isRetry) await scanAsync(trie, isRetry: true);
    } else {
      state = state.copyWith(formableWordCount: result.wordCount);
    }
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
