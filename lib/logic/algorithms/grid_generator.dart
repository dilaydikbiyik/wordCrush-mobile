import '../../data/models/letter_model.dart';

class GridGenerator {
  static List<LetterModel> generate(int size) {
    final letters = <LetterModel>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        letters.add(LetterModel(x: x, y: y, char: 'A'));
      }
    }
    return letters;
  }
}
