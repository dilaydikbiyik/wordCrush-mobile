import 'package:flutter_test/flutter_test.dart';
import 'package:word_crush_mobile/data/services/trie_service.dart';

void main() {
  group('TrieService', () {
    late TrieService trie;

    setUp(() {
      trie = TrieService();
      trie.insert('ADANA');
      trie.insert('ADA');
      trie.insert('DANA');
      trie.insert('KALEM');
      trie.insert('KAL');
    });

    test('contains — inserted word returns true', () {
      expect(trie.contains('ADANA'), isTrue);
      expect(trie.contains('KALEM'), isTrue);
    });

    test('contains — non-existent word returns false', () {
      expect(trie.contains('MASA'), isFalse);
      expect(trie.contains(''), isFalse);
    });

    test('hasPrefix — valid prefix returns true', () {
      expect(trie.hasPrefix('ADA'), isTrue);
      expect(trie.hasPrefix('KA'), isTrue);
    });

    test('hasPrefix — invalid prefix returns false', () {
      expect(trie.hasPrefix('ZZZ'), isFalse);
    });

    test('Turkish uppercase — İ is distinct from I', () {
      trie.insert('İNEK');
      expect(trie.contains('İNEK'), isTrue);
      expect(trie.contains('INEK'), isFalse);
    });
  });
}
