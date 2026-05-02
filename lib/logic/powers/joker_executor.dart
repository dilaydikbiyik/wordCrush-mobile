import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import '../../data/models/joker_inventory.dart';
import '../algorithms/gravity_engine.dart';
import '../algorithms/grid_generator.dart';

/// Executes joker abilities on the grid and returns the modified grid.
///
/// Each joker type has a specific effect:
/// - Fish: removes 3 random non-empty cells
/// - Wheel: clears the entire row + column of the target cell
/// - Lollipop: removes a single target cell
/// - Swap: swaps letters of two adjacent cells
/// - Shuffle: randomly rearranges all letters on the grid
/// - Party: clears every cell and refills the entire grid
class JokerExecutor {
  final GravityEngine _gravityEngine;
  final GridGenerator _generator;
  final Random _random;

  JokerExecutor({
    GravityEngine? gravityEngine,
    GridGenerator? generator,
    Random? random,
  })  : _gravityEngine = gravityEngine ?? GravityEngine(),
        _generator = generator ?? GridGenerator(),
        _random = random ?? Random();

  /// Executes the given [jokerType] on [grid].
  ///
  /// Some jokers require a [targetCell] (Lollipop, Wheel) or
  /// [secondCell] (Swap). Returns the updated grid after the effect.
  /// Pre-picks the cells that fish joker will remove, for preview purposes.
  static List<Cell> pickFishCells(GridModel grid, {Random? random}) {
    final rng = random ?? Random();
    final nonEmpty = grid.allCells.where((c) => !c.isEmpty).toList()..shuffle(rng);
    return nonEmpty.take(min(AppConstants.fishDeleteCount, nonEmpty.length)).toList();
  }

  GridModel execute({
    required String jokerType,
    required GridModel grid,
    Cell? targetCell,
    Cell? secondCell,
    List<Cell>? preselectedCells,
  }) {
    return switch (jokerType) {
      JokerType.fish => _executeFish(grid, preselectedCells: preselectedCells),
      JokerType.wheel => _executeWheel(grid, targetCell!),
      JokerType.lollipop => _executeLollipop(grid, targetCell!),
      JokerType.swap => _executeSwap(grid, targetCell!, secondCell!),
      JokerType.shuffle => _executeShuffle(grid),
      JokerType.party => _executeParty(grid),
      _ => grid,
    };
  }

  /// Returns true if the joker requires the player to tap a cell first.
  static bool requiresTarget(String jokerType) {
    return jokerType == JokerType.lollipop ||
        jokerType == JokerType.wheel ||
        jokerType == JokerType.swap;
  }

  /// Returns true if the joker requires two cell selections (swap).
  static bool requiresTwoTargets(String jokerType) {
    return jokerType == JokerType.swap;
  }

  // ---------------------------------------------------------------------------
  // Fish — Remove 3 random cells
  // ---------------------------------------------------------------------------

  GridModel _executeFish(GridModel grid, {List<Cell>? preselectedCells}) {
    final toRemove = (preselectedCells != null && preselectedCells.isNotEmpty)
        ? preselectedCells
        : () {
            final nonEmpty = grid.allCells.where((c) => !c.isEmpty).toList()
              ..shuffle(_random);
            return nonEmpty.take(min(AppConstants.fishDeleteCount, nonEmpty.length)).toList();
          }();
    if (toRemove.isEmpty) return grid;
    return _gravityEngine.removeAndRefill(grid, toRemove);
  }

  // ---------------------------------------------------------------------------
  // Wheel — Clear target's row + column
  // ---------------------------------------------------------------------------

  GridModel _executeWheel(GridModel grid, Cell target) {
    final toRemove = <Cell>[];
    final size = grid.size;

    // Entire row
    for (int col = 0; col < size; col++) {
      final cell = grid.getCell(target.row, col);
      if (!cell.isEmpty) toRemove.add(cell);
    }

    // Entire column (skip intersection to avoid duplicate)
    for (int row = 0; row < size; row++) {
      if (row == target.row) continue;
      final cell = grid.getCell(row, target.col);
      if (!cell.isEmpty) toRemove.add(cell);
    }

    return _gravityEngine.removeAndRefill(grid, toRemove);
  }

  // ---------------------------------------------------------------------------
  // Lollipop — Remove single cell
  // ---------------------------------------------------------------------------

  GridModel _executeLollipop(GridModel grid, Cell target) {
    if (target.isEmpty) return grid;
    return _gravityEngine.removeAndRefill(grid, [target]);
  }

  // ---------------------------------------------------------------------------
  // Swap — Swap letters of two adjacent cells
  // ---------------------------------------------------------------------------

  GridModel _executeSwap(GridModel grid, Cell first, Cell second) {
    if (first.isEmpty || second.isEmpty) return grid;
    if (!first.isAdjacentTo(second)) return grid;

    final swapped1 = first.copyWith(letter: second.letter);
    final swapped2 = second.copyWith(letter: first.letter);
    return grid.setCells([swapped1, swapped2]);
  }

  // ---------------------------------------------------------------------------
  // Shuffle — Rearrange all letters randomly
  // ---------------------------------------------------------------------------

  GridModel _executeShuffle(GridModel grid) {
    final allLetters = grid.allCells
        .where((c) => !c.isEmpty)
        .map((c) => c.letter)
        .toList()
      ..shuffle(_random);

    int idx = 0;
    final size = grid.size;
    final newCells = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) {
          final original = grid.getCell(row, col);
          if (original.isEmpty) return original;
          return Cell(row: row, col: col, letter: allLetters[idx++]);
        },
      ),
    );

    return GridModel(size: size, cells: newCells);
  }

  // ---------------------------------------------------------------------------
  // Party — Clear everything and refill
  // ---------------------------------------------------------------------------

  GridModel _executeParty(GridModel grid) {
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
