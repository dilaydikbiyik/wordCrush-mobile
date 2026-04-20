import 'package:flutter/material.dart';
import '../../data/models/grid_model.dart';
import 'letter_tile.dart';

/// Renders the NxN grid of [LetterTile] widgets.
///
/// TODO (Phase 6): Add GestureDetector for 8-directional swipe selection.
class GridBoard extends StatelessWidget {
  final GridModel grid;

  const GridBoard({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.count(
        crossAxisCount: grid.size,
        children: grid.allCells
            .map((cell) => LetterTile(cell: cell))
            .toList(),
      ),
    );
  }
}
