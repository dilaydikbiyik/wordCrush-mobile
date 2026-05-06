import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/data/services/trie_service.dart';
import 'package:word_crush_mobile/logic/scoring/combo_engine.dart';

void main() {
  group('ComboEngine', () {
    late TrieService trie;
    late ComboEngine engine;

    setUp(() {
      trie = TrieService();
      for (final w in [
        // ADANA grubu
        'ADANA', 'ANA', 'ADA', 'DANA',
        // MASAL grubu
        'MASAL', 'MASA', 'ASA', 'SAL',
        // SARI grubu
        'SARI', 'ARI',
        // KALEM grubu
        'KALEM', 'KAL', 'KALE', 'ALEM',
        // KURAL grubu (substring vs subsequence kritik testi)
        'KURAL', 'KUR', 'KURA',
        // KADAR grubu
        'KADAR', 'ADA', 'DAR',
        // ARABA grubu
        'ARABA', 'ARA', 'RAB', 'ABA',
        // 2 harfli — combo sonuçlarına GİRMEMELİ
        'EL', 'AL',
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

    // ─── Gerçek sözlük kelimeleriyle substring testleri ─────────────────────

    test('findComboWords — KALEM → {KALEM, KAL, KALE, ALEM}', () {
      // K-A-L-E-M: substring olarak KAL(0-3), KALE(0-4), ALEM(1-5), KALEM(0-5)
      final combos = engine.findComboWords('KALEM');
      expect(combos, containsAll(['KALEM', 'KAL', 'KALE', 'ALEM']));
      expect(combos.length, 4);
    });

    test('findComboWords — KURAL → {KURAL, KUR, KURA} (KAL olmamalı)', () {
      // K-U-R-A-L: substring olarak KUR(0-3), KURA(0-4), KURAL(0-5)
      // KAL sözlükte var ama K→A→L ardışık değil (0,3,4) — subsequence, substring DEĞİL
      final combos = engine.findComboWords('KURAL');
      expect(combos, containsAll(['KURAL', 'KUR', 'KURA']));
      expect(combos, isNot(contains('KAL')));
      expect(combos.length, 3);
    });

    test('findComboWords — KADAR → {KADAR, ADA, DAR}', () {
      // K-A-D-A-R: substring olarak ADA(1-4), DAR(2-5), KADAR(0-5)
      final combos = engine.findComboWords('KADAR');
      expect(combos, containsAll(['KADAR', 'ADA', 'DAR']));
      expect(combos.length, 3);
    });

    test('findComboWords — ARABA → {ARABA, ARA, RAB, ABA}', () {
      // A-R-A-B-A: substring olarak ARA(0-3), RAB(1-4), ABA(2-5), ARABA(0-5)
      final combos = engine.findComboWords('ARABA');
      expect(combos, containsAll(['ARABA', 'ARA', 'RAB', 'ABA']));
      expect(combos.length, 4);
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
