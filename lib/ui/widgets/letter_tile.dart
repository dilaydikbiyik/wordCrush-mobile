import 'package:flutter/material.dart';
import '../../data/models/letter_model.dart';

class LetterTile extends StatelessWidget {
  final LetterModel letter;

  const LetterTile({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: letter.isSelected ? Colors.indigo.shade200 : Colors.white,
      child: Center(
        child: Text(
          letter.char,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
