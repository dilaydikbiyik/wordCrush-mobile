import '../../core/constants/letter_scores.dart';

/// Calculates word scores based on the Turkish letter point table.
///
/// Each letter has a Scrabble-style point value defined in [LetterScores].
/// Combo words contribute their own letter scores to the total.
class ScoreCalculator {
  /// Returns the sum of individual letter scores for [word].
  ///
  /// [word] must be in Turkish uppercase (matching [LetterScores.scores] keys).
  /// Unknown characters score 0 (e.g. power-up tiles).
  int calculateWordScore(String word) {
    int score = 0;
    for (final char in word.split('')) {
      score += LetterScores.getScore(char);
    }
    return score;
  }

  /// Calculates the total score: main word + all combo sub-words.
  ///
  /// [mainWord] is the word the player formed.
  /// [comboWords] is the list of valid sub-words found inside [mainWord]
  /// (excluding the main word itself — it's added automatically).
  int calculateTotalScore(String mainWord, List<String> comboWords) {
    int total = calculateWordScore(mainWord);
    for (final word in comboWords) {
      total += calculateWordScore(word);
    }
    return total;
  }
}
