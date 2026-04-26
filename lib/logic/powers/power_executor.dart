import '../../data/models/cell.dart';
import '../../data/models/grid_model.dart';
import 'power_type.dart';

class PowerExecutor {
  /// Determines what kind of power should be spawned based on word length.
  static PowerType determinePowerForWordLength(int length) {
    if (length >= 7) return PowerType.megaBlast;
    if (length == 6) return PowerType.columnClear;
    if (length == 5) return PowerType.areaBlast;
    if (length == 4) return PowerType.rowClear;
    return PowerType.none;
  }

  /// Calculates the full set of cells that should be destroyed due to chain reactions.
  Set<Cell> calculateBlastRadius(GridModel grid, Set<Cell> initialCells) {
    final Set<Cell> destroyed = {};
    final List<Cell> queue = initialCells.toList();

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (destroyed.contains(current)) continue;

      destroyed.add(current);

      switch (current.powerType) {
        case PowerType.rowClear:
          for (int c = 0; c < grid.size; c++) {
            final target = grid.getCell(current.row, c);
            if (!destroyed.contains(target) && !queue.contains(target)) {
              queue.add(target);
            }
          }
          break;

        case PowerType.columnClear:
          for (int r = 0; r < grid.size; r++) {
            final target = grid.getCell(r, current.col);
            if (!destroyed.contains(target) && !queue.contains(target)) {
              queue.add(target);
            }
          }
          break;

        case PowerType.areaBlast:
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              final r = current.row + dr;
              final c = current.col + dc;
              if (r >= 0 && r < grid.size && c >= 0 && c < grid.size) {
                final target = grid.getCell(r, c);
                if (!destroyed.contains(target) && !queue.contains(target)) {
                  queue.add(target);
                }
              }
            }
          }
          break;

        case PowerType.megaBlast:
          for (int dr = -2; dr <= 2; dr++) {
            for (int dc = -2; dc <= 2; dc++) {
              final r = current.row + dr;
              final c = current.col + dc;
              if (r >= 0 && r < grid.size && c >= 0 && c < grid.size) {
                final target = grid.getCell(r, c);
                if (!destroyed.contains(target) && !queue.contains(target)) {
                  queue.add(target);
                }
              }
            }
          }
          break;

        case PowerType.none:
        default:
          break;
      }
    }

    return destroyed;
  }
}
