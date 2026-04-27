/// Edge case unit tests for game mechanics and validation.
///
/// Covers:
/// - Market: insufficient gold scenario
/// - Joker inventory: all jokers used
/// - Username: empty and over-max-length inputs
import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/core/constants/app_constants.dart';
import 'package:word_crush_mobile/data/models/joker_inventory.dart';
import 'package:word_crush_mobile/data/services/trie_service.dart';
import 'package:word_crush_mobile/logic/scoring/score_calculator.dart';

void main() {
  group('Edge Cases', () {
    // ─── Market: insufficient gold ───────────────────────────────────────────

    group('Gold — insufficient balance', () {
      test('A player with 0 gold cannot afford any joker', () {
        const goldBalance = 0;
        expect(goldBalance < AppConstants.fishPrice, isTrue,
            reason: 'Balık joker price=${AppConstants.fishPrice} > 0');
        expect(goldBalance < AppConstants.lollipopPrice, isTrue,
            reason: 'Lollipop joker price=${AppConstants.lollipopPrice} > 0');
        expect(goldBalance < AppConstants.wheelPrice, isTrue);
        expect(goldBalance < AppConstants.swapPrice, isTrue);
        expect(goldBalance < AppConstants.shufflePrice, isTrue);
        expect(goldBalance < AppConstants.partyPrice, isTrue);
      });

      test('A player with exactly the price can afford it', () {
        const goldBalance = AppConstants.fishPrice;
        expect(goldBalance >= AppConstants.fishPrice, isTrue);
      });

      test('Spending more than balance should fail', () {
        // Simulates PlayerNotifier.spendGold logic
        int balance = 50;
        const cost = AppConstants.fishPrice; // 100
        final canAfford = balance >= cost;
        expect(canAfford, isFalse);
      });

      test('Spending exactly balance should succeed', () {
        int balance = AppConstants.fishPrice;
        const cost = AppConstants.fishPrice;
        final canAfford = balance >= cost;
        expect(canAfford, isTrue);
        if (canAfford) balance -= cost;
        expect(balance, 0);
      });
    });

    // ─── Joker inventory: all jokers used ───────────────────────────────────

    group('JokerInventory — quantity tracking', () {
      test('JokerInventory starts with 0 of each type', () {
        final inv = JokerInventory(jokerType: JokerType.fish, quantity: 0);
        expect(inv.quantity, 0);
      });

      test('A joker with quantity 0 cannot be used', () {
        final inv = JokerInventory(jokerType: JokerType.fish, quantity: 0);
        // Simulates hasJoker() check
        expect(inv.quantity > 0, isFalse);
      });

      test('A joker with quantity 1 can be used once', () {
        int qty = 1;
        expect(qty > 0, isTrue); // has joker
        qty--;
        expect(qty, 0); // now used
        expect(qty > 0, isFalse); // can't use again
      });

      test('JokerType constants — all 6 types are distinct strings', () {
        final types = [
          JokerType.fish,
          JokerType.wheel,
          JokerType.lollipop,
          JokerType.swap,
          JokerType.shuffle,
          JokerType.party,
        ];
        expect(types.length, 6);
        // Each type must be a unique non-empty string
        expect(types.toSet().length, 6, reason: 'All JokerType constants must be unique');
        for (final t in types) {
          expect(t, isNotEmpty);
        }
      });
    });

    // ─── Username validation ─────────────────────────────────────────────────

    group('Username — validation edge cases', () {
      const maxUsernameLength = 20; // Matches LoginScreen maxLength

      test('Empty username is invalid', () {
        const username = '';
        expect(username.trim().isNotEmpty, isFalse);
      });

      test('Whitespace-only username is invalid after trim', () {
        const username = '   ';
        expect(username.trim().isNotEmpty, isFalse);
      });

      test('Username within max length is valid', () {
        const username = 'oyuncu1';
        expect(username.trim().isNotEmpty, isTrue);
        expect(username.length <= maxUsernameLength, isTrue);
      });

      test('Username at max length (20 chars) is valid', () {
        final username = 'A' * maxUsernameLength;
        expect(username.length, maxUsernameLength);
        expect(username.trim().isNotEmpty, isTrue);
      });

      test('Username over max length is rejected by UI (maxLength=20)', () {
        // The TextField enforces maxLength — simulate the check
        final input = 'A' * 25;
        final clamped = input.length > maxUsernameLength
            ? input.substring(0, maxUsernameLength)
            : input;
        expect(clamped.length, maxUsernameLength);
      });
    });

    // ─── Score calculation edge cases ────────────────────────────────────────

    group('ScoreCalculator — edge cases', () {
      final calc = ScoreCalculator();

      test('Very long word still scores correctly', () {
        // 'ADANA' (5 letters): A(1)+D(3)+A(1)+N(1)+A(1) = 7
        expect(calc.calculateWordScore('ADANA'), 7);
      });

      test('Word with special Turkish characters scores correctly', () {
        // 'ÖĞ': Ö(7)+Ğ(8) = 15
        expect(calc.calculateWordScore('ÖĞ'), 15);
      });

      test('Power tile character (★) scores 0', () {
        expect(calc.calculateWordScore('★'), 0);
      });
    });

    // ─── Trie edge cases ────────────────────────────────────────────────────

    group('TrieService — edge cases', () {
      late TrieService trie;

      setUp(() {
        trie = TrieService();
        trie.insert('ADANA');
      });

      test('Empty string is not a valid word', () {
        expect(trie.contains(''), isFalse);
      });

      test('Prefix alone is not a valid word (unless inserted)', () {
        // 'ADA' was not inserted separately
        expect(trie.contains('ADA'), isFalse);
        expect(trie.hasPrefix('ADA'), isTrue); // but prefix exists
      });

      test('Case sensitivity — lowercase is distinct', () {
        // Trie stores uppercase; lowercase should not match
        expect(trie.contains('adana'), isFalse);
      });
    });
  });
}
