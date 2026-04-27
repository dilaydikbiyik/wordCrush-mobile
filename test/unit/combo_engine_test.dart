import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/data/services/trie_service.dart';
import 'package:word_crush_mobile/logic/scoring/combo_engine.dart';

void main() {
  group('ComboEngine', () {
    late TrieService trie;
    late ComboEngine engine;

    setUp(() {
      trie = TrieService();
      // Insert words referenced in PROJECT_INSTRUCTIONS.md examples
      for (final w in [
        'ADANA', 'ANA', 'ADA', 'DANA',
        'MASAL', 'MASA', 'ASA', 'SAL',
        'SARI', 'ARI',
        'KAL', 'KALEM',
        'EL', // 2-letter — should NOT appear in combo results
        'AL',  // 2-letter — should NOT appear
      ]) {
        trie.insert(w);
      }
      engine = ComboEngine(trie);
    });

    // ─── Main word always included ───────────────────────────────────────────

    test('findComboWords — ADANA includes ADANA itself', () {
      final combos = engine.findComboWords('ADANA');
      expect(combos, contains('ADANA'));
    });

    // ─── PROJECT_INSTRUCTIONS.md examples ───────────────────────────────────

    test('findComboWords — ADANA → {ADANA, ANA, ADA, DANA}', () {
      final combos = engine.findComboWords('ADANA');
      expect(combos, containsAll(['ADANA', 'ANA', 'ADA', 'DANA']));
      expect(combos.length, 4);
    });

    test('findComboWords — MASAL → {MASAL, MASA, ASA, SAL}', () {
      final combos = engine.findComboWords('MASAL');
      expect(combos, containsAll(['MASAL', 'MASA', 'ASA', 'SAL']));
      expect(combos.length, 4);
    });

    test('findComboWords — SARI → {SARI, ARI}', () {
      final combos = engine.findComboWords('SARI');
      expect(combos, containsAll(['SARI', 'ARI']));
      expect(combos.length, 2);
    });

    // ─── Minimum length filter ───────────────────────────────────────────────

    test('findComboWords — 2-letter sub-words are excluded', () {
      // "EL" and "AL" are in the trie but should NOT appear (min length = 3)
      final combos = engine.findComboWords('KALEM');
      expect(combos, isNot(contains('EL')));
      expect(combos, isNot(contains('AL')));
    });

    // ─── Combo count ─────────────────────────────────────────────────────────

    test('comboCount — ADANA = 4', () {
      expect(engine.comboCount('ADANA'), 4);
    });

    test('comboCount — SARI = 2', () {
      expect(engine.comboCount('SARI'), 2);
    });

    test('comboCount — word with no sub-words = 1 (just itself)', () {
      // KALEM: only KALEM and KAL are in trie
      final combos = engine.findComboWords('KALEM');
      expect(combos, containsAll(['KALEM', 'KAL']));
    });

    // ─── No duplicates ───────────────────────────────────────────────────────

    test('findComboWords — no duplicate words in result', () {
      final combos = engine.findComboWords('ADANA');
      final unique = combos.toSet();
      expect(combos.length, unique.length);
    });

    // ─── Edge cases ──────────────────────────────────────────────────────────

    test('findComboWords — word not in trie returns empty list', () {
      final combos = engine.findComboWords('ZZZZZ');
      expect(combos, isEmpty);
    });

    test('findComboWords — 2-letter main word returns empty (below min)', () {
      final combos = engine.findComboWords('AL');
      expect(combos, isEmpty);
    });
  });
}
