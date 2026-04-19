import '../../data/models/letter_model.dart';

class GravityEngine {
  List<LetterModel> applyGravity(List<LetterModel> grid, int size) {
    final columns = List.generate(size, (_) => <LetterModel>[]);

    for (final letter in grid) {
      columns[letter.x].add(letter);
    }

    for (var x = 0; x < size; x++) {
      final column = columns[x]
        ..sort((a, b) => b.y.compareTo(a.y));
      for (var y = size - 1; y >= 0; y--) {
        final index = size - 1 - y;
        column[index] = column[index].copyWith(y: y);
      }
    }

    return columns.expand((column) => column).toList();
  }
}
