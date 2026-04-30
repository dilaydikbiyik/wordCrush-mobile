import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/core/constants/app_constants.dart';
import 'package:word_crush_mobile/data/models/game_record.dart';
import 'package:word_crush_mobile/data/models/joker_inventory.dart';
import 'package:word_crush_mobile/data/models/player_profile.dart';
import 'package:word_crush_mobile/data/services/objectbox_service.dart';
import 'package:word_crush_mobile/logic/providers/game_provider.dart';

/// In-memory ObjectBoxService — DB gerektirmeden GameNotifier testine izin verir.
class _FakeObjectBoxService extends ObjectBoxService {
  final List<GameRecord> _records = [];

  @override
  List<GameRecord> getAllGameRecords() => List.from(_records);

  @override
  void saveGameRecord(GameRecord record) => _records.add(record);

  @override
  PlayerProfile? getProfile() => null;

  @override
  void saveProfile(PlayerProfile profile) {}

  @override
  List<JokerInventory> getAllJokers() => [];

  @override
  void saveJoker(JokerInventory joker) {}

  @override
  JokerInventory? getJoker(String jokerType) => null;
}

GameNotifier _makeGame() => GameNotifier(_FakeObjectBoxService());

void main() {
  group('GameNotifier — oyun akışı', () {
    test('startNewGame state\'i doğru başlatır', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.hardGridSize, 15);

      expect(g.state.movesLeft, 15);
      expect(g.state.maxMoves, 15);
      expect(g.state.gridSize, AppConstants.hardGridSize);
      expect(g.state.difficulty, 'Zor');
      expect(g.state.isGameActive, isTrue);
      expect(g.state.isGameOver, isFalse);
      expect(g.state.wordCount, 0);
    });

    test('decrementMove her çağrıda 1 azaltır', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.hardGridSize, 15);
      g.decrementMove();
      g.decrementMove();

      expect(g.state.movesLeft, 13);
    });

    test('son hamle bitince isGameOver true olur', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.hardGridSize, 1);
      g.decrementMove();

      expect(g.state.movesLeft, 0);
      expect(g.state.isGameOver, isTrue);
      expect(g.state.isGameActive, isFalse);
    });

    test('decrementMove 0\'ın altına inmez', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.hardGridSize, 1);
      g.decrementMove();
      g.decrementMove(); // fazladan çağrı

      expect(g.state.movesLeft, 0);
    });

    test('recordWord kelime sayısını ve en uzun kelimeyi günceller', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.mediumGridSize, 20);
      g.recordWord('ARI');
      g.recordWord('KALEM');
      g.recordWord('EV');

      expect(g.state.wordCount, 3);
      expect(g.state.longestWord, 'KALEM');
    });

    test('daha kısa kelime longestWord\'ü değiştirmez', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.mediumGridSize, 20);
      g.recordWord('KALEM');
      g.recordWord('EV');

      expect(g.state.longestWord, 'KALEM');
    });

    test('endGame kaydı DB\'ye yazar', () {
      final db = _FakeObjectBoxService();
      final g = GameNotifier(db);
      g.startNewGame(AppConstants.hardGridSize, 15);
      g.recordWord('ARI');
      g.decrementMove();
      g.endGame(120);

      expect(db.getAllGameRecords().length, 1);
      final record = db.getAllGameRecords().first;
      expect(record.score, 120);
      expect(record.wordCount, 1);
      expect(record.longestWord, 'ARI');
    });

    test('endGame sonrası isGameActive false, isGameOver true olur', () {
      final g = _makeGame();
      g.startNewGame(AppConstants.hardGridSize, 15);
      g.endGame(0);

      expect(g.state.isGameActive, isFalse);
      expect(g.state.isGameOver, isTrue);
    });

    test('wordCount == 0 ise endGame yine de çalışır ama kayıt yazar', () {
      final db = _FakeObjectBoxService();
      final g = GameNotifier(db);
      g.startNewGame(AppConstants.hardGridSize, 15);
      g.endGame(0);

      // wordCount 0 olsa da kayıt yazılır (UI tarafı zaten bunu engeller)
      expect(db.getAllGameRecords().length, 1);
    });

    test('ikinci oyun gameNumber 2 ile kaydedilir', () {
      final db = _FakeObjectBoxService();
      final g = GameNotifier(db);

      g.startNewGame(AppConstants.hardGridSize, 15);
      g.endGame(100);

      g.startNewGame(AppConstants.hardGridSize, 15);
      expect(g.state.gameNumber, 2);
    });

    test('tam oyun akışı: başla → kelime bul → hamle azalt → bitir', () {
      final db = _FakeObjectBoxService();
      final g = GameNotifier(db);

      g.startNewGame(AppConstants.easyGridSize, 25);
      g.recordWord('ARABA');
      g.recordWord('EV');
      g.decrementMove();
      g.decrementMove();
      g.endGame(85);

      final record = db.getAllGameRecords().first;
      expect(record.score, 85);
      expect(record.wordCount, 2);
      expect(record.longestWord, 'ARABA');
      expect(g.state.movesLeft, 23);
    });
  });
}
