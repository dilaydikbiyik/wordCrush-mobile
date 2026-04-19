import 'package:flutter/material.dart';
import '../../data/models/letter_model.dart';

class GridBoard extends StatelessWidget {
  final List<LetterModel> grid;
  final int size;

  const GridBoard({super.key, required this.grid, required this.size});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: grid.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
      ),
      itemBuilder: (context, index) {
        final letter = grid[index];
        return Center(child: Text(letter.char));
      },
    );
  }
}
