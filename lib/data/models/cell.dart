import 'package:flutter/foundation.dart';
import '../../logic/powers/power_type.dart';

/// Represents a single cell in the game grid.
class Cell {
  static int _idCounter = 0;

  /// Resets the global ID counter. Call this in test [setUp] to keep
  /// cell IDs small and predictable across test cases.
  @visibleForTesting
  static void resetIdCounter() => _idCounter = 0;

  final int id;
  final int row;
  final int col;
  final String letter;
  final bool isSelected;
  final bool isEmpty;
  final PowerType powerType;

  Cell({
    required this.row,
    required this.col,
    required this.letter,
    this.isSelected = false,
    this.isEmpty = false,
    this.powerType = PowerType.none,
    int? id,
  }) : id = id ?? _idCounter++;

  Cell.empty({
    required this.row,
    required this.col,
  })  : id = _idCounter++,
        letter = '',
        isSelected = false,
        isEmpty = true,
        powerType = PowerType.none;

  Cell copyWith({
    int? row,
    int? col,
    String? letter,
    bool? isSelected,
    bool? isEmpty,
    PowerType? powerType,
  }) {
    return Cell(
      id: id, // Explicitly pass current id to preserve it
      row: row ?? this.row,
      col: col ?? this.col,
      letter: letter ?? this.letter,
      isSelected: isSelected ?? this.isSelected,
      isEmpty: isEmpty ?? this.isEmpty,
      powerType: powerType ?? this.powerType,
    );
  }

  bool isAdjacentTo(Cell other) {
    final rowDiff = (row - other.row).abs();
    final colDiff = (col - other.col).abs();
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          row == other.row &&
          col == other.col &&
          letter == other.letter &&
          isSelected == other.isSelected &&
          isEmpty == other.isEmpty &&
          powerType == other.powerType;

  @override
  int get hashCode => Object.hash(id, row, col, letter, isSelected, isEmpty, powerType);
}
