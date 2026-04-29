import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/game_record.dart';
import '../../data/services/objectbox_service.dart';

/// Immutable state for the overall game session.
class GameState {
  /// Remaining moves in the current game.
  final int movesLeft;

  /// Maximum moves for this difficulty level.
  final int maxMoves;

  /// Grid dimension (6, 8, or 10).
  final int gridSize;

  /// Difficulty label for display purposes.
  final String difficulty;

  /// Whether a game is currently in progress.
  final bool isGameActive;

  /// Whether the game has ended (moves exhausted or player quit).
  final bool isGameOver;

  /// Number of valid words found in this session.
  final int wordCount;

  /// The longest word found in this session.
  final String longestWord;

  /// When the current game started.
  final DateTime? startTime;

  /// Sequential game number across all sessions.
  final int gameNumber;

  const GameState({
    this.movesLeft = 0,
    this.maxMoves = 0,
    this.gridSize = 10,
    this.difficulty = 'Kolay',
    this.isGameActive = false,
    this.isGameOver = false,
    this.wordCount = 0,
    this.longestWord = '',
    this.startTime,
    this.gameNumber = 0,
  });

  GameState copyWith({
    int? movesLeft,
    int? maxMoves,
    int? gridSize,
    String? difficulty,
    bool? isGameActive,
    bool? isGameOver,
    int? wordCount,
    String? longestWord,
    DateTime? startTime,
    int? gameNumber,
  }) {
    return GameState(
      movesLeft: movesLeft ?? this.movesLeft,
      maxMoves: maxMoves ?? this.maxMoves,
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
      isGameActive: isGameActive ?? this.isGameActive,
      isGameOver: isGameOver ?? this.isGameOver,
      wordCount: wordCount ?? this.wordCount,
      longestWord: longestWord ?? this.longestWord,
      startTime: startTime ?? this.startTime,
      gameNumber: gameNumber ?? this.gameNumber,
    );
  }
}

/// Manages the high-level game session lifecycle.
///
/// Tracks moves, word count, longest word, and handles game-over logic
/// including saving the completed game to ObjectBox.
class GameNotifier extends StateNotifier<GameState> {
  final ObjectBoxService _db;

  GameNotifier(this._db) : super(const GameState());

  /// Starts a new game with the given [gridSize] and [maxMoves].
  ///
  /// Automatically calculates the next game number from stored records.
  void startNewGame(int gridSize, int maxMoves) {
    final records = _db.getAllGameRecords();
    final nextNumber = records.isEmpty ? 1 : records.length + 1;

    final difficulty = switch (gridSize) {
      AppConstants.hardGridSize => 'Zor',
      AppConstants.mediumGridSize => 'Orta',
      _ => 'Kolay',
    };

    state = GameState(
      movesLeft: maxMoves,
      maxMoves: maxMoves,
      gridSize: gridSize,
      difficulty: difficulty,
      isGameActive: true,
      isGameOver: false,
      wordCount: 0,
      longestWord: '',
      startTime: DateTime.now(),
      gameNumber: nextNumber,
    );
  }

  /// Decrements the remaining move count by one.
  ///
  /// If moves reach zero, the game ends automatically.
  void decrementMove() {
    if (state.movesLeft <= 0) return;

    final newMoves = state.movesLeft - 1;
    state = state.copyWith(
      movesLeft: newMoves,
      isGameOver: newMoves <= 0,
      isGameActive: newMoves > 0,
    );
  }

  /// Records a successfully found word, updating count and longest.
  void recordWord(String word) {
    state = state.copyWith(
      wordCount: state.wordCount + 1,
      longestWord:
          word.length > state.longestWord.length ? word : state.longestWord,
    );
  }

  /// Ends the current game and saves the result to ObjectBox.
  ///
  /// [finalScore] is the total accumulated score from [ScoreProvider].
  void endGame(int finalScore) {
    final duration = state.startTime != null
        ? DateTime.now().difference(state.startTime!).inSeconds
        : 0;

    final record = GameRecord(
      gameNumber: state.gameNumber,
      gridSize: state.gridSize,
      score: finalScore,
      wordCount: state.wordCount,
      longestWord: state.longestWord,
      durationSeconds: duration,
    );

    _db.saveGameRecord(record);

    state = state.copyWith(
      isGameActive: false,
      isGameOver: true,
    );
  }
}

/// Provider for the overall game session state.
///
/// Requires [objectBoxServiceProvider] to be overridden with an initialized
/// instance at app startup (see SplashScreen).
final objectBoxServiceProvider = Provider<ObjectBoxService>((ref) {
  throw UnimplementedError(
    'objectBoxServiceProvider must be overridden after ObjectBox initialization',
  );
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final db = ref.watch(objectBoxServiceProvider);
  return GameNotifier(db);
});

/// Reactive provider for all game records.
///
/// Re-reads from ObjectBox whenever [gameProvider] state changes (e.g. after endGame).
final gameRecordsProvider = Provider<List<GameRecord>>((ref) {
  ref.watch(gameProvider);
  final db = ref.read(objectBoxServiceProvider);
  return db.getAllGameRecords();
});
