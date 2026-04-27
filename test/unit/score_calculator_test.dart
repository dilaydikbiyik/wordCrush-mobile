import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/logic/scoring/score_calculator.dart';

void main() {
  group('ScoreCalculator', () {
    late ScoreCalculator calc;

    setUp(() {
      calc = ScoreCalculator();
    });

    // ─── calculateWordScore ─────────────────────────────────────────────────

    test('calculateWordScore — SORU = S(2)+O(2)+R(1)+U(2) = 7', () {
      expect(calc.calculateWordScore('SORU'), 7);
    });

    test('calculateWordScore — ARI = A(1)+R(1)+I(2) = 4', () {
      expect(calc.calculateWordScore('ARI'), 4);
    });

    test('calculateWordScore — SARI = S(2)+A(1)+R(1)+İ(1) — without dot I', () {
      // SARI with capital I (dotless) = S(2)+A(1)+R(1)+I(2) = 6
      expect(calc.calculateWordScore('SARI'), 6);
    });

    test('calculateWordScore — single high-scoring letter J = 10', () {
      expect(calc.calculateWordScore('J'), 10);
    });

    test('calculateWordScore — single low-scoring letter A = 1', () {
      expect(calc.calculateWordScore('A'), 1);
    });

    test('calculateWordScore — unknown character returns 0', () {
      // Power tile markers or empty strings should score 0
      expect(calc.calculateWordScore(''), 0);
    });

    test('calculateWordScore — all 29 letters have correct scores', () {
      final expected = {
        'A': 1,  'B': 3,  'C': 4,  'Ç': 4,
        'D': 3,  'E': 1,  'F': 7,  'G': 5,
        'Ğ': 8,  'H': 5,  'I': 2,  'İ': 1,
        'J': 10, 'K': 1,  'L': 1,  'M': 2,
        'N': 1,  'O': 2,  'Ö': 7,  'P': 5,
        'R': 1,  'S': 2,  'Ş': 4,  'T': 1,
        'U': 2,  'Ü': 3,  'V': 7,  'Y': 3,
        'Z': 4,
      };
      for (final entry in expected.entries) {
        expect(
          calc.calculateWordScore(entry.key),
          entry.value,
          reason: '"${entry.key}" should score ${entry.value}',
        );
      }
    });

    // ─── calculateTotalScore ────────────────────────────────────────────────

    test('calculateTotalScore — main only (no combos) = word score', () {
      // SARI without combos = 6
      expect(calc.calculateTotalScore('SARI', []), 6);
    });

    test('calculateTotalScore — SARI + ARI combo = 6 + 4 = 10', () {
      // PROJECT_INSTRUCTIONS.md örneği: SARI=6, ARI=4 → toplam 10
      expect(calc.calculateTotalScore('SARI', ['ARI']), 10);
    });

    test('calculateTotalScore — multiple combos accumulate', () {
      // ADANA = A(1)+D(3)+A(1)+N(1)+A(1) = 7
      // ANA   = A(1)+N(1)+A(1) = 3
      // ADA   = A(1)+D(3)+A(1) = 5
      // DANA  = D(3)+A(1)+N(1)+A(1) = 6
      // Total = 7 + 3 + 5 + 6 = 21
      expect(
        calc.calculateTotalScore('ADANA', ['ANA', 'ADA', 'DANA']),
        21,
      );
    });

    test('calculateTotalScore — empty main word = 0', () {
      expect(calc.calculateTotalScore('', []), 0);
    });
  });
}
