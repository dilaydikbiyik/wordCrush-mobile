import 'dart:async';
import 'package:flutter/services.dart';
import '../../core/utils/char_normalizer.dart';

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isWord = false;
}

class TrieService {
  final TrieNode root = TrieNode();

  Future<void> loadWords() async {
    final data = await rootBundle.loadString('assets/words.txt');
    final words = data
        .split('\n')
        .map((word) => CharNormalizer.normalize(word.trim()))
        .where((word) => word.isNotEmpty);

    for (final word in words) {
      insert(word);
    }
  }

  void insert(String word) {
    var node = root;
    for (final char in word.split('')) {
      node = node.children.putIfAbsent(char, () => TrieNode());
    }
    node.isWord = true;
  }

  bool contains(String word) {
    var node = root;
    for (final char in word.split('')) {
      final next = node.children[char];
      if (next == null) return false;
      node = next;
    }
    return node.isWord;
  }

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
