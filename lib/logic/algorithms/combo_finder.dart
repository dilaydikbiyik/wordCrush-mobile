import '../../data/models/letter_model.dart';

class ComboFinder {
  List<List<LetterModel>> findCombos(List<LetterModel> selectedLetters) {
    if (selectedLetters.isEmpty) return [];
    return [selectedLetters];
  }
}
