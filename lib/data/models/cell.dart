/// Represents a single cell in the game grid.
///
/// Each cell holds its position ([row], [col]), the [letter] it displays,
/// selection state, and an optional [powerType] for special-power tiles.
class Cell {
  final int row;
  final int col;
  final String letter;
  final bool isSelected;
  final bool isEmpty;
  final String? powerType;

  const Cell({
    required this.row,
    required this.col,
    required this.letter,
    this.isSelected = false,
    this.isEmpty = false,
    this.powerType,
  });

  /// Creates an empty cell (letter cleared after word match).
  const Cell.empty({
    required this.row,
    required this.col,
  })  : letter = '',
        isSelected = false,
        isEmpty = true,
        powerType = null;

  Cell copyWith({
    int? row,
    int? col,
    String? letter,
    bool? isSelected,
    bool? isEmpty,
    String? powerType,
  }) {
    return Cell(
      row: row ?? this.row,
      col: col ?? this.col,
      letter: letter ?? this.letter,
      isSelected: isSelected ?? this.isSelected,
      isEmpty: isEmpty ?? this.isEmpty,
      powerType: powerType ?? this.powerType,
    );
  }

  /// Returns true if [other] is one of the 8 directional neighbors.
  bool isAdjacentTo(Cell other) {
    final dRow = (row - other.row).abs();
    final dCol = (col - other.col).abs();
    if (dRow == 0 && dCol == 0) return false;
    return dRow <= 1 && dCol <= 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Cell($row, $col, "$letter")';
}
