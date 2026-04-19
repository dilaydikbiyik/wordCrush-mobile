import 'dart:collection';

class TrieNode {
  final Map<String, TrieNode> children = {};
  bool isWord = false;
}

class TrieService {
  final TrieNode _root = TrieNode();

  void insert(String word) {
    var node = _root;
    for (final char in word.split('')) {
      node = node.children.putIfAbsent(char, () => TrieNode());
    }
    node.isWord = true;
  }

  bool contains(String word) {
    var node = _root;
    for (final char in word.split('')) {
      if (!node.children.containsKey(char)) return false;
      node = node.children[char]!;
    }
    return node.isWord;
  }

  bool isPrefix(String prefix) {
    var node = _root;
    for (final char in prefix.split('')) {
      if (!node.children.containsKey(char)) return false;
      node = node.children[char]!;
    }
    return true;
  }
}
