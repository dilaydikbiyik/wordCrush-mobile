import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/grid_generator.dart';
import '../../data/models/letter_model.dart';
import '../../core/constants/app_constants.dart';

class GameState {
  final List<LetterModel> grid;
  final int movesLeft;
  final int score;

  GameState({
    required this.grid,
    required this.movesLeft,
    required this.score,
  });

  GameState copyWith({
    List<LetterModel>? grid,
    int? movesLeft,
    int? score,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      movesLeft: movesLeft ?? this.movesLeft,
      score: score ?? this.score,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier()
      : super(GameState(
          grid: GridGenerator().generateGrid(
            AppConstants.easyGridSize,
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
          ),
          movesLeft: AppConstants.easyMaxMoves,
          score: 0,
        ));

  void reset() {
    state = GameState(
      grid: GridGenerator().generateGrid(
        AppConstants.easyGridSize,
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ),
      movesLeft: AppConstants.easyMaxMoves,
      score: 0,
    );
  }

  void decrementMove() {
    if (state.movesLeft > 0) {
      state = state.copyWith(movesLeft: state.movesLeft - 1);
    }
  }

  void addScore(int value) {
    state = state.copyWith(score: state.score + value);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});
