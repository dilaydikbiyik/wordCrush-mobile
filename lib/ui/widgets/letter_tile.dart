import 'package:flutter/material.dart';
import '../../data/models/letter_model.dart';

class LetterTile extends StatelessWidget {
  final LetterModel letter;

  const LetterTile({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter.char,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
