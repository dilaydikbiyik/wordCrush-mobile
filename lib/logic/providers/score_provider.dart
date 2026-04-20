import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for scoring.
class ScoreState {
  /// Cumulative score for the current game.
  final int totalScore;

  /// Score earned from the most recent word.
  final int lastWordScore;

  /// Combo sub-words found in the most recent word.
  final List<String> lastComboWords;

  /// Number of combo words for the most recent word.
  final int lastComboCount;

  const ScoreState({
    this.totalScore = 0,
    this.lastWordScore = 0,
    this.lastComboWords = const [],
    this.lastComboCount = 0,
  });

  ScoreState copyWith({
    int? totalScore,
    int? lastWordScore,
    List<String>? lastComboWords,
    int? lastComboCount,
  }) {
    return ScoreState(
      totalScore: totalScore ?? this.totalScore,
      lastWordScore: lastWordScore ?? this.lastWordScore,
      lastComboWords: lastComboWords ?? this.lastComboWords,
      lastComboCount: lastComboCount ?? this.lastComboCount,
    );
  }
}

/// Manages the score state for the current game session.
///
/// This notifier does NOT calculate scores itself — it receives pre-calculated
/// values from the game controller which uses [ScoreCalculator] and [ComboEngine].
class ScoreNotifier extends StateNotifier<ScoreState> {
  ScoreNotifier() : super(const ScoreState());

  /// Adds a word's score to the running total.
  ///
  /// [wordScore] is the total (main word + combo words) from [ScoreCalculator].
  /// [comboWords] is the list of sub-words found by [ComboEngine].
  void addWordScore(int wordScore, List<String> comboWords) {
    state = state.copyWith(
      totalScore: state.totalScore + wordScore,
      lastWordScore: wordScore,
      lastComboWords: comboWords,
      lastComboCount: comboWords.length,
    );
  }

  /// Resets all scoring state for a new game.
  void reset() {
    state = const ScoreState();
  }
}

/// Provider for the score state.
final scoreProvider = StateNotifierProvider<ScoreNotifier, ScoreState>((ref) {
  return ScoreNotifier();
});
