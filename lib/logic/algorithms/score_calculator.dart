import '../../data/models/letter_model.dart';

class ScoreCalculator {
  int calculateScore(List<LetterModel> letters, int comboMultiplier) {
    final base = letters.length * 10;
    final bonus = comboMultiplier * 5;
    return base + bonus;
  }
}
