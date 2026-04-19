import '../../data/models/letter_model.dart';

class GridGenerator {
  List<LetterModel> generateGrid(int size, List<String> letters) {
    final grid = <LetterModel>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        grid.add(LetterModel(
          x: x,
          y: y,
          char: letters[(x + y) % letters.length],
        ));
      }
    }
    return grid;
  }
}
