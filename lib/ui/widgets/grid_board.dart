import 'package:flutter/material.dart';
import '../../data/models/letter_model.dart';
import 'letter_tile.dart';

class GridBoard extends StatelessWidget {
  final List<LetterModel> grid;

  const GridBoard({super.key, required this.grid});

  @override
  Widget build(BuildContext context) {
    final size = grid.isEmpty ? 0 : grid.map((e) => e.x).reduce((a, b) => a > b ? a : b) + 1;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.count(
        crossAxisCount: size,
        children: grid.map((letter) => LetterTile(letter: letter)).toList(),
      ),
    );
  }
}
