import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/char_normalizer.dart';

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isWord = false;
}

/// In-memory Trie loaded from [AppConstants.wordsAssetPath].
///
/// Words are stored in Turkish uppercase (e.g. 'ADANA', 'KALEMİ').
/// This allows O(m) lookup and O(p) prefix pruning during grid solving.
class TrieService {
  final TrieNode root = TrieNode();

  /// Raw word list kept for isolate transfer (passed to [compute] as serializable data).
  final List<String> _wordList = [];

  /// All loaded words — used to pass the dictionary to background isolates.
  List<String> get wordList => List.unmodifiable(_wordList);

  /// Loads all words from asset, converts to Turkish uppercase, inserts into Trie.
  Future<void> loadWords() async {
    final data = await rootBundle.loadString(AppConstants.wordsAssetPath);
    final words = data
        .split('\n')
        .map((w) => CharNormalizer.toTurkishUpper(w.trim()))
        .where((w) => w.length >= AppConstants.minWordLength);

    for (final word in words) {
      _wordList.add(word);
      insert(word);
    }
  }

  void insert(String word) {
    var node = root;
    for (final char in word.split('')) {
      node = node.children.putIfAbsent(char, TrieNode.new);
    }
    node.isWord = true;
  }

  /// Returns true if [word] (Turkish uppercase) is in the dictionary.
  bool contains(String word) {
    var node = root;
    for (final char in word.split('')) {
      final next = node.children[char];
      if (next == null) return false;
      node = next;
    }
    return node.isWord;
  }

  /// Returns true if any word starts with [prefix] — used for DFS pruning.
  bool hasPrefix(String prefix) {
    var node = root;
    for (final char in prefix.split('')) {
      final next = node.children[char];
      if (next == null) return false;
      node = next;
    }
    return true;
  }
}
