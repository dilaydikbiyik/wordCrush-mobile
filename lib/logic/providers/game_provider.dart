import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';
import '../../data/models/letter_model.dart';
import '../../data/models/settings_model.dart';
import '../../data/services/isar_service.dart';
import '../../data/services/trie_service.dart';
import '../algorithms/combo_finder.dart';
import '../algorithms/gravity_engine.dart';
import '../algorithms/grid_generator.dart';
import '../algorithms/score_calculator.dart';

class GameState {
  final List<LetterModel> grid;
  final int score;
  final int remainingMoves;
  final int level;
  final bool isGameOver;
  final bool soundEnabled;
  final String statusMessage;

  GameState({
    required this.grid,
    required this.score,
    required this.remainingMoves,
    required this.level,
    required this.isGameOver,
    required this.soundEnabled,
    required this.statusMessage,
  });

  GameState.initial()
      : grid = [],
        score = 0,
        remainingMoves = AppConstants.defaultMoves,
        level = 1,
        isGameOver = false,
        soundEnabled = true,
        statusMessage = 'Başlamak için oynayın';

  GameState copyWith({
    List<LetterModel>? grid,
    int? score,
    int? remainingMoves,
    int? level,
    bool? isGameOver,
    bool? soundEnabled,
    String? statusMessage,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      score: score ?? this.score,
      remainingMoves: remainingMoves ?? this.remainingMoves,
      level: level ?? this.level,
      isGameOver: isGameOver ?? this.isGameOver,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final IsarService isarService;
  final TrieService trieService;
  final GridGenerator _gridGenerator = GridGenerator();
  final GravityEngine _gravityEngine = GravityEngine();
  final ScoreCalculator _scoreCalculator = ScoreCalculator();
  final ComboFinder _comboFinder = ComboFinder();

  GameNotifier({required this.isarService, required this.trieService})
      : super(GameState.initial());

  Future<void> initSettings() async {
    final settings = await isarService.loadSettings();
    if (settings != null) {
      state = state.copyWith(
        soundEnabled: settings.soundEnabled,
        level: settings.currentLevel,
      );
    }
  }

  void startGame(int level) {
    final size = switch (level) {
      1 => AppConstants.easyGridSize,
      2 => AppConstants.mediumGridSize,
      3 => AppConstants.hardGridSize,
      _ => AppConstants.mediumGridSize,
    };
    state = state.copyWith(
      grid: _gridGenerator.generate(size),
      score: 0,
      remainingMoves: AppConstants.defaultMoves,
      level: level,
      isGameOver: false,
      statusMessage: 'Oyun başladı',
    );
  }

  bool validateWord(String word) {
    final normalized = normalizeTurkishCharacters(word).toLowerCase();
    return trieService.contains(normalized);
  }

  void submitWord(String word) {
    if (state.isGameOver) return;

    final normalized = normalizeTurkishCharacters(word).toLowerCase();
    if (!validateWord(normalized) || normalized.length < 2) {
      state = state.copyWith(statusMessage: 'Geçersiz kelime');
      return;
    }

    final gainedScore = _scoreCalculator.calculate(normalized, 1);
    state = state.copyWith(
      score: state.score + gainedScore,
      remainingMoves: state.remainingMoves - 1,
      statusMessage: '$gainedScore puan kazandınız',
    );

    if (state.remainingMoves <= 0) {
      finishGame();
    }
  }

  void resolveMove() {
    final size = switch (state.level) {
      1 => AppConstants.easyGridSize,
      2 => AppConstants.mediumGridSize,
      3 => AppConstants.hardGridSize,
      _ => AppConstants.mediumGridSize,
    };
    final newGrid = _gravityEngine.applyGravity(state.grid, size);
    state = state.copyWith(grid: newGrid);
  }

  void finishGame() {
    state = state.copyWith(isGameOver: true, statusMessage: 'Oyun bitti');
  }

  Future<void> saveProgress() async {
    final settings = SettingsModel()
      ..soundEnabled = state.soundEnabled
      ..currentLevel = state.level;
    await isarService.saveSettings(settings);
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final isarService = IsarService();
  final trieService = TrieService();
  return GameNotifier(isarService: isarService, trieService: trieService);
});
