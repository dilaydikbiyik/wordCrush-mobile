import 'package:flutter/material.dart';
import '../../data/models/cell.dart';

/// Renders a single grid cell.
///
/// TODO (Phase 6): Add power-up icons, selection animations, score overlay.
class LetterTile extends StatelessWidget {
  final Cell cell;

  const LetterTile({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cell.isSelected ? Colors.indigo.shade200 : Colors.white,
      child: Center(
        child: Text(
          cell.letter,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
