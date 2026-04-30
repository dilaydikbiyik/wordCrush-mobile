import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/data/models/joker_inventory.dart';
import 'package:word_crush_mobile/data/services/objectbox_service.dart';
import 'package:word_crush_mobile/logic/providers/joker_provider.dart';

/// In-memory ObjectBoxService — bypasses ObjectBox so JokerNotifier
/// can be tested without a real database or file system.
class _FakeObjectBoxService extends ObjectBoxService {
  final List<JokerInventory> _jokers = [];

  @override
  List<JokerInventory> getAllJokers() => List.from(_jokers);

  @override
  void saveJoker(JokerInventory joker) {
    _jokers.removeWhere((j) => j.jokerType == joker.jokerType);
    _jokers.add(joker);
  }

  @override
  JokerInventory? getJoker(String jokerType) =>
      _jokers.where((j) => j.jokerType == jokerType).firstOrNull;
}

JokerNotifier _makeNotifier({Map<String, int> initial = const {}}) {
  final db = _FakeObjectBoxService();
  for (final entry in initial.entries) {
    db.saveJoker(JokerInventory(jokerType: entry.key, quantity: entry.value));
  }
  final notifier = JokerNotifier(db);
  notifier.loadInventory();
  return notifier;
}

void main() {
  group('JokerNotifier — useJoker business logic', () {
    test('useJoker returns true and decrements qty by 1', () {
      final n = _makeNotifier(initial: {JokerType.fish: 3});
      final result = n.useJoker(JokerType.fish);
      expect(result, isTrue);
      expect(n.state.getQuantity(JokerType.fish), 2);
    });

    test('useJoker on qty=1 leaves 0, not negative', () {
      final n = _makeNotifier(initial: {JokerType.fish: 1});
      n.useJoker(JokerType.fish);
      expect(n.state.getQuantity(JokerType.fish), 0);
      expect(n.state.hasJoker(JokerType.fish), isFalse);
    });

    test('useJoker on qty=0 returns false and does not change state', () {
      final n = _makeNotifier(initial: {JokerType.fish: 0});
      final result = n.useJoker(JokerType.fish);
      expect(result, isFalse);
      expect(n.state.getQuantity(JokerType.fish), 0);
    });

    test('useJoker on missing type returns false', () {
      final n = _makeNotifier();
      expect(n.useJoker(JokerType.wheel), isFalse);
    });

    test('useJoker does not affect other joker types', () {
      final n = _makeNotifier(initial: {
        JokerType.fish: 2,
        JokerType.wheel: 5,
      });
      n.useJoker(JokerType.fish);
      expect(n.state.getQuantity(JokerType.fish), 1);
      expect(n.state.getQuantity(JokerType.wheel), 5);
    });

    test('useJoker sets activeJoker in state', () {
      final n = _makeNotifier(initial: {JokerType.lollipop: 2});
      n.useJoker(JokerType.lollipop);
      expect(n.state.activeJoker, JokerType.lollipop);
    });

    test('clearActiveJoker nullifies activeJoker', () {
      final n = _makeNotifier(initial: {JokerType.shuffle: 1});
      n.useJoker(JokerType.shuffle);
      n.clearActiveJoker();
      expect(n.state.activeJoker, isNull);
    });

    test('using all jokers one by one exhausts inventory', () {
      final n = _makeNotifier(initial: {JokerType.party: 3});
      for (int i = 3; i > 0; i--) {
        expect(n.useJoker(JokerType.party), isTrue);
      }
      expect(n.state.hasJoker(JokerType.party), isFalse);
      expect(n.useJoker(JokerType.party), isFalse);
    });
  });

  group('JokerNotifier — persistence (in-memory DB)', () {
    test('useJoker persists decremented qty to DB', () {
      final db = _FakeObjectBoxService();
      db.saveJoker(JokerInventory(jokerType: JokerType.fish, quantity: 5));
      final n = JokerNotifier(db);
      n.loadInventory();

      n.useJoker(JokerType.fish);

      // Read directly from the fake DB to verify persistence
      final saved = db.getJoker(JokerType.fish);
      expect(saved?.quantity, 4);
    });

    test('addJoker persists incremented qty to DB', () {
      final db = _FakeObjectBoxService();
      final n = JokerNotifier(db);
      n.loadInventory();

      n.addJoker(JokerType.wheel, 3);

      final saved = db.getJoker(JokerType.wheel);
      expect(saved?.quantity, 3);
    });

    test('loadInventory reads persisted jokers into state', () {
      final db = _FakeObjectBoxService();
      db.saveJoker(JokerInventory(jokerType: JokerType.swap, quantity: 7));
      db.saveJoker(JokerInventory(jokerType: JokerType.party, quantity: 2));

      final n = JokerNotifier(db);
      n.loadInventory();

      expect(n.state.getQuantity(JokerType.swap), 7);
      expect(n.state.getQuantity(JokerType.party), 2);
    });

    test('use → reload reflects correct qty (simulates app restart)', () {
      final db = _FakeObjectBoxService();
      db.saveJoker(JokerInventory(jokerType: JokerType.fish, quantity: 4));

      final session1 = JokerNotifier(db);
      session1.loadInventory();
      session1.useJoker(JokerType.fish);
      session1.useJoker(JokerType.fish);

      // Simulate app restart: new notifier, same DB
      final session2 = JokerNotifier(db);
      session2.loadInventory();

      expect(session2.state.getQuantity(JokerType.fish), 2);
    });
  });
}
